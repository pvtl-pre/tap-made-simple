#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

BUILD_CLUSTER_KUBECONFIG=$(yq e .clusters.build_cluster.k8s_info.kubeconfig $PARAMS_YAML)
BUILD_CLUSTER_NAME=$(yq e .clusters.build_cluster.k8s_info.name $PARAMS_YAML)
ITERATE_CLUSTER_KUBECONFIG=$(yq e .clusters.iterate_cluster.k8s_info.kubeconfig $PARAMS_YAML)
ITERATE_CLUSTER_NAME=$(yq e .clusters.iterate_cluster.k8s_info.name $PARAMS_YAML)
RUN_CLUSTER_COUNT=$(yq e '.clusters.run_clusters | length' $PARAMS_YAML)

REGISTRY_HOSTNAME=$(yq e .registry.fqdn $PARAMS_YAML)
REGISTRY_USERNAME=$(yq e .registry.username $PARAMS_YAML)
REGISTRY_PASSWORD=$(yq e .registry.password $PARAMS_YAML)

function add_dev_namespace() {
  CLUSTER_NAME=$1
  KUBECONFIG=$2
  IS_ITERATE_CLUSTER=$3

  kubectl create ns product-team1 --dry-run=client -o yaml | kubectl --kubeconfig $KUBECONFIG apply -f -

  information "Add read/write registry credentials to the developer namespace on cluster '$CLUSTER_NAME'"

  tanzu secret registry add registry-credentials \
    --server $REGISTRY_HOSTNAME \
    --username $REGISTRY_USERNAME \
    --password $REGISTRY_PASSWORD \
    --namespace product-team1 \
    --kubeconfig $KUBECONFIG

  information "Authorize the service account to the developer namespace on cluster '$CLUSTER_NAME'"

  kubectl apply -f tap-declarative-yaml/dev-namespace/rbac.yaml -n product-team1 --kubeconfig $KUBECONFIG
}

add_dev_namespace $ITERATE_CLUSTER_NAME $ITERATE_CLUSTER_KUBECONFIG
add_dev_namespace $BUILD_CLUSTER_NAME $BUILD_CLUSTER_KUBECONFIG

for ((i = 0; i < $RUN_CLUSTER_COUNT; i++)); do
  RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)

  add_dev_namespace $RUN_CLUSTER_NAME $RUN_CLUSTER_KUBECONFIG
done
