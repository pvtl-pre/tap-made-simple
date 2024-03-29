#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

RUN_CLUSTER_COUNT=$(yq e '.clusters.run_clusters | length' $PARAMS_YAML)

TAP_VERSION_YAML="tap-version.yaml"
TAP_VERSION=$(yq e .tap.version $TAP_VERSION_YAML)

for ((i = 0; i < $RUN_CLUSTER_COUNT; i++)); do
  RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].kubeconfig $PARAMS_YAML)
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].name $PARAMS_YAML)

  RUN_PROFILE="generated/profiles/$RUN_CLUSTER_NAME.yaml"

  information "Installing run profile on cluster '$RUN_CLUSTER_NAME'"

  tanzu package install tap \
    -n tap-install \
    -p tap.tanzu.vmware.com \
    -v $TAP_VERSION \
    -f $RUN_PROFILE \
    --kubeconfig $RUN_CLUSTER_KUBECONFIG \
    --wait=false
done
