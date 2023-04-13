#!/bin/bash
set -e -o pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source $SCRIPTS/set-env.sh

BUILD_CLUSTER_NAME=$(yq e .clusters.build_cluster.k8s_info.name $PARAMS_YAML)
ITERATE_CLUSTER_NAME=$(yq e .clusters.iterate_cluster.k8s_info.name $PARAMS_YAML)

BUILD_PROFILE="generated/profiles/$BUILD_CLUSTER_NAME.yaml"
ITERATE_PROFILE="generated/profiles/$ITERATE_CLUSTER_NAME.yaml"

information "Updating generated profiles with testing supply chain configuration"

ytt -f "$PARAMS_YAML" -f $BUILD_PROFILE -f profile-overlays/supply-chain-testing.yaml --output-files generated/profiles
ytt -f "$PARAMS_YAML" -f $ITERATE_PROFILE -f profile-overlays/supply-chain-testing.yaml --output-files generated/profiles

$SCRIPTS/install-tap-build-profile.sh
$SCRIPTS/install-tap-iterate-profile.sh

$SCRIPTS/reconcile-tap-install-for-build-cluster.sh
$SCRIPTS/reconcile-tap-install-for-iterate-cluster.sh
