#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

TAP_VERSION_YAML="tap-version.yaml"
TAP_VERSION=$(yq e .tap.version $TAP_VERSION_YAML)

GITOPS_REPO=$(yq e .gitops.repo $PARAMS_YAML)
GITOPS_REPO_DIR="gitops-repo"

information "Cloning gitops repo"

rm -rf generated/$GITOPS_REPO_DIR
git clone $GITOPS_REPO generated/$GITOPS_REPO_DIR

information "Downloading and extracting 'tanzu-gitops-ri' from Tanzu Network"

RI_PRODUCT_FILE='tanzu-gitops-ri-*.tgz'
RI_PRODUCT_FILE_ID=$(yq e .gitops_reference_implementation.tanzu_net.product_file_id $TAP_VERSION_YAML)

rm -f generated/$RI_PRODUCT_FILE

pivnet download-product-files \
  --product-slug='tanzu-application-platform' \
  --release-version=$TAP_VERSION \
  --product-file-id=$RI_PRODUCT_FILE_ID \
  --download-dir generated

tar -xvf generated/$RI_PRODUCT_FILE -C generated/$GITOPS_REPO_DIR

(
  cd generated/$GITOPS_REPO_DIR

  if [[ -n "$(yq e ".gitops.initial_commit_hash" ../../$PARAMS_YAML)" ]]; then
    information "Skipping initial commit hash retrieval since it is already set"
  else
    information "Getting the initial commit hash of the gitops repo"

    export HASH=$(git rev-parse HEAD)
    yq e -i ".gitops.initial_commit_hash = env(HASH)" ../../$PARAMS_YAML
  fi

  information "Committing gitops repo"

  git add .
  git status
  git commit -m "Initialize Tanzu GitOps RI"
  git push
)
