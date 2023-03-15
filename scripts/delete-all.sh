#!/bin/bash
set -e -o pipefail

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

RESOURCE_GROUP=$(yq e .azure.resource_group $PARAMS_YAML)

if [[ "$(az group exists --name $RESOURCE_GROUP)" == 'false' ]]; then
  information "Resource group '$RESOURCE_GROUP' does not exist"
else
  information "Deleting resource group $RESOURCE_GROUP"

  az group delete --resource-group $RESOURCE_GROUP
fi

information "Deleting folder 'generated'"
rm -rf generated