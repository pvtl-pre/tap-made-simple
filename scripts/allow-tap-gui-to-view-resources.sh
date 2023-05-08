#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

BUILD_CLUSTER_KUBECONFIG=$(yq e .clusters.build_cluster.kubeconfig $PARAMS_YAML)
BUILD_CLUSTER_NAME=$(yq e .clusters.build_cluster.name $PARAMS_YAML)
BUILD_CLUSTER_YAML_PATH=".clusters.build_cluster"
ITERATE_CLUSTER_KUBECONFIG=$(yq e .clusters.iterate_cluster.kubeconfig $PARAMS_YAML)
ITERATE_CLUSTER_NAME=$(yq e .clusters.iterate_cluster.name $PARAMS_YAML)
ITERATE_CLUSTER_YAML_PATH=".clusters.iterate_cluster"
RUN_CLUSTER_COUNT=$(yq e '.clusters.run_clusters | length' $PARAMS_YAML)
VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.name $PARAMS_YAML)
VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.kubeconfig $PARAMS_YAML)

VIEW_PROFILE="generated/profiles/$VIEW_CLUSTER_NAME.yaml"

function install_components() {
  CLUSTER_NAME=$1
  KUBECONFIG=$2
  YAML_PATH=$3

  information "Installing TAP components to view cluster resources from cluster '$CLUSTER_NAME'"

  information "Adding TAP GUI multi-cluster RBAC on cluster '$CLUSTER_NAME'"

  KUBE_VERSION=$(kubectl version -o yaml --kubeconfig $KUBECONFIG | yq e '.serverVersion.minor')

  kubectl apply -f tap-declarative-yaml/tap-gui/tap-gui-viewer-service-account-rbac.yaml --kubeconfig $KUBECONFIG

  if [[ $KUBE_VERSION -ge 24 ]]; then
    kubectl apply -f tap-declarative-yaml/tap-gui/tap-gui-viewer-service-account-secret.yaml --kubeconfig $KUBECONFIG
    TAP_GUI_VIEWER_SECRET="tap-gui-viewer"
  else
    TAP_GUI_VIEWER_SECRET=$(kubectl -n tap-gui get sa tap-gui-viewer -o yaml --kubeconfig $KUBECONFIG | yq -r '.secrets[0].name')
  fi

  information "Getting endpoint on cluster '$CLUSTER_NAME'"

  export CLUSTER_URL=$(kubectl --kubeconfig $KUBECONFIG config view | yq '.clusters[0].cluster.server')

  yq e -i "$YAML_PATH.url = env(CLUSTER_URL)" "$PARAMS_YAML"

  information "Getting service account token on cluster '$CLUSTER_NAME'"

  export SA_TOKEN=$(kubectl -n tap-gui get secret $TAP_GUI_VIEWER_SECRET -o yaml --kubeconfig $KUBECONFIG | yq -r '.data["token"]' | base64 --decode)

  yq e -i "$YAML_PATH.sa_token = env(SA_TOKEN)" "$PARAMS_YAML"
}

install_components $ITERATE_CLUSTER_NAME $ITERATE_CLUSTER_KUBECONFIG $ITERATE_CLUSTER_YAML_PATH
install_components $BUILD_CLUSTER_NAME $BUILD_CLUSTER_KUBECONFIG $BUILD_CLUSTER_YAML_PATH

for ((i = 0; i < $RUN_CLUSTER_COUNT; i++)); do
  RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].kubeconfig $PARAMS_YAML)
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].name $PARAMS_YAML)
  RUN_CLUSTER_YAML_PATH=".clusters.run_clusters[$i]"

  install_components $RUN_CLUSTER_NAME $RUN_CLUSTER_KUBECONFIG $RUN_CLUSTER_YAML_PATH
done

information "Updating generated view profile with view cluster resources configuration"

ytt -f "$PARAMS_YAML" -f $VIEW_PROFILE -f profile-overlays/view-cluster-resources.yaml --output-files generated/profiles

$SCRIPTS/apply-view-profile.sh

$SCRIPTS/reconcile-view-cluster.sh
