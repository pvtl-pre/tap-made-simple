#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

AGE_KEY_PATH=$(yq e .gitops.age_key_path $PARAMS_YAML)
BUILD_CLUSTER_KUBECONFIG=$(yq e .clusters.build_cluster.kubeconfig $PARAMS_YAML)
BUILD_CLUSTER_NAME=$(yq e .clusters.build_cluster.name $PARAMS_YAML)
GITOPS_REPO_DIR="generated/gitops-repo"
ITERATE_CLUSTER_KUBECONFIG=$(yq e .clusters.iterate_cluster.kubeconfig $PARAMS_YAML)
ITERATE_CLUSTER_NAME=$(yq e .clusters.iterate_cluster.name $PARAMS_YAML)
RUN_CLUSTER_COUNT=$(yq e '.clusters.run_clusters | length' $PARAMS_YAML)
VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.kubeconfig $PARAMS_YAML)
VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.name $PARAMS_YAML)

export SOPS_AGE_RECIPIENTS=$(age-keygen -y $AGE_KEY_PATH)
export SOPS_AGE_KEY=$(cat $AGE_KEY_PATH)

function deploy() {
  CLUSTER_NAME=$1
  KUBECONFIG=$2

  (
    cd $GITOPS_REPO_DIR/clusters/$CLUSTER_NAME

    KUBECONFIG=../../../../$KUBECONFIG ./tanzu-sync/scripts/deploy.sh -y --wait=false
  )
}

information "Deploying kapp 'tanzu-sync' to the View Cluster"

deploy $VIEW_CLUSTER_NAME $VIEW_CLUSTER_KUBECONFIG

information "Deploying kapp 'tanzu-sync' to the Iterate Cluster"

deploy $ITERATE_CLUSTER_NAME $ITERATE_CLUSTER_KUBECONFIG

information "Deploying kapp 'tanzu-sync' to the Build Cluster"

deploy $BUILD_CLUSTER_NAME $BUILD_CLUSTER_KUBECONFIG

for ((i = 0; i < $RUN_CLUSTER_COUNT; i++)); do
  RUN_CLUSTER_KUBECONFIG="$(yq e .clusters.run_clusters[$i].kubeconfig $PARAMS_YAML)"
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].name $PARAMS_YAML)

  information "Deploying kapp 'tanzu-sync' on cluster '$RUN_CLUSTER_NAME'"

  deploy $RUN_CLUSTER_NAME $RUN_CLUSTER_KUBECONFIG
done
