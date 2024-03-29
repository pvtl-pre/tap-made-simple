#!/bin/bash
set -e -o pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source $SCRIPTS/set-env.sh

ITERATE_CLUSTER_NAME=$(yq e .clusters.iterate_cluster.name $PARAMS_YAML)
RUN_CLUSTER_COUNT=$(yq e '.clusters.run_clusters | length' $PARAMS_YAML)
VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.name $PARAMS_YAML)

ITERATE_PROFILE="generated/profiles/$ITERATE_CLUSTER_NAME.yaml"
VIEW_PROFILE="generated/profiles/$VIEW_CLUSTER_NAME.yaml"

information "Updating generated profiles with load balancer configuration"

ytt -f "$PARAMS_YAML" -f $VIEW_PROFILE -f profile-overlays/load-balancer.yaml --output-files generated/profiles
ytt -f "$PARAMS_YAML" -f $ITERATE_PROFILE -f profile-overlays/load-balancer.yaml --output-files generated/profiles

for ((i = 0; i < $RUN_CLUSTER_COUNT; i++)); do
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].name $PARAMS_YAML)

  RUN_PROFILE="generated/profiles/$RUN_CLUSTER_NAME.yaml"

  ytt -f "$PARAMS_YAML" -f $RUN_PROFILE -f profile-overlays/load-balancer.yaml --output-files generated/profiles
done

$SCRIPTS/apply-view-profile.sh
$SCRIPTS/apply-iterate-profile.sh
$SCRIPTS/apply-run-profiles.sh

$SCRIPTS/reconcile-view-cluster.sh
$SCRIPTS/reconcile-iterate-cluster.sh
$SCRIPTS/reconcile-run-clusters.sh
