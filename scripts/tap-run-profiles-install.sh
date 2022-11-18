#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

TAP_VERSION=$(yq e .tap_version $PARAMS_YAML)

mkdir -p generated/profile-templates

declare -a run_clusters=($(yq e -o=j -I=0 '.clusters.run_clusters[]' $PARAMS_YAML))

for ((i=0;i<${#run_clusters[@]};i++)); 
do
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)
  RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)

  RUN_PROFILE="generated/profile-templates/$RUN_CLUSTER_NAME.yaml"

  information "Generating run profile for cluster $RUN_CLUSTER_NAME"

  ytt --data-value-yaml index=$i -f "$PARAMS_YAML" -f profile-templates/run.yaml > $RUN_PROFILE

  information "Installing run profile on cluster $RUN_CLUSTER_NAME"

  tanzu package install tap \
    -n tap-install \
    -p tap.tanzu.vmware.com \
    -v $TAP_VERSION \
    -f $RUN_PROFILE \
    --kubeconfig $RUN_CLUSTER_KUBECONFIG \
    --wait=false
done
