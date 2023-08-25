#!/bin/bash
set -e -o pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source $SCRIPTS/set-env.sh

GITOPS_REPO_DIR="generated/gitops-repo"
ITERATE_CLUSTER_NAME=$(yq e .clusters.iterate_cluster.name $PARAMS_YAML)
RUN_CLUSTER_COUNT=$(yq e '.clusters.run_clusters | length' $PARAMS_YAML)
VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.name $PARAMS_YAML)

ITERATE_PROFILE_DIR="$GITOPS_REPO_DIR/clusters/$ITERATE_CLUSTER_NAME/cluster-config/values/"
VIEW_PROFILE_DIR="$GITOPS_REPO_DIR/clusters/$VIEW_CLUSTER_NAME/cluster-config/values/"

ITERATE_PROFILE="$ITERATE_PROFILE_DIR/tap-values.yaml"
VIEW_PROFILE="$VIEW_PROFILE_DIR/tap-values.yaml"

information "Updating profiles with load balancer configuration"

ytt -f "$PARAMS_YAML" -f $VIEW_PROFILE -f profile-overlays/load-balancer.yaml --output-files $VIEW_PROFILE_DIR
ytt -f "$PARAMS_YAML" -f $ITERATE_PROFILE -f profile-overlays/load-balancer.yaml --output-files $ITERATE_PROFILE_DIR

for ((i = 0; i < $RUN_CLUSTER_COUNT; i++)); do
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].name $PARAMS_YAML)

  RUN_PROFILE_DIR="$GITOPS_REPO_DIR/clusters/$RUN_CLUSTER_NAME/cluster-config/values/"

  RUN_PROFILE="$RUN_PROFILE_DIR/tap-values.yaml"

  ytt -f "$PARAMS_YAML" -f $RUN_PROFILE -f profile-overlays/load-balancer.yaml --output-files $RUN_PROFILE_DIR
done

$SCRIPTS/commit-gitops-repo.sh "Updating profiles with load balancer configuration"

$SCRIPTS/reconcile-view-cluster.sh
$SCRIPTS/reconcile-iterate-cluster.sh
$SCRIPTS/reconcile-run-clusters.sh
