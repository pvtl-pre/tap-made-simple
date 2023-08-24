#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

BUILD_CLUSTER_KUBECONFIG=$(yq e .clusters.build_cluster.kubeconfig $PARAMS_YAML)

information "Waiting for reconciliation on the Build Cluster"

kctrl app kick -a sync -n tanzu-sync -y --kubeconfig $BUILD_CLUSTER_KUBECONFIG $@
