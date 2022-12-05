#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

REGISTRY_HOSTNAME=$(yq e .registry.fqdn $PARAMS_YAML)
REGISTRY_USERNAME=$(yq e .registry.username $PARAMS_YAML)
REGISTRY_PASSWORD=$(yq e .registry.password $PARAMS_YAML)

information "Add read/write registry credentials to the developer namespace on cluster '$CLUSTER_NAME'"

tanzu secret registry add registry-credentials \
  --server $REGISTRY_HOSTNAME \
  --username $REGISTRY_USERNAME \
  --password $REGISTRY_PASSWORD \
  --namespace default \
  --kubeconfig $KUBECONFIG

information "Authorize the service account to the developer namespace on cluster '$CLUSTER_NAME'"
kubectl apply -f tap-declarative-yaml/dev-namespace/rbac.yaml --kubeconfig $KUBECONFIG

if [[ $IS_BUILD_CLUSTER == true ]]; then
  information "Create a scan policy to the developer namespace on cluster '$CLUSTER_NAME'"
  kubectl apply -f tap-declarative-yaml/dev-namespace/scan-policy.yaml --kubeconfig $KUBECONFIG

  information "Create an ootb_supply_chain_testing_scanning Java pipeline on cluster '$CLUSTER_NAME'"
  kubectl apply -f tap-declarative-yaml/dev-namespace/java-pipeline.yaml --kubeconfig $KUBECONFIG

  information "Create an ootb_supply_chain_testing_scanning Python pipeline on cluster '$CLUSTER_NAME'"
  kubectl apply -f tap-declarative-yaml/dev-namespace/python-pipeline.yaml --kubeconfig $KUBECONFIG
fi
