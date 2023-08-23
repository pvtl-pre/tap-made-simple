#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

AGE_KEY_PATH=$(yq e .gitops.age_key_path $PARAMS_YAML)
BUILD_CLUSTER_NAME=$(yq e .clusters.build_cluster.name $PARAMS_YAML)
GITOPS_REPO_DIR="generated/gitops-repo"
ITERATE_CLUSTER_NAME=$(yq e .clusters.iterate_cluster.name $PARAMS_YAML)
RUN_CLUSTER_COUNT=$(yq e '.clusters.run_clusters | length' $PARAMS_YAML)
VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.name $PARAMS_YAML)

export SOPS_AGE_RECIPIENTS=$(age-keygen -y $AGE_KEY_PATH)
export SOPS_AGE_KEY=$(cat $AGE_KEY_PATH)

BUILD_TANZU_SYNC="$GITOPS_REPO_DIR/clusters/$BUILD_CLUSTER_NAME/tanzu-sync/app/sensitive-values/tanzu-sync-values.sops.yaml"
ITERATE_TANZU_SYNC="$GITOPS_REPO_DIR/clusters/$ITERATE_CLUSTER_NAME/tanzu-sync/app/sensitive-values/tanzu-sync-values.sops.yaml"
VIEW_TANZU_SYNC="$GITOPS_REPO_DIR/clusters/$VIEW_CLUSTER_NAME/tanzu-sync/app/sensitive-values/tanzu-sync-values.sops.yaml"

information "Generating tanzu sync values"

ytt --data-value-file age_key=$AGE_KEY_PATH -f "$PARAMS_YAML" -f values/tanzu-sync-values.yaml >$VIEW_TANZU_SYNC
ytt --data-value-file age_key=$AGE_KEY_PATH -f "$PARAMS_YAML" -f values/tanzu-sync-values.yaml >$ITERATE_TANZU_SYNC
ytt --data-value-file age_key=$AGE_KEY_PATH -f "$PARAMS_YAML" -f values/tanzu-sync-values.yaml >$BUILD_TANZU_SYNC

sops --in-place --encrypt $VIEW_TANZU_SYNC
sops --in-place --encrypt $ITERATE_TANZU_SYNC
sops --in-place --encrypt $BUILD_TANZU_SYNC

for ((i = 0; i < $RUN_CLUSTER_COUNT; i++)); do
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].name $PARAMS_YAML)

  RUN_TANZU_SYNC="$GITOPS_REPO_DIR/clusters/$RUN_CLUSTER_NAME/tanzu-sync/app/sensitive-values/tanzu-sync-values.sops.yaml"

  ytt --data-value-file age_key=$AGE_KEY_PATH -f "$PARAMS_YAML" -f values/tanzu-sync-values.yaml >$RUN_TANZU_SYNC
  
  sops --in-place --encrypt $RUN_TANZU_SYNC
done

information "Adding tanzu-sync-values to the GitOps Repo"

$SCRIPTS/commit-gitops-repo.sh "Adding tanzu-sync-values"
