#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

TAP_VERSION_YAML="tap-version.yaml"
CLUSTER_ESSENTIALS_VERSION=$(yq e .cluster_essentials.version $TAP_VERSION_YAML)
TAP_VERSION=$(yq e .tap.version $TAP_VERSION_YAML)
JUMPBOX_OS=$(yq e .jumpbox_os $PARAMS_YAML)

information "Downloading and extracting 'tanzu-cluster-essentials' from Tanzu Network"

if [[ "$JUMPBOX_OS" == 'OSX' ]]; then
  CLUSTER_ESSENTIALS_FILE="tanzu-cluster-essentials-darwin-amd64-$CLUSTER_ESSENTIALS_VERSION.tgz"
  CLUSTER_ESSENTIALS_PRODUCT_FILE_ID=$(yq e .cluster_essentials.tanzu_net.osx_product_file_id $TAP_VERSION_YAML)

  TAP_FILE='tanzu-framework-darwin-amd64-*.tar'
  TAP_FILE_PRODUCT_FILE_ID=$(yq e .tap.tanzu_net.osx_product_file_id $TAP_VERSION_YAML)

  TANZU_CLI='tanzu-core-darwin_amd64'
else
  CLUSTER_ESSENTIALS_FILE="tanzu-cluster-essentials-linux-amd64-$CLUSTER_ESSENTIALS_VERSION.tgz"
  CLUSTER_ESSENTIALS_PRODUCT_FILE_ID=$(yq e .cluster_essentials.tanzu_net.linux_product_file_id $TAP_VERSION_YAML)

  TAP_FILE='tanzu-framework-linux-amd64-*.tar'
  TAP_FILE_PRODUCT_FILE_ID=$(yq e .tap.tanzu_net.linux_product_file_id $TAP_VERSION_YAML)

  TANZU_CLI='tanzu-core-linux_amd64'
fi

rm -rf generated/tanzu-cluster-essentials
mkdir -p generated/tanzu-cluster-essentials

if [[ ! -f "generated/$CLUSTER_ESSENTIALS_FILE" ]]; then
  pivnet download-product-files --product-slug='tanzu-cluster-essentials' --release-version=$CLUSTER_ESSENTIALS_VERSION --product-file-id=$CLUSTER_ESSENTIALS_PRODUCT_FILE_ID --download-dir generated
fi

tar -xvf generated/$CLUSTER_ESSENTIALS_FILE -C generated/tanzu-cluster-essentials

(
  export INSTALL_BUNDLE=$(yq e .cluster_essentials.bundle $TAP_VERSION_YAML)
  export INSTALL_REGISTRY_HOSTNAME=$(yq e .tanzu_registry.hostname $PARAMS_YAML)
  export INSTALL_REGISTRY_USERNAME=$(yq e .tanzu_registry.username $PARAMS_YAML)
  export INSTALL_REGISTRY_PASSWORD=$(yq e .tanzu_registry.password $PARAMS_YAML)

  VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.k8s_info.kubeconfig $PARAMS_YAML)
  BUILD_CLUSTER_KUBECONFIG=$(yq e .clusters.build_cluster.k8s_info.kubeconfig $PARAMS_YAML)

  cd generated/tanzu-cluster-essentials

  KUBECONFIG=../../$VIEW_CLUSTER_KUBECONFIG ./install.sh --yes

  KUBECONFIG=../../$BUILD_CLUSTER_KUBECONFIG ./install.sh --yes

  declare -a run_clusters=($(yq e -o=j -I=0 '.clusters.run_clusters[]' ../../$PARAMS_YAML))

  for ((i=0;i<${#run_clusters[@]};i++));
  do
    RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig ../../$PARAMS_YAML)  

    KUBECONFIG=../../$RUN_CLUSTER_KUBECONFIG ./install.sh --yes
  done
)

information "Downloading and extracting 'tanzu-framework-bundle' from Tanzu Network"

rm -rf generated/tanzu
mkdir -p generated/tanzu

if [[ ! -f "generated/$TAP_FILE" ]]; then
  pivnet download-product-files --product-slug='tanzu-application-platform' --release-version=$TAP_VERSION --product-file-id=$TAP_FILE_PRODUCT_FILE_ID --download-dir generated
fi

tar -xvf generated/$TAP_FILE -C generated/tanzu

information "Installing Tanzu CLI"

export TANZU_CLI_NO_INIT=true
sudo install generated/tanzu/cli/core/v*/$TANZU_CLI /usr/local/bin/tanzu

tanzu version

information "Installing Tanzu CLI plug-ins"

tanzu plugin install --local generated/tanzu/cli all

tanzu plugin list
