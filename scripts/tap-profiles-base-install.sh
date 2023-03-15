#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

INSTALL_REGISTRY_HOSTNAME=$(yq e .tanzu_registry.hostname $PARAMS_YAML)
INSTALL_REGISTRY_USERNAME=$(yq e .tanzu_registry.username $PARAMS_YAML)
INSTALL_REGISTRY_PASSWORD=$(yq e .tanzu_registry.password $PARAMS_YAML)

TAP_VERSION_YAML="tap-version.yaml"
TAP_VERSION=$(yq e .tap.version $TAP_VERSION_YAML)

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

if [[ $IS_BUILD_OR_RUN_CLUSTER == true ]]; then
  information "Adding TAP GUI multi-cluster RBAC on cluster '$CLUSTER_NAME'"

  KUBE_VERSION=$(kubectl version -o yaml --kubeconfig $KUBECONFIG | yq e '.serverVersion.minor')

  kubectl apply -f tap-declarative-yaml/tap-gui-viewer-service-account-rbac.yaml --kubeconfig $KUBECONFIG

  if [[ $KUBE_VERSION -ge "24" ]]; then
    kubectl apply -f tap-declarative-yaml/tap-gui-viewer-service-account-secret.yaml --kubeconfig $KUBECONFIG
    TAP_GUI_VIEWER_SECRET="tap-gui-viewer"
  else
    TAP_GUI_VIEWER_SECRET=$(kubectl -n tap-gui get sa tap-gui-viewer -o yaml --kubeconfig $KUBECONFIG | yq -r '.secrets[0].name')
  fi

  information "Getting service account token on cluster '$CLUSTER_NAME'"

  export SA_TOKEN=$(kubectl -n tap-gui get secret $TAP_GUI_VIEWER_SECRET -o yaml --kubeconfig $KUBECONFIG | yq -r '.data["token"]' | base64 --decode)

  yq e -i "$SA_TOKEN_PATH = env(SA_TOKEN)" "$PARAMS_YAML"
fi

information "Waiting for TAP package repository on cluster '$CLUSTER_NAME'"

kubectl wait pkgr --for condition=ReconcileSucceeded=True \
  -n tap-install tanzu-tap-repository \
  --kubeconfig $KUBECONFIG \
  --timeout=5m
