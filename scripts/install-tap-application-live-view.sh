#!/bin/bash
set -e -o pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source $SCRIPTS/set-env.sh

BUILD_CLUSTER_NAME=$(yq e .clusters.build_cluster.k8s_info.name $PARAMS_YAML)
ITERATE_CLUSTER_NAME=$(yq e .clusters.iterate_cluster.k8s_info.name $PARAMS_YAML)
RUN_CLUSTER_COUNT=$(yq e '.clusters.run_clusters | length' $PARAMS_YAML)
VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.k8s_info.name $PARAMS_YAML)

BUILD_PROFILE="generated/profiles/$BUILD_CLUSTER_NAME.yaml"
ITERATE_PROFILE="generated/profiles/$ITERATE_CLUSTER_NAME.yaml"
VIEW_PROFILE="generated/profiles/$VIEW_CLUSTER_NAME.yaml"

information "Updating generated profiles with application live view configuration"

ytt -f "$PARAMS_YAML" -f $BUILD_PROFILE -f profile-overlays/application-live-view-conventions.yaml --output-files generated/profiles
ytt -f "$PARAMS_YAML" -f $VIEW_PROFILE -f profile-overlays/application-live-view-backend.yaml --output-files generated/profiles
ytt -f "$PARAMS_YAML" -f $ITERATE_PROFILE -f profile-overlays/application-live-view-connector.yaml --output-files generated/profiles
ytt -f "$PARAMS_YAML" -f $ITERATE_PROFILE -f profile-overlays/application-live-view-conventions.yaml --output-files generated/profiles

for ((i = 0; i < $RUN_CLUSTER_COUNT; i++)); do
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)

  RUN_PROFILE="generated/profiles/$RUN_CLUSTER_NAME.yaml"

  ytt --data-value-yaml index=$i -f "$PARAMS_YAML" -f $RUN_PROFILE -f profile-overlays/application-live-view-connector.yaml --output-files generated/profiles
done

$SCRIPTS/install-tap-view-profile.sh
$SCRIPTS/install-tap-iterate-profile.sh
$SCRIPTS/install-tap-build-profile.sh
$SCRIPTS/install-tap-run-profiles.sh

$SCRIPTS/reconcile-tap-install-for-view-cluster.sh
$SCRIPTS/reconcile-tap-install-for-iterate-cluster.sh
$SCRIPTS/reconcile-tap-install-for-build-cluster.sh
$SCRIPTS/reconcile-tap-install-for-run-clusters.sh
