#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

export ACR_NAME=$(yq e .azure.acr_name $PARAMS_YAML)

RESOURCE_GROUP=$(yq e .azure.resource_group $PARAMS_YAML)
ACR_SKU=$(yq e .azure.acr_sku $PARAMS_YAML)
CREATE_ACR=false

if [[ -z "$ACR_NAME" || "$ACR_NAME" == "null" ]]; then
  export ACR_NAME=tapregistry$(date +%Y%m%d%H%M%S)

  CREATE_ACR=true
else
  ACR_EXISTS=$(az acr list -o json | jq ".[] | contains({name: \"$ACR_NAME\"})")

  if [[ -z "$ACR_EXISTS" || "$ACR_EXISTS" == 'false' ]]; then
    CREATE_ACR=true
  fi
fi

if [[ "$CREATE_ACR" == 'true' ]]; then
  RETURNED_ACR_JSON=$(az acr check-name --name $ACR_NAME -o json)

  if [[ $(echo "$RETURNED_ACR_JSON" | jq -r '.nameAvailable') != "true" ]]; then
    echo "Azure Container Registry name $ACR_NAME is not available"
    exit 1
  fi

  echo "## Creating Azure Container Registry named $ACR_NAME"
  az acr create --name $ACR_NAME --resource-group $RESOURCE_GROUP --sku $ACR_SKU
  yq e -i '.azure.acr_name = env(ACR_NAME) + ".azurecr.io"' "$PARAMS_YAML"

  export ACR_TBS_REPO="$ACR_NAME/tap/build-service"

  echo "## Build service repo path will be $ACR_TBS_REPO"

  yq e -i '.tap_values.buildservice.kp_default_repository = env(ACR_TBS_REPO)' "$PARAMS_YAML"

  export ACR_SUPPLY_CHAIN_REPO="$ACR_NAME/tap/supply-chain"

  echo "## Supply chain server will be $ACR_SUPPLY_CHAIN_REPO"

  yq e -i '.tap_values.shared.image_registry.project_path = env(ACR_SUPPLY_CHAIN_REPO)' "$PARAMS_YAML"
else
  echo "## Azure Container Registry named $ACR_NAME already exists"
fi

echo "## Getting Azure Container Registry creds"

ACR_ADMIN_ENABLED=$(az acr show -n $ACR_NAME -o yaml | yq e .adminUserEnabled)

if [[ "$ACR_ADMIN_ENABLED" == "false" ]]; then
  echo "## Enabling admin on registry $ACR_NAME"
  az acr update -n $ACR_NAME --admin-enabled true
fi

RETURNED_ACR_CREDS_JSON=$(az acr credential show --name $ACR_NAME -o json)

export ACR_USERNAME=$(echo "$RETURNED_ACR_CREDS_JSON" | jq -r '.username')
export ACR_PASSWORD=$(echo "$RETURNED_ACR_CREDS_JSON" | jq -r '.passwords[0].value')

yq e -i '.azure.acr_username = env(ACR_USERNAME)' "$PARAMS_YAML"
yq e -i '.azure.acr_password = env(ACR_PASSWORD)' "$PARAMS_YAML"

yq e -i '.tap_values.shared.image_registry.username = env(ACR_USERNAME)' "$PARAMS_YAML"
yq e -i '.tap_values.shared.image_registry.password = env(ACR_PASSWORD)' "$PARAMS_YAML"

yq e -i '.tap_values.buildservice.kp_default_repository_username = env(ACR_USERNAME)' "$PARAMS_YAML"
yq e -i '.tap_values.buildservice.kp_default_repository_password = env(ACR_PASSWORD)' "$PARAMS_YAML"
