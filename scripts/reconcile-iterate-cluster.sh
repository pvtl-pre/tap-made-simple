#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

ITERATE_CLUSTER_KUBECONFIG=$(yq e .clusters.iterate_cluster.kubeconfig $PARAMS_YAML)

information "Waiting for reconciliation on the Iterate Cluster"

kubectl wait pkgi --for condition=ReconcileSucceeded=True \
  -n tap-install tap \
  --kubeconfig $ITERATE_CLUSTER_KUBECONFIG \
  --timeout=15m
