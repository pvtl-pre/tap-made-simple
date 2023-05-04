#!/bin/bash
set -e -o pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source $SCRIPTS/set-env.sh

VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.k8s_info.name $PARAMS_YAML)

VIEW_PROFILE="generated/profiles/$VIEW_CLUSTER_NAME.yaml"

information "Updating generated profiles with application accelerator configuration"

ytt -f "$PARAMS_YAML" -f $VIEW_PROFILE -f profile-overlays/application-accelerator.yaml --output-files generated/profiles

$SCRIPTS/apply-view-profile.sh

$SCRIPTS/reconcile-view-cluster.sh
