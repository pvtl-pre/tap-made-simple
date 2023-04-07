#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

BUILD_CLUSTER_KUBECONFIG=$(yq e .clusters.build_cluster.k8s_info.kubeconfig $PARAMS_YAML)
BUILD_CLUSTER_NAME=$(yq e .clusters.build_cluster.k8s_info.name $PARAMS_YAML)
ITERATE_CLUSTER_KUBECONFIG=$(yq e .clusters.iterate_cluster.k8s_info.kubeconfig $PARAMS_YAML)
ITERATE_CLUSTER_NAME=$(yq e .clusters.iterate_cluster.k8s_info.name $PARAMS_YAML)
RUN_CLUSTER_COUNT=$(yq e '.clusters.run_clusters | length' $PARAMS_YAML)
VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.k8s_info.kubeconfig $PARAMS_YAML)
VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.k8s_info.name $PARAMS_YAML)

TAP_VERSION_YAML="tap-version.yaml"
TAP_VERSION=$(yq e .tap.version $TAP_VERSION_YAML)

INSTALL_REGISTRY_HOSTNAME=$(yq e .tanzu_registry.hostname $PARAMS_YAML)
INSTALL_REGISTRY_USERNAME=$(yq e .tanzu_registry.username $PARAMS_YAML)
INSTALL_REGISTRY_PASSWORD=$(yq e .tanzu_registry.password $PARAMS_YAML)

function add_package_repo() {
  CLUSTER_NAME=$1
  KUBECONFIG=$2

  information "Installing TAP package repository on cluster '$CLUSTER_NAME'"

  information "Creating tap-install and tap-gui namespaces on cluster '$CLUSTER_NAME'"

  kubectl create ns tap-install --dry-run=client -o yaml | kubectl --kubeconfig $KUBECONFIG apply -f -
  kubectl create ns tap-gui --dry-run=client -o yaml | kubectl --kubeconfig $KUBECONFIG apply -f -

  information "Adding image registry secret on cluster '$CLUSTER_NAME'"

  tanzu secret registry add tap-registry \
    --username $INSTALL_REGISTRY_USERNAME \
    --password $INSTALL_REGISTRY_PASSWORD \
    --server $INSTALL_REGISTRY_HOSTNAME \
    --export-to-all-namespaces \
    --yes \
    --namespace tap-install \
    --kubeconfig $KUBECONFIG

  information "Adding the TAP package repository on cluster '$CLUSTER_NAME'"

  tanzu package repository add tanzu-tap-repository \
    --url $INSTALL_REGISTRY_HOSTNAME/tanzu-application-platform/tap-packages:$TAP_VERSION \
    --namespace tap-install \
    --wait=false \
    --kubeconfig $KUBECONFIG
}

function reconcile() {
  CLUSTER_NAME=$1
  KUBECONFIG=$2

  information "Waiting for TAP package repository on cluster '$CLUSTER_NAME'"

  kubectl wait pkgr --for condition=ReconcileSucceeded=True \
    -n tap-install tanzu-tap-repository \
    --kubeconfig $KUBECONFIG \
    --timeout=5m
}

add_package_repo $VIEW_CLUSTER_NAME $VIEW_CLUSTER_KUBECONFIG
add_package_repo $ITERATE_CLUSTER_NAME $ITERATE_CLUSTER_KUBECONFIG
add_package_repo $BUILD_CLUSTER_NAME $BUILD_CLUSTER_KUBECONFIG

for ((i = 0; i < $RUN_CLUSTER_COUNT; i++)); do
  RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)

  add_package_repo $RUN_CLUSTER_NAME $RUN_CLUSTER_KUBECONFIG
done

reconcile $VIEW_CLUSTER_NAME $VIEW_CLUSTER_KUBECONFIG
reconcile $ITERATE_CLUSTER_NAME $ITERATE_CLUSTER_KUBECONFIG
reconcile $BUILD_CLUSTER_NAME $BUILD_CLUSTER_KUBECONFIG

for ((i = 0; i < $RUN_CLUSTER_COUNT; i++)); do
  RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)

  reconcile $RUN_CLUSTER_NAME $RUN_CLUSTER_KUBECONFIG
done
