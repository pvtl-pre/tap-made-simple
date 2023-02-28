#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

RESOURCE_GROUP=$(yq e .azure.resource_group $PARAMS_YAML)
NODE_SIZE=$(yq e .azure.node_size $PARAMS_YAML)

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

information "Getting kubeconfig paths"

VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.k8s_info.name $PARAMS_YAML)
export VIEW_CLUSTER_KUBECONFIG="$KUBECONFIGS_PATH/$VIEW_CLUSTER_NAME.yaml"

yq e -i '.clusters.view_cluster.k8s_info.kubeconfig = env(VIEW_CLUSTER_KUBECONFIG)' "$PARAMS_YAML"

ITERATE_CLUSTER_NAME=$(yq e .clusters.iterate_cluster.k8s_info.name $PARAMS_YAML)
export ITERATE_CLUSTER_KUBECONFIG="$KUBECONFIGS_PATH/$ITERATE_CLUSTER_NAME.yaml"

yq e -i '.clusters.iterate_cluster.k8s_info.kubeconfig = env(ITERATE_CLUSTER_KUBECONFIG)' "$PARAMS_YAML"

BUILD_CLUSTER_NAME=$(yq e .clusters.build_cluster.k8s_info.name $PARAMS_YAML)
export BUILD_CLUSTER_KUBECONFIG="$KUBECONFIGS_PATH/$BUILD_CLUSTER_NAME.yaml"

yq e -i '.clusters.build_cluster.k8s_info.kubeconfig = env(BUILD_CLUSTER_KUBECONFIG)' "$PARAMS_YAML"

declare -a run_clusters=($(yq e -o=j -I=0 '.clusters.run_clusters[]' $PARAMS_YAML))

for ((i=0;i<${#run_clusters[@]};i++));
do
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)
  export RUN_CLUSTER_KUBECONFIG="$KUBECONFIGS_PATH/$RUN_CLUSTER_NAME.yaml"

  yq e -i ".clusters.run_clusters[$i].k8s_info.kubeconfig = env(RUN_CLUSTER_KUBECONFIG)" "$PARAMS_YAML"
done

CLUSTER_EXISTS=$(az aks list | jq "any(.name == \"$VIEW_CLUSTER_NAME\")")

if [[ $CLUSTER_EXISTS == false ]]; then
  information "Creating View Cluster"
  az aks create --name $VIEW_CLUSTER_NAME --resource-group $RESOURCE_GROUP --node-vm-size $NODE_SIZE --node-count 1 --ssh-key-value $SSH_KEY_PATH.pub --yes --no-wait
  CREATING_VIEW_CLUSTER=true
fi

CLUSTER_EXISTS=$(az aks list | jq "any(.name == \"$ITERATE_CLUSTER_NAME\")")

if [[ $CLUSTER_EXISTS == false ]]; then
  information "Creating Iterate Cluster"
  az aks create --name $ITERATE_CLUSTER_NAME --resource-group $RESOURCE_GROUP --node-vm-size $NODE_SIZE --node-count 2 --ssh-key-value $SSH_KEY_PATH.pub --yes --no-wait
  CREATING_ITERATE_CLUSTER=true
fi

CLUSTER_EXISTS=$(az aks list | jq "any(.name == \"$BUILD_CLUSTER_NAME\")")

if [[ $CLUSTER_EXISTS == false ]]; then
  information "Creating Build Cluster"
  az aks create --name $BUILD_CLUSTER_NAME --resource-group $RESOURCE_GROUP --node-vm-size $NODE_SIZE --node-count 2 --ssh-key-value $SSH_KEY_PATH.pub --yes --no-wait
  CREATING_BUILD_CLUSTER=true
fi

declare -a run_clusters=($(yq e -o=j -I=0 '.clusters.run_clusters[]' $PARAMS_YAML))
declare -a CREATING_RUN_CLUSTERS=()

for ((i=0;i<${#run_clusters[@]};i++));
do
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)

  CLUSTER_EXISTS=$(az aks list | jq "any(.name == \"$RUN_CLUSTER_NAME\")")

  if [[ $CLUSTER_EXISTS == false ]]; then
    information "Creating Run Cluster '$RUN_CLUSTER_NAME'"
    az aks create --name $RUN_CLUSTER_NAME --resource-group $RESOURCE_GROUP --node-vm-size $NODE_SIZE --node-count 2 --ssh-key-value $SSH_KEY_PATH.pub --yes --no-wait
    CREATING_RUN_CLUSTERS+=(true)
  else
    CREATING_RUN_CLUSTERS+=(false)
  fi
done

if [[ $CREATING_VIEW_CLUSTER == true ]]; then
  information "Waiting for creation of the View Cluster"

  az aks wait --name $VIEW_CLUSTER_NAME --resource-group $RESOURCE_GROUP --created --interval 5
else
  information "View Cluster already exists"
fi

if [[ $CREATING_ITERATE_CLUSTER == true ]]; then
  information "Waiting for creation of the Iterate Cluster"

  az aks wait --name $ITERATE_CLUSTER_NAME --resource-group $RESOURCE_GROUP --created --interval 5
else
  information "Iterate Cluster already exists"
fi

if [[ $CREATING_BUILD_CLUSTER == true ]]; then
  information "Waiting for creation of the Build Cluster"

  az aks wait --name $BUILD_CLUSTER_NAME --resource-group $RESOURCE_GROUP --created --interval 5
else
  information "Build Cluster already exists"
fi

declare -a run_clusters=($(yq e -o=j -I=0 '.clusters.run_clusters[]' $PARAMS_YAML))

for ((i=0;i<${#run_clusters[@]};i++));
do
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)
  
  if [[ ${CREATING_RUN_CLUSTERS[$i]} == true ]]; then
    information "Waiting for creation of the Run Cluster '$RUN_CLUSTER_NAME'"

    az aks wait --name $RUN_CLUSTER_NAME --resource-group $RESOURCE_GROUP --created --interval 5
  else
    information "Run Cluster '$RUN_CLUSTER_NAME' already exists"
  fi
done

information "Getting kubeconfigs and extracting cluster endpoints"

az aks get-credentials --name $VIEW_CLUSTER_NAME --resource-group $RESOURCE_GROUP --overwrite-existing --file $VIEW_CLUSTER_KUBECONFIG

export VIEW_CLUSTER_URL=$(kubectl --kubeconfig $VIEW_CLUSTER_KUBECONFIG config view | yq '.clusters[0].cluster.server')
yq e -i '.clusters.view_cluster.k8s_info.url = env(VIEW_CLUSTER_URL)' "$PARAMS_YAML"

az aks get-credentials --name $ITERATE_CLUSTER_NAME --resource-group $RESOURCE_GROUP --overwrite-existing --file $ITERATE_CLUSTER_KUBECONFIG

export ITERATE_CLUSTER_URL=$(kubectl --kubeconfig $ITERATE_CLUSTER_KUBECONFIG config view | yq '.clusters[0].cluster.server')
yq e -i '.clusters.iterate_cluster.k8s_info.url = env(ITERATE_CLUSTER_URL)' "$PARAMS_YAML"

az aks get-credentials --name $BUILD_CLUSTER_NAME --resource-group $RESOURCE_GROUP --overwrite-existing --file $BUILD_CLUSTER_KUBECONFIG

export BUILD_CLUSTER_URL=$(kubectl --kubeconfig $BUILD_CLUSTER_KUBECONFIG config view | yq '.clusters[0].cluster.server')
yq e -i '.clusters.build_cluster.k8s_info.url = env(BUILD_CLUSTER_URL)' "$PARAMS_YAML"

for ((i=0;i<${#run_clusters[@]};i++));
do
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)
  RUN_CLUSTER_KUBECONFIG="$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)"

  az aks get-credentials --name $RUN_CLUSTER_NAME --resource-group $RESOURCE_GROUP --overwrite-existing --file $RUN_CLUSTER_KUBECONFIG

  export RUN_CLUSTER_URL=$(kubectl --kubeconfig $RUN_CLUSTER_KUBECONFIG config view | yq '.clusters[0].cluster.server')
  yq e -i ".clusters.run_clusters[$i].k8s_info.url = env(RUN_CLUSTER_URL)" "$PARAMS_YAML"
done
