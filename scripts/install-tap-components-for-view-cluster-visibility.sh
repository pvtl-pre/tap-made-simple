#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

TKG_LAB_SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$TKG_LAB_SCRIPTS/set-env.sh"

BUILD_CLUSTER_KUBECONFIG=$(yq e .clusters.build_cluster.k8s_info.kubeconfig $PARAMS_YAML)
BUILD_CLUSTER_NAME=$(yq e .clusters.build_cluster.k8s_info.name $PARAMS_YAML)
BUILD_CLUSTER_SA_TOKEN_PATH=".clusters.build_cluster.k8s_info.sa_token"
ITERATE_CLUSTER_KUBECONFIG=$(yq e .clusters.iterate_cluster.k8s_info.kubeconfig $PARAMS_YAML)
ITERATE_CLUSTER_NAME=$(yq e .clusters.iterate_cluster.k8s_info.name $PARAMS_YAML)
ITERATE_CLUSTER_SA_TOKEN_PATH=".clusters.iterate_cluster.k8s_info.sa_token"
RUN_CLUSTER_COUNT=$(yq e '.clusters.run_clusters | length' $PARAMS_YAML)
VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.k8s_info.name $PARAMS_YAML)
VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.k8s_info.kubeconfig $PARAMS_YAML)

function install_components() {
  CLUSTER_NAME=$1
  KUBECONFIG=$2
  SA_TOKEN_PATH=$3

  information "Installing TAP components for View Cluster visibility on cluster '$CLUSTER_NAME'"

  information "Adding TAP GUI multi-cluster RBAC on cluster '$CLUSTER_NAME'"

  KUBE_VERSION=$(kubectl version -o yaml --kubeconfig $KUBECONFIG | yq e '.serverVersion.minor')

  kubectl apply -f tap-declarative-yaml/tap-gui/tap-gui-viewer-service-account-rbac.yaml --kubeconfig $KUBECONFIG

  if [[ $KUBE_VERSION -ge 24 ]]; then
    kubectl apply -f tap-declarative-yaml/tap-gui/tap-gui-viewer-service-account-secret.yaml --kubeconfig $KUBECONFIG
    TAP_GUI_VIEWER_SECRET="tap-gui-viewer"
  else
    TAP_GUI_VIEWER_SECRET=$(kubectl -n tap-gui get sa tap-gui-viewer -o yaml --kubeconfig $KUBECONFIG | yq -r '.secrets[0].name')
  fi

  information "Getting service account token on cluster '$CLUSTER_NAME'"

  export SA_TOKEN=$(kubectl -n tap-gui get secret $TAP_GUI_VIEWER_SECRET -o yaml --kubeconfig $KUBECONFIG | yq -r '.data["token"]' | base64 --decode)

  yq e -i "$SA_TOKEN_PATH = env(SA_TOKEN)" "$PARAMS_YAML"
}

install_components $ITERATE_CLUSTER_NAME $ITERATE_CLUSTER_KUBECONFIG $ITERATE_CLUSTER_SA_TOKEN_PATH
install_components $BUILD_CLUSTER_NAME $BUILD_CLUSTER_KUBECONFIG $BUILD_CLUSTER_SA_TOKEN_PATH

for ((i = 0; i < $RUN_CLUSTER_COUNT; i++)); do
  RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)
  RUN_CLUSTER_SA_TOKEN_PATH=".clusters.run_clusters[$i].k8s_info.sa_token"

  install_components $RUN_CLUSTER_NAME $RUN_CLUSTER_KUBECONFIG $RUN_CLUSTER_SA_TOKEN_PATH
done
