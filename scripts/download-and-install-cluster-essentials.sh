#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

JUMPBOX_OS=$(yq e .jumpbox_os $PARAMS_YAML)

TAP_VERSION_YAML="tap-version.yaml"
CLUSTER_ESSENTIALS_VERSION=$(yq e .cluster_essentials.version $TAP_VERSION_YAML)
RUN_CLUSTER_COUNT=$(yq e '.clusters.run_clusters | length' $PARAMS_YAML)

information "Downloading and extracting 'tanzu-cluster-essentials' from Tanzu Network"

if [[ $JUMPBOX_OS == 'MacOS' ]]; then
  CLUSTER_ESSENTIALS_PRODUCT_FILE="tanzu-cluster-essentials-darwin-amd64-$CLUSTER_ESSENTIALS_VERSION.tgz"
  CLUSTER_ESSENTIALS_PRODUCT_FILE_ID=$(yq e .cluster_essentials.tanzu_net.macos_product_file_id $TAP_VERSION_YAML)
else
  CLUSTER_ESSENTIALS_PRODUCT_FILE="tanzu-cluster-essentials-linux-amd64-$CLUSTER_ESSENTIALS_VERSION.tgz"
  CLUSTER_ESSENTIALS_PRODUCT_FILE_ID=$(yq e .cluster_essentials.tanzu_net.linux_product_file_id $TAP_VERSION_YAML)
fi

rm -f generated/$CLUSTER_ESSENTIALS_PRODUCT_FILE
rm -rf generated/tanzu-cluster-essentials
mkdir -p generated/tanzu-cluster-essentials

pivnet download-product-files --product-slug='tanzu-cluster-essentials' --release-version=$CLUSTER_ESSENTIALS_VERSION --product-file-id=$CLUSTER_ESSENTIALS_PRODUCT_FILE_ID --download-dir generated

tar -xvf generated/$CLUSTER_ESSENTIALS_PRODUCT_FILE -C generated/tanzu-cluster-essentials

(
  export INSTALL_BUNDLE=$(yq e .cluster_essentials.bundle $TAP_VERSION_YAML)
  export INSTALL_REGISTRY_HOSTNAME=$(yq e .tanzu_registry.hostname $PARAMS_YAML)
  export INSTALL_REGISTRY_USERNAME=$(yq e .tanzu_registry.username $PARAMS_YAML)
  export INSTALL_REGISTRY_PASSWORD=$(yq e .tanzu_registry.password $PARAMS_YAML)

  BUILD_CLUSTER_KUBECONFIG=$(yq e .clusters.build_cluster.kubeconfig $PARAMS_YAML)
  ITERATE_CLUSTER_KUBECONFIG=$(yq e .clusters.iterate_cluster.kubeconfig $PARAMS_YAML)
  VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.kubeconfig $PARAMS_YAML)

  cd generated/tanzu-cluster-essentials

  KUBECONFIG=../../$BUILD_CLUSTER_KUBECONFIG ./install.sh --yes

  KUBECONFIG=../../$ITERATE_CLUSTER_KUBECONFIG ./install.sh --yes

  KUBECONFIG=../../$VIEW_CLUSTER_KUBECONFIG ./install.sh --yes

  for ((i = 0; i < $RUN_CLUSTER_COUNT; i++)); do
    RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].kubeconfig ../../$PARAMS_YAML)

    KUBECONFIG=../../$RUN_CLUSTER_KUBECONFIG ./install.sh --yes
  done
)
