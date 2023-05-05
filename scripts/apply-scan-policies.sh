#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

BUILD_CLUSTER_KUBECONFIG=$(yq e .clusters.build_cluster.kubeconfig $PARAMS_YAML)

information "Create a scan policy to the developer namespace on the Build Cluster"

kubectl apply -f tap-declarative-yaml/dev-namespace/scan-policy.yaml -n product-team1 --kubeconfig $BUILD_CLUSTER_KUBECONFIG
