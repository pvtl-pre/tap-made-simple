#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

TAP_VERSION_YAML="tap-version.yaml"
TAP_VERSION=$(yq e .tap.version $TAP_VERSION_YAML)

information "Downloading 'tanzu-gitops-ri' from Tanzu Network"

RI_PRODUCT_FILE='tanzu-gitops-ri-*.tgz'
RI_PRODUCT_FILE_ID=$(yq e .gitops_reference_implementation.tanzu_net.product_file_id $TAP_VERSION_YAML)

rm -f generated/$RI_PRODUCT_FILE

pivnet download-product-files \
  --product-slug='tanzu-application-platform' \
  --release-version=$TAP_VERSION \
  --product-file-id=$RI_PRODUCT_FILE_ID \
  --download-dir generated
