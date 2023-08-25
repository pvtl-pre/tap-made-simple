#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

BUILD_CLUSTER_KUBECONFIG=$(yq e .clusters.build_cluster.kubeconfig $PARAMS_YAML)
BUILD_CLUSTER_NAME=$(yq e .clusters.build_cluster.name $PARAMS_YAML)
BUILD_CLUSTER_YAML_PATH=".clusters.build_cluster"
GITOPS_REPO_DIR="generated/gitops-repo"
ITERATE_CLUSTER_KUBECONFIG=$(yq e .clusters.iterate_cluster.kubeconfig $PARAMS_YAML)
ITERATE_CLUSTER_NAME=$(yq e .clusters.iterate_cluster.name $PARAMS_YAML)
ITERATE_CLUSTER_YAML_PATH=".clusters.iterate_cluster"
RUN_CLUSTER_COUNT=$(yq e '.clusters.run_clusters | length' $PARAMS_YAML)
VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.kubeconfig $PARAMS_YAML)
VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.name $PARAMS_YAML)

VIEW_PROFILE="$GITOPS_REPO_DIR/clusters/$VIEW_CLUSTER_NAME/cluster-config/values/tap-values.yaml"

function add_components() {
  CLUSTER_NAME=$1

  information "Adding TAP components to view cluster resources from cluster '$CLUSTER_NAME'"

  cp tap-declarative-yaml/tap-gui/tap-gui-viewer-service-account-rbac.yaml $GITOPS_REPO_DIR/clusters/$CLUSTER_NAME/cluster-config/config/tap-install/
  cp tap-declarative-yaml/tap-gui/tap-gui-viewer-service-account-secret.yaml $GITOPS_REPO_DIR/clusters/$CLUSTER_NAME/cluster-config/config/tap-install/
}

function set_sa_token() {
  CLUSTER_NAME=$1
  KUBECONFIG=$2
  YAML_PATH=$3

  information "Getting endpoint on cluster '$CLUSTER_NAME'"

  export CLUSTER_URL=$(kubectl --kubeconfig $KUBECONFIG config view | yq '.clusters[0].cluster.server')

  yq e -i "$YAML_PATH.url = env(CLUSTER_URL)" "$PARAMS_YAML"

  information "Waiting for secret 'tap-gui-viewer' on cluster '$CLUSTER_NAME'"

  while ! kubectl -n tap-gui get secret tap-gui-viewer --kubeconfig $KUBECONFIG >/dev/null 2>&1; do sleep 2; done

  information "Getting service account token on cluster '$CLUSTER_NAME'"

  export SA_TOKEN=$(kubectl -n tap-gui get secret tap-gui-viewer -o yaml --kubeconfig $KUBECONFIG | yq -r '.data["token"]' | base64 --decode)

  yq e -i "$YAML_PATH.sa_token = env(SA_TOKEN)" "$PARAMS_YAML"
}

add_components $ITERATE_CLUSTER_NAME
add_components $BUILD_CLUSTER_NAME

for ((i = 0; i < $RUN_CLUSTER_COUNT; i++)); do
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].name $PARAMS_YAML)

  add_components $RUN_CLUSTER_NAME
done

$SCRIPTS/commit-gitops-repo.sh "Adding TAP components to view cluster resources"

$SCRIPTS/reconcile-iterate-cluster.sh --wait=false
$SCRIPTS/reconcile-build-cluster.sh --wait=false
$SCRIPTS/reconcile-run-clusters.sh --wait=false

set_sa_token $ITERATE_CLUSTER_NAME $ITERATE_CLUSTER_KUBECONFIG $ITERATE_CLUSTER_YAML_PATH
set_sa_token $BUILD_CLUSTER_NAME $BUILD_CLUSTER_KUBECONFIG $BUILD_CLUSTER_YAML_PATH

for ((i = 0; i < $RUN_CLUSTER_COUNT; i++)); do
  RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].kubeconfig $PARAMS_YAML)
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].name $PARAMS_YAML)
  RUN_CLUSTER_YAML_PATH=".clusters.run_clusters[$i]"

  set_sa_token $RUN_CLUSTER_NAME $RUN_CLUSTER_KUBECONFIG $RUN_CLUSTER_YAML_PATH
done

information "Updating view profile with Iterate, Build and Run Cluster information"

ytt -f "$PARAMS_YAML" -f $VIEW_PROFILE -f profile-overlays/tap-gui-view-resources.yaml --output-files $GITOPS_REPO_DIR/clusters/$VIEW_CLUSTER_NAME/cluster-config/values/

$SCRIPTS/commit-gitops-repo.sh "Updating view profile with Iterate, Build and Run Cluster information"

$SCRIPTS/reconcile-view-cluster.sh
