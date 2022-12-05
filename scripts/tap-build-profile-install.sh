#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

TAP_VERSION=$(yq e .tap.version tap-version.yaml)
BUILD_CLUSTER_NAME=$(yq e .clusters.build_cluster.k8s_info.name $PARAMS_YAML)
BUILD_CLUSTER_KUBECONFIG=$(yq e .clusters.build_cluster.k8s_info.kubeconfig $PARAMS_YAML)
BUILD_PROFILE="generated/profile-templates/$BUILD_CLUSTER_NAME.yaml"

information "Generating build profile"

mkdir -p generated/profile-templates
ytt -f "$PARAMS_YAML" -f profile-templates/build.yaml > $BUILD_PROFILE

information "Add metadata store creds on the Build Cluster"

CA_CERT=$(kubectl get secret -n metadata-store ingress-cert -o yaml --kubeconfig $VIEW_CLUSTER_KUBECONFIG | yq -r '.data."ca.crt"')
METADATA_STORE_AUTH_TOKEN=$(kubectl get secrets metadata-store-read-write-client -n metadata-store -o yaml --kubeconfig $VIEW_CLUSTER_KUBECONFIG | yq ".data.token" | base64 -d)

kubectl create ns metadata-store-secrets --dry-run=client -o yaml | kubectl --kubeconfig $BUILD_CLUSTER_KUBECONFIG apply -f -
ytt -v ca_crt=$CA_CERT -f tap-declarative-yaml/metadata-store-ca.yaml | kubectl --kubeconfig $BUILD_CLUSTER_KUBECONFIG apply -f -
kubectl create secret generic store-auth-token --from-literal=auth_token=$METADATA_STORE_AUTH_TOKEN -n metadata-store-secrets --dry-run=client -o yaml | kubectl --kubeconfig $BUILD_CLUSTER_KUBECONFIG apply -f -
kubectl apply -f tap-declarative-yaml/metadata-store-secrets-export.yaml --kubeconfig $BUILD_CLUSTER_KUBECONFIG

information "Installing build profile"

tanzu package install tap \
  -n tap-install \
  -p tap.tanzu.vmware.com \
  -v $TAP_VERSION \
  -f $BUILD_PROFILE \
  --kubeconfig $BUILD_CLUSTER_KUBECONFIG \
  --wait=false
