#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

GITOPS_REPO=$(yq e .gitops.repo_url $PARAMS_YAML)
GITOPS_REPO_DIR="generated/gitops-repo"
RI_PRODUCT_FILE='tanzu-gitops-ri-*.tgz'

information "Cloning GitOps Repo"

rm -rf $GITOPS_REPO_DIR
git clone $GITOPS_REPO $GITOPS_REPO_DIR

information "Extracting 'tanzu-gitops-ri'"

tar -xvf generated/$RI_PRODUCT_FILE -C $GITOPS_REPO_DIR

if [[ -n "$(yq e ".gitops.initial_commit_hash" $PARAMS_YAML)" ]]; then
  information "Skipping initial commit hash retrieval since it is already set"
else
  information "Getting the initial commit hash of the GitOps Repo"

  export HASH=$(cd $GITOPS_REPO_DIR; git rev-parse HEAD)
  yq e -i ".gitops.initial_commit_hash = env(HASH)" $PARAMS_YAML
fi

information "Initializing GitOps Repo"

$SCRIPTS/commit-gitops-repo.sh "Initialize Tanzu GitOps RI"
