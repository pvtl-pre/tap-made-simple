#!/bin/bash
set -e -o pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source $SCRIPTS/set-env.sh

VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.name $PARAMS_YAML)
VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.kubeconfig $PARAMS_YAML)

VIEW_PROFILE="generated/profiles/$VIEW_CLUSTER_NAME.yaml"

information "Updating generated view profile with TAP GUI auth configuration"

ytt -f "$PARAMS_YAML" -f $VIEW_PROFILE -f profile-overlays/tap-gui-auth.yaml --output-files generated/profiles

$SCRIPTS/apply-view-profile.sh

$SCRIPTS/reconcile-view-cluster.sh
