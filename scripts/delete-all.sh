#!/bin/bash
set -e -o pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source $SCRIPTS/set-env.sh

GITOPS_HASH=$(yq e .gitops.initial_commit_hash $PARAMS_YAML)
GITOPS_REPO_DIR="gitops-repo"
RESOURCE_GROUP=$(yq e .azure.resource_group $PARAMS_YAML)

if [[ -d "generated/$GITOPS_REPO_DIR" ]]; then
  information "Reverting gitops repo to initial commit"

  (
    cd generated/$GITOPS_REPO_DIR

    git reset --hard $GITOPS_HASH
    git push --force
  )
fi

if [[ "$(az group exists --name $RESOURCE_GROUP)" == 'false' ]]; then
  information "Resource group '$RESOURCE_GROUP' does not exist"
else
  information "Deleting resource group $RESOURCE_GROUP"

  az group delete --resource-group $RESOURCE_GROUP
fi

information "Deleting folder 'generated'"

rm -rf generated
