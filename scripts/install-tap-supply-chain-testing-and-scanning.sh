#!/bin/bash
set -e -o pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source $SCRIPTS/set-env.sh

BUILD_CLUSTER_NAME=$(yq e .clusters.build_cluster.k8s_info.name $PARAMS_YAML)

BUILD_PROFILE="generated/profiles/$BUILD_CLUSTER_NAME.yaml"

information "Updating generated build profile with testing and scanning supply chain configuration"

ytt -f "$PARAMS_YAML" -f $BUILD_PROFILE -f profile-overlays/supply-chain-testing-and-scanning.yaml --output-files generated/profiles

$SCRIPTS/install-tap-build-profile.sh

$SCRIPTS/reconcile-tap-install-for-build-cluster.sh
