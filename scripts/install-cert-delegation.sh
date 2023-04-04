#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

CERT_PATH="generated/cert"
ITERATE_CLUSTER_KUBECONFIG=$(yq e .clusters.iterate_cluster.k8s_info.kubeconfig $PARAMS_YAML)
ITERATE_CLUSTER_NAME=$(yq e .clusters.iterate_cluster.k8s_info.name $PARAMS_YAML)
RUN_CLUSTER_COUNT=$(yq e '.clusters.run_clusters | length' $PARAMS_YAML)
VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.k8s_info.kubeconfig $PARAMS_YAML)
VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.k8s_info.name $PARAMS_YAML)

function install_cert_delegation() {
  CLUSTER_NAME=$1
  KUBECONFIG=$2

  information "Waiting for Contour CRD tlscertificatedelegations.projectcontour.io on cluster '$CLUSTER_NAME'"

  while ! kubectl get crd tlscertificatedelegations.projectcontour.io --kubeconfig $KUBECONFIG >/dev/null 2>&1; do sleep 2; done

  information "Applying TLS certificate delegation on cluster '$CLUSTER_NAME'"

  kubectl apply -f tap-declarative-yaml/tls-delegation.yaml --kubeconfig $KUBECONFIG
}

install_cert_delegation $VIEW_CLUSTER_NAME    $VIEW_CLUSTER_KUBECONFIG
install_cert_delegation $ITERATE_CLUSTER_NAME $ITERATE_CLUSTER_KUBECONFIG

for ((i=0;i<$RUN_CLUSTER_COUNT;i++)); 
do
  RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)

  install_cert_delegation $RUN_CLUSTER_NAME $RUN_CLUSTER_KUBECONFIG
done
