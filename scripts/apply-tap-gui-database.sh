#!/bin/bash
set -e -o pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source $SCRIPTS/set-env.sh

VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.name $PARAMS_YAML)
VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.kubeconfig $PARAMS_YAML)

VIEW_PROFILE="generated/profiles/$VIEW_CLUSTER_NAME.yaml"

information "Deploy TAP GUI database on the View Cluster"

helm repo add bitnami https://charts.bitnami.com/bitnami

kubectl create ns tap-gui-backend --dry-run=client -o yaml | kubectl --kubeconfig $VIEW_CLUSTER_KUBECONFIG apply -f -

helm upgrade --install tap-gui-db bitnami/postgresql \
  -n tap-gui-backend \
  --set auth.username="tapuser" \
  --set auth.password="VMware1!" \
  --kubeconfig $VIEW_CLUSTER_KUBECONFIG

information "Updating generated view profile with TAP GUI database configuration"

ytt -f "$PARAMS_YAML" -f $VIEW_PROFILE -f profile-overlays/tap-gui-database.yaml --output-files generated/profiles

$SCRIPTS/apply-view-profile.sh

$SCRIPTS/reconcile-view-cluster.sh
