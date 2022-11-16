#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

TAP_VERSION=$(yq e .tap_version $PARAMS_YAML)
JUMPBOX_OS=$(yq e .jumpbox-os $PARAMS_YAML)

information "Downloading and extracting 'tanzu-cluster-essentials' from Tanzu Network"

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
  export INSTALL_BUNDLE=$(yq e .tanzu_registry.bundle $PARAMS_YAML)
  export INSTALL_REGISTRY_HOSTNAME=$(yq e .tanzu_registry.hostname $PARAMS_YAML)
  export INSTALL_REGISTRY_USERNAME=$(yq e .tanzu_registry.username $PARAMS_YAML)
  export INSTALL_REGISTRY_PASSWORD=$(yq e .tanzu_registry.password $PARAMS_YAML)

  VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.k8s_info.kubeconfig $PARAMS_YAML)
  BUILD_CLUSTER_KUBECONFIG=$(yq e .clusters.build_cluster.k8s_info.kubeconfig $PARAMS_YAML)

  RUN_CLUSTERS_INSTALL_COMMAND=""

  declare -a run_clusters=($(yq e -o=j -I=0 '.clusters.run_clusters[]' $PARAMS_YAML))

  for ((i=0;i<${#run_clusters[@]};i++)); 
  do
    RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)  

    current_cluster_command="KUBECONFIG=../../$RUN_CLUSTER_KUBECONFIG ./install.sh --yes"

    if [[ "$i" -eq "0" ]]; then
      RUN_CLUSTERS_INSTALL_COMMAND="$current_cluster_command"
    else
      RUN_CLUSTERS_INSTALL_COMMAND="$RUN_CLUSTERS_INSTALL_COMMAND & $current_cluster_command"
    fi
  done

  cd generated/tanzu-cluster-essentials

  KUBECONFIG=../../$VIEW_CLUSTER_KUBECONFIG ./install.sh --yes \
  & \
  KUBECONFIG=../../$BUILD_CLUSTER_KUBECONFIG ./install.sh --yes \
  & \
  eval $RUN_CLUSTERS_INSTALL_COMMAND

  wait
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
