#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

CERT_PATH="generated/cert"
GENERATE_CERT=$(yq e .tls.generate $PARAMS_YAML)
ITERATE_CLUSTER_KUBECONFIG=$(yq e .clusters.iterate_cluster.k8s_info.kubeconfig $PARAMS_YAML)
ITERATE_CLUSTER_NAME=$(yq e .clusters.iterate_cluster.k8s_info.name $PARAMS_YAML)
RUN_CLUSTER_COUNT=$(yq e '.clusters.run_clusters | length' $PARAMS_YAML)
VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.k8s_info.name $PARAMS_YAML)
VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.k8s_info.kubeconfig $PARAMS_YAML)

function install_cert() {
  CLUSTER_NAME=$1
  KUBECONFIG=$2

  information "Applying TLS secret on cluster '$CLUSTER_NAME'"

  kubectl apply -f $CERT_PATH/tls-secret.yaml --kubeconfig $KUBECONFIG
}

mkdir -p $CERT_PATH

if [[ $GENERATE_CERT == true ]]; then
  $SCRIPTS/generate-cert.sh
else
  information "Skipped cert generation due to user providing cert"

  information "Getting cert details"

  yq e .tls.cert_data $PARAMS_YAML | base64 --decode >$CERT_PATH/wildcard.cer
  yq e .tls.key_data $PARAMS_YAML | base64 --decode >$CERT_PATH/wildcard.key
fi

information "Creating TLS secret yaml"

kubectl create secret tls wildcard -n tap-install --cert=$CERT_PATH/wildcard.cer --key=$CERT_PATH/wildcard.key --dry-run=client -o yaml >$CERT_PATH/tls-secret.yaml

install_cert $VIEW_CLUSTER_NAME $VIEW_CLUSTER_KUBECONFIG
install_cert $ITERATE_CLUSTER_NAME $ITERATE_CLUSTER_KUBECONFIG

for ((i = 0; i < $RUN_CLUSTER_COUNT; i++)); do
  RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)

  install_cert $RUN_CLUSTER_NAME $RUN_CLUSTER_KUBECONFIG
done
