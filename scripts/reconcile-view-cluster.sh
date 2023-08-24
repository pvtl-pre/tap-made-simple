#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.kubeconfig $PARAMS_YAML)

information "Waiting for reconciliation on the View Cluster"

kctrl app kick -a sync -n tanzu-sync -y --kubeconfig $VIEW_CLUSTER_KUBECONFIG $@
