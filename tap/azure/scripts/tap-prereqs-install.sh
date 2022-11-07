#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TAP_VERSION=$(yq e .tap_version $PARAMS_YAML)
JUMPBOX_OS=$(yq e .jumpbox-os $PARAMS_YAML)
CLUSTER_NAME=$(yq e .azure.aks_cluster_name $PARAMS_YAML)
KUBECONFIG=$(yq e .azure.kubeconfig $PARAMS_YAML)

echo "## Downloading and extracting 'tanzu-cluster-essentials' from Tanzu Network"

if [[ "$JUMPBOX_OS" == 'OSX' ]]; then
  CLUSTER_ESSENTIALS_FILE="tanzu-cluster-essentials-darwin-amd64-$TAP_VERSION.tgz"
  CLUSTER_ESSENTIALS_PRODUCT_FILE_ID=1330472

  TAP_FILE='tanzu-framework-darwin-amd64.tar'
  TAP_FILE_PRODUCT_FILE_ID=1310083

  TANZU_CLI='tanzu-core-darwin_amd64'
else
  CLUSTER_ESSENTIALS_FILE="tanzu-cluster-essentials-linux-amd64-$TAP_VERSION.tgz"
  CLUSTER_ESSENTIALS_PRODUCT_FILE_ID=1330470

  TAP_FILE='tanzu-framework-linux-amd64.tar'
  TAP_FILE_PRODUCT_FILE_ID=1310085

  TANZU_CLI='tanzu-core-linux_amd64'
fi

rm -rf generated/tanzu-cluster-essentials
mkdir -p generated/tanzu-cluster-essentials

if [[ ! -f "generated/$CLUSTER_ESSENTIALS_FILE" ]]; then
  pivnet download-product-files --product-slug='tanzu-cluster-essentials' --release-version=$TAP_VERSION --product-file-id=$CLUSTER_ESSENTIALS_PRODUCT_FILE_ID --download-dir generated
fi

tar -xvf generated/$CLUSTER_ESSENTIALS_FILE -C generated/tanzu-cluster-essentials

(
cd generated/tanzu-cluster-essentials
KUBECONFIG=../../$KUBECONFIG ./install.sh --yes
)

echo "## Downloading and extracting 'tanzu-framework-bundle' from Tanzu Network"

rm -rf generated/tanzu
mkdir -p generated/tanzu

if [[ ! -f "generated/$TAP_FILE" ]]; then
  pivnet download-product-files --product-slug='tanzu-application-platform' --release-version=$TAP_VERSION --product-file-id=$TAP_FILE_PRODUCT_FILE_ID --download-dir generated
fi

tar -xvf generated/$TAP_FILE -C generated/tanzu


echo "## Installing Tanzu CLI"

export TANZU_CLI_NO_INIT=true
sudo install generated/tanzu/cli/core/v*/$TANZU_CLI /usr/local/bin/tanzu

tanzu version

echo "## Installing Tanzu CLI plug-ins"

tanzu plugin install --local generated/tanzu/cli all

tanzu plugin list