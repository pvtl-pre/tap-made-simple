#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

RESOURCE_GROUP=$(yq e .azure.resource_group $PARAMS_YAML)
CLUSTER_NAME=$(yq e .azure.aks_cluster_name $PARAMS_YAML)
export KUBECONFIG="generated/kubeconfig.yaml"
export SSH_KEY_PATH="generated/azure-ssh"

CLUSTER_EXISTS=$(az aks list | jq ".[] | contains({name: \"$CLUSTER_NAME\"})")

if [[ -z "${CLUSTER_EXISTS}" || "${CLUSTER_EXISTS}" == 'false' ]]; then
  if [ -f "$SSH_KEY_PATH" ]; then
    echo "INFO: skipping ssh key generation"
  else
    mkdir -p generated

    echo "INFO: generating ssh key at $SSH_KEY_PATH"
    ssh-keygen -t rsa -b 4096 -f "$SSH_KEY_PATH" -q -N ""

    yq e -i '.azure.ssh_key_path = env(SSH_KEY_PATH)' "$PARAMS_YAML"
  fi
  
  echo "## Creating AKS cluster '$CLUSTER_NAME'"
  az aks create --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --node-vm-size standard_a8_v2 --node-count 4 --ssh-key-value $SSH_KEY_PATH.pub --yes
else
  echo "## AKS cluster '$CLUSTER_NAME' exists"
fi

echo "## Getting kubeconfig credentials"
az aks get-credentials --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --overwrite-existing --file $KUBECONFIG

yq e -i '.azure.kubeconfig = env(KUBECONFIG)' "$PARAMS_YAML"
