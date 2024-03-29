#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

JUMPBOX_OS=$(yq e .jumpbox_os $PARAMS_YAML)

TAP_VERSION_YAML="tap-version.yaml"
TAP_VERSION=$(yq e .tap.version $TAP_VERSION_YAML)

information "Downloading and extracting 'tanzu-framework' from Tanzu Network"

if [[ $JUMPBOX_OS == 'MacOS' ]]; then
  TANZU_CLI_PRODUCT_FILE='tanzu-framework-darwin-amd64-*.tar'
  TANZU_CLI_PRODUCT_FILE_ID=$(yq e .tap.tanzu_cli.tanzu_net.macos_product_file_id $TAP_VERSION_YAML)

  TANZU_CLI='tanzu-core-darwin_amd64'
else
  TANZU_CLI_PRODUCT_FILE='tanzu-framework-linux-amd64-*.tar'
  TANZU_CLI_PRODUCT_FILE_ID=$(yq e .tap.tanzu_cli.tanzu_net.linux_product_file_id $TAP_VERSION_YAML)

  TANZU_CLI='tanzu-core-linux_amd64'
fi

rm -f generated/$TANZU_CLI_PRODUCT_FILE
rm -rf generated/tanzu
mkdir -p generated/tanzu

pivnet download-product-files \
  --product-slug='tanzu-application-platform' \
  --release-version=$TAP_VERSION \
  --product-file-id=$TANZU_CLI_PRODUCT_FILE_ID \
  --download-dir generated

tar -xvf generated/$TANZU_CLI_PRODUCT_FILE -C generated/tanzu

information "Installing Tanzu CLI"

export TANZU_CLI_NO_INIT=true
sudo install generated/tanzu/cli/core/v*/$TANZU_CLI /usr/local/bin/tanzu

tanzu version

information "Installing Tanzu CLI plug-ins"

tanzu plugin install --local generated/tanzu/cli all

tanzu plugin list
