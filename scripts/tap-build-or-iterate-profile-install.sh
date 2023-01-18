#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

TAP_VERSION=$(yq e .tap.version tap-version.yaml)
CLUSTER_NAME=$(yq e .clusters.$CLUSTER_TYPE\_cluster.k8s_info.name $PARAMS_YAML)
KUBECONFIG=$(yq e .clusters.$CLUSTER_TYPE\_cluster.k8s_info.kubeconfig $PARAMS_YAML)
PROFILE="generated/profile-templates/$CLUSTER_NAME.yaml"

information "Generating $CLUSTER_TYPE profile"

mkdir -p generated/profile-templates
ytt -f "$PARAMS_YAML" -f profile-templates/$CLUSTER_TYPE.yaml > $PROFILE

information "Getting metadata store creds from the View Cluster"

CA_CERT=$(kubectl get secret -n metadata-store ingress-cert -o yaml --kubeconfig $VIEW_CLUSTER_KUBECONFIG | yq -r '.data."ca.crt"')
METADATA_STORE_AUTH_TOKEN=$(kubectl get secrets metadata-store-read-write-client -n metadata-store -o yaml --kubeconfig $VIEW_CLUSTER_KUBECONFIG | yq ".data.token" | base64 -d)

information "Adding metadata store creds on Build/Iterate Cluster '$CLUSTER_NAME'"

kubectl create ns metadata-store-secrets --dry-run=client -o yaml | kubectl --kubeconfig $KUBECONFIG apply -f -
ytt -v ca_crt=$CA_CERT -f tap-declarative-yaml/metadata-store-ca.yaml | kubectl --kubeconfig $KUBECONFIG apply -f -
kubectl create secret generic store-auth-token --from-literal=auth_token=$METADATA_STORE_AUTH_TOKEN -n metadata-store-secrets --dry-run=client -o yaml | kubectl --kubeconfig $KUBECONFIG apply -f -
kubectl apply -f tap-declarative-yaml/metadata-store-secrets-export.yaml --kubeconfig $KUBECONFIG

information "Installing $CLUSTER_TYPE profile"

tanzu package install tap \
  -n tap-install \
  -p tap.tanzu.vmware.com \
  -v $TAP_VERSION \
  -f $PROFILE \
  --kubeconfig $KUBECONFIG \
  --wait=false
