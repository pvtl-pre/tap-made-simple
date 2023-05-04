#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

ITERATE_CLUSTER_KUBECONFIG=$(yq e .clusters.iterate_cluster.k8s_info.kubeconfig $PARAMS_YAML)
ITERATE_CLUSTER_NAME=$(yq e .clusters.iterate_cluster.k8s_info.name $PARAMS_YAML)

ITERATE_PROFILE="generated/profiles/$ITERATE_CLUSTER_NAME.yaml"

TAP_VERSION_YAML="tap-version.yaml"
TAP_VERSION=$(yq e .tap.version $TAP_VERSION_YAML)

information "Installing iterate profile"

tanzu package install tap \
  -n tap-install \
  -p tap.tanzu.vmware.com \
  -v $TAP_VERSION \
  -f $ITERATE_PROFILE \
  --kubeconfig $ITERATE_CLUSTER_KUBECONFIG \
  --wait=false
