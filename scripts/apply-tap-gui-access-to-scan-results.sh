#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.name $PARAMS_YAML)
VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.kubeconfig $PARAMS_YAML)

VIEW_PROFILE="generated/profiles/$VIEW_CLUSTER_NAME.yaml"

information "Getting metadata store access token"

export METADATA_STORE_ACCESS_TOKEN=$(kubectl get secrets metadata-store-read-write-client -n metadata-store -o jsonpath="{.data.token}" --kubeconfig $VIEW_CLUSTER_KUBECONFIG | base64 -d)

information "Updating generated view profile with TAP GUI access to the metadata store configuration"

ytt -v access_token="Bearer $METADATA_STORE_ACCESS_TOKEN" -f $VIEW_PROFILE -f profile-overlays/tap-gui-metadata-store-auth.yaml --output-files generated/profiles

$SCRIPTS/apply-view-profile.sh

$SCRIPTS/reconcile-view-cluster.sh
