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

BUILD_PROFILE="$GITOPS_REPO_DIR/clusters/$BUILD_CLUSTER_NAME/cluster-config/values/tap-values.yaml"
ITERATE_PROFILE="$GITOPS_REPO_DIR/clusters/$ITERATE_CLUSTER_NAME/cluster-config/values/tap-values.yaml"
VIEW_PROFILE="$GITOPS_REPO_DIR/clusters/$VIEW_CLUSTER_NAME/cluster-config/values/tap-values.yaml"

SENSITIVE_BUILD_PROFILE="$GITOPS_REPO_DIR/clusters/$BUILD_CLUSTER_NAME/cluster-config/values/tap-sensitive-values.sops.yaml"
SENSITIVE_ITERATE_PROFILE="$GITOPS_REPO_DIR/clusters/$ITERATE_CLUSTER_NAME/cluster-config/values/tap-sensitive-values.sops.yaml"
SENSITIVE_VIEW_PROFILE="$GITOPS_REPO_DIR/clusters/$VIEW_CLUSTER_NAME/cluster-config/values/tap-sensitive-values.sops.yaml"

information "Generating tap-values from templates"

ytt -f "$PARAMS_YAML" -f values/view-profile.yaml >$VIEW_PROFILE
ytt -f "$PARAMS_YAML" -f values/iterate-profile.yaml >$ITERATE_PROFILE
ytt -f "$PARAMS_YAML" -f values/build-profile.yaml >$BUILD_PROFILE

for ((i = 0; i < $RUN_CLUSTER_COUNT; i++)); do
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].name $PARAMS_YAML)

  RUN_PROFILE="$GITOPS_REPO_DIR/clusters/$RUN_CLUSTER_NAME/cluster-config/values/tap-values.yaml"

  ytt --data-value-yaml index=$i -f "$PARAMS_YAML" -f values/run-profile.yaml >$RUN_PROFILE
done

information "Generating sensitive tap-values from templates"

ytt -f "$PARAMS_YAML" -f values/sensitive-view-profile.yaml >$SENSITIVE_VIEW_PROFILE
ytt -f "$PARAMS_YAML" -f values/sensitive-iterate-profile.yaml >$SENSITIVE_ITERATE_PROFILE
ytt -f "$PARAMS_YAML" -f values/sensitive-build-profile.yaml >$SENSITIVE_BUILD_PROFILE

sops --in-place --encrypt $SENSITIVE_VIEW_PROFILE
sops --in-place --encrypt $SENSITIVE_ITERATE_PROFILE
sops --in-place --encrypt $SENSITIVE_BUILD_PROFILE

for ((i = 0; i < $RUN_CLUSTER_COUNT; i++)); do
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].name $PARAMS_YAML)

  SENSITIVE_RUN_PROFILE="$GITOPS_REPO_DIR/clusters/$RUN_CLUSTER_NAME/cluster-config/values/tap-sensitive-values.sops.yaml"

  ytt -f "$PARAMS_YAML" -f values/sensitive-run-profile.yaml >$SENSITIVE_RUN_PROFILE

  sops --in-place --encrypt $SENSITIVE_RUN_PROFILE
done

information "Adding tap-values to the GitOps Repo"

$SCRIPTS/commit-gitops-repo.sh "Adding tap-values"
