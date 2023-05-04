#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.k8s_info.kubeconfig $PARAMS_YAML)

information "Waiting for reconciliation on the View Cluster"

kubectl wait pkgi --for condition=ReconcileSucceeded=True \
  -n tap-install tap \
  --kubeconfig $VIEW_CLUSTER_KUBECONFIG \
  --timeout=15m
