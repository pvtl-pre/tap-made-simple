#!/bin/bash
set -e -o pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source $SCRIPTS/set-env.sh

GITOPS_REPO_DIR="generated/gitops-repo"
VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.name $PARAMS_YAML)
VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.kubeconfig $PARAMS_YAML)

VIEW_PROFILE_DIR="$GITOPS_REPO_DIR/clusters/$VIEW_CLUSTER_NAME/cluster-config/values/"

VIEW_PROFILE="$VIEW_PROFILE_DIR/tap-values.yaml"

information "Updating view profile with TAP GUI auth configuration"

ytt -f "$PARAMS_YAML" -f $VIEW_PROFILE -f profile-overlays/tap-gui-auth.yaml --output-files $VIEW_PROFILE_DIR

$SCRIPTS/commit-gitops-repo.sh "Updating view profile with TAP GUI auth configuration"

$SCRIPTS/reconcile-view-cluster.sh
