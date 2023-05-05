#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

ACR_SKU=$(yq e .azure.acr.sku $PARAMS_YAML)
CREATE_ACR=false
RESOURCE_GROUP=$(yq e .azure.resource_group $PARAMS_YAML)

export ACR_NAME=$(yq e .azure.acr.name $PARAMS_YAML)

if [[ -z "$ACR_NAME" || "$ACR_NAME" == "null" ]]; then
  ACR_NAME=tapregistry$(date +%Y%m%d%H%M%S)

  CREATE_ACR=true
else
  ACR_EXISTS=$(az acr list -g $RESOURCE_GROUP -o json | jq "any(.name == \"$ACR_NAME\")")

  if [[ $ACR_EXISTS == false ]]; then
    CREATE_ACR=true
  fi
fi

if [[ $CREATE_ACR == true ]]; then
  ACR_NAME_AVAILABLE=$(az acr check-name -n $ACR_NAME -o json | jq -r '.nameAvailable')

  if [[ $ACR_NAME_AVAILABLE == false ]]; then
    information "Azure Container Registry name $ACR_NAME is not available"

    exit 1
  fi

  information "Creating Azure Container Registry named $ACR_NAME"

  az acr create -n $ACR_NAME -g $RESOURCE_GROUP --sku $ACR_SKU
  yq e -i '.azure.acr.name = env(ACR_NAME)' "$PARAMS_YAML"
else
  information "Azure Container Registry named $ACR_NAME already exists"
fi

information "Getting Azure Container Registry creds"

ACR_ADMIN_ENABLED=$(az acr show -n $ACR_NAME -g $RESOURCE_GROUP -o json | jq '.adminUserEnabled')

if [[ $ACR_ADMIN_ENABLED == false ]]; then
  information "Enabling admin on registry $ACR_NAME"

  az acr update -n $ACR_NAME -g $RESOURCE_GROUP --admin-enabled true
fi

RETURNED_ACR_CREDS_JSON=$(az acr credential show -n $ACR_NAME -g $RESOURCE_GROUP -o json)

export REGISTRY_FQDN="$ACR_NAME.azurecr.io"
export REGISTRY_USERNAME=$(jq -r '.username' <<<$RETURNED_ACR_CREDS_JSON)
export REGISTRY_PASSWORD=$(jq -r '.passwords[0].value' <<<$RETURNED_ACR_CREDS_JSON)

yq e -i '.registry.fqdn = env(REGISTRY_FQDN)' "$PARAMS_YAML"
yq e -i '.registry.username = env(REGISTRY_USERNAME)' "$PARAMS_YAML"
yq e -i '.registry.password = env(REGISTRY_PASSWORD)' "$PARAMS_YAML"
