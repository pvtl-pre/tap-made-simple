#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

RESOURCE_GROUP=$(yq e .azure.resource_group $PARAMS_YAML)

CLUSTER_EXISTS=$(az aks list | jq "any(.name == \"$CLUSTER_NAME\")")

if [[ -z "${CLUSTER_EXISTS}" || "${CLUSTER_EXISTS}" == 'false' || "${CLUSTER_EXISTS}" == false ]]; then
  information "Creating AKS cluster $CLUSTER_NAME"
  az aks create --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --node-vm-size standard_a8_v2 --node-count 4 --ssh-key-value $SSH_KEY_PATH.pub --yes
else
  information "AKS cluster $CLUSTER_NAME exists"
fi

information "Getting kubeconfig credentials for cluster $CLUSTER_NAME"
az aks get-credentials --name $CLUSTER_NAME --resource-group $RESOURCE_GROUP --overwrite-existing --file $KUBECONFIG
