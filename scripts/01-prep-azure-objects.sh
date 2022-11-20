#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

# Ensure az is configured and working
if ! az account show > /dev/null; then
  information "ERROR: could not run az account show, please configure az"
  exit 1
fi

RESOURCE_GROUP=$(yq e .azure.resource_group $PARAMS_YAML)
LOCATION=$(yq e .azure.location $PARAMS_YAML)

if [[ "$(az group exists --name $RESOURCE_GROUP -o json)" == false ]]; then
  information "Creating resource group '$RESOURCE_GROUP' in location '$LOCATION'"
  az group create --name $RESOURCE_GROUP --location $LOCATION
else
  information "Resource group '$RESOURCE_GROUP' exists"
fi
