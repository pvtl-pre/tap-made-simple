#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

export SSH_KEY_PATH="generated/ssh-key"
export KUBECONFIGS_PATH="generated/kubeconfigs"

mkdir -p $KUBECONFIGS_PATH

if [ -f "$SSH_KEY_PATH" ]; then
  information "Skipping ssh key generation since it exists"
else
  information "Generating ssh key at $SSH_KEY_PATH"
  ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -q -N ""

  yq e -i '.clusters.ssh_key_path = env(SSH_KEY_PATH)' "$PARAMS_YAML"
fi

information "Building create clusters command"

VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.k8s_info.name $PARAMS_YAML)
export VIEW_CLUSTER_KUBECONFIG="$KUBECONFIGS_PATH/$VIEW_CLUSTER_NAME.yaml"

yq e -i '.clusters.view_cluster.k8s_info.kubeconfig = env(VIEW_CLUSTER_KUBECONFIG)' "$PARAMS_YAML"

BUILD_CLUSTER_NAME=$(yq e .clusters.build_cluster.k8s_info.name $PARAMS_YAML)
export BUILD_CLUSTER_KUBECONFIG="$KUBECONFIGS_PATH/$BUILD_CLUSTER_NAME.yaml"

yq e -i '.clusters.build_cluster.k8s_info.kubeconfig = env(BUILD_CLUSTER_KUBECONFIG)' "$PARAMS_YAML"

RUN_CLUSTERS_DEPLOY_COMMAND=""

declare -a run_clusters=($(yq e -o=j -I=0 '.clusters.run_clusters[]' $PARAMS_YAML))

for ((i=0;i<${#run_clusters[@]};i++)); 
do
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)
  export RUN_CLUSTER_KUBECONFIG="$KUBECONFIGS_PATH/$RUN_CLUSTER_NAME.yaml"
  export RUN_CLUSTER_URL=$(kubectl --kubeconfig $RUN_CLUSTER_KUBECONFIG config view | yq '.clusters[0].cluster.server')

  current_cluster_command="CLUSTER_NAME=$RUN_CLUSTER_NAME KUBECONFIG=$RUN_CLUSTER_KUBECONFIG $TKG_LAB_SCRIPTS/03a-deploy-azure-k8s-cluster.sh"

  if [[ "$i" -eq "0" ]]; then
    RUN_CLUSTERS_DEPLOY_COMMAND="$current_cluster_command"
  else
    RUN_CLUSTERS_DEPLOY_COMMAND="$RUN_CLUSTERS_DEPLOY_COMMAND & $current_cluster_command"
  fi

  yq e -i ".clusters.run_clusters[$i].k8s_info.kubeconfig = env(RUN_CLUSTER_KUBECONFIG)" "$PARAMS_YAML"
  yq e -i ".clusters.run_clusters[$i].k8s_info.url = env(RUN_CLUSTER_URL)" "$PARAMS_YAML"
done

information "Creating clusters in parallel"

CLUSTER_NAME=$VIEW_CLUSTER_NAME \
KUBECONFIG=$VIEW_CLUSTER_KUBECONFIG \
$TKG_LAB_SCRIPTS/03a-deploy-azure-k8s-cluster.sh \
& \
CLUSTER_NAME=$BUILD_CLUSTER_NAME \
KUBECONFIG=$BUILD_CLUSTER_KUBECONFIG \
$TKG_LAB_SCRIPTS/03a-deploy-azure-k8s-cluster.sh \
& \
eval $RUN_CLUSTERS_DEPLOY_COMMAND

wait

information "Clusters created"

information "Getting K8S urls"

export VIEW_CLUSTER_URL=$(kubectl --kubeconfig $VIEW_CLUSTER_KUBECONFIG config view | yq '.clusters[0].cluster.server')
yq e -i '.clusters.view_cluster.k8s_info.url = env(VIEW_CLUSTER_URL)' "$PARAMS_YAML"

export BUILD_CLUSTER_URL=$(kubectl --kubeconfig $BUILD_CLUSTER_KUBECONFIG config view | yq '.clusters[0].cluster.server')
yq e -i '.clusters.build_cluster.k8s_info.url = env(BUILD_CLUSTER_URL)' "$PARAMS_YAML"

for ((i=0;i<${#run_clusters[@]};i++)); 
do
  export RUN_CLUSTER_KUBECONFIG="$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)"
  export RUN_CLUSTER_URL=$(kubectl --kubeconfig $RUN_CLUSTER_KUBECONFIG config view | yq '.clusters[0].cluster.server')

  yq e -i ".clusters.run_clusters[$i].k8s_info.url = env(RUN_CLUSTER_URL)" "$PARAMS_YAML"
done
