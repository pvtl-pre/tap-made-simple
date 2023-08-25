#!/bin/bash
set -e -o pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source $SCRIPTS/set-env.sh

GITOPS_REPO_DIR="generated/gitops-repo"
VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.name $PARAMS_YAML)
VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.kubeconfig $PARAMS_YAML)

VIEW_INSTALL_DIR="$GITOPS_REPO_DIR/clusters/$VIEW_CLUSTER_NAME/cluster-config/config/tap-install/"
VIEW_PROFILE_DIR="$GITOPS_REPO_DIR/clusters/$VIEW_CLUSTER_NAME/cluster-config/values/"

VIEW_PROFILE="$VIEW_PROFILE_DIR/tap-values.yaml"

information "Add TAP GUI database on the View Cluster"

helm repo add bitnami https://charts.bitnami.com/bitnami

kubectl create ns tap-gui-backend --dry-run=client -o yaml > $VIEW_INSTALL_DIR/tap-gui-backend-ns.yaml

helm template tap-gui-db bitnami/postgresql \
  -n tap-gui-backend \
  --set auth.username="tapuser" \
  --set auth.password="VMware1!" \
  --kubeconfig $VIEW_CLUSTER_KUBECONFIG \
  > $VIEW_INSTALL_DIR/tap-gui-db.yaml

information "Updating view profile with TAP GUI database configuration"

ytt -f "$PARAMS_YAML" -f $VIEW_PROFILE -f profile-overlays/tap-gui-database.yaml --output-files $VIEW_PROFILE_DIR

$SCRIPTS/commit-gitops-repo.sh "Updating view profile with TAP GUI database configuration"

$SCRIPTS/reconcile-view-cluster.sh
