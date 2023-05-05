#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

BUILD_CLUSTER_KUBECONFIG=$(yq e .clusters.build_cluster.kubeconfig $PARAMS_YAML)
VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.name $PARAMS_YAML)
VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.kubeconfig $PARAMS_YAML)

VIEW_PROFILE="generated/profiles/$VIEW_CLUSTER_NAME.yaml"

information "Getting metadata store service account and ingress secrets"

export METADATA_STORE_ACCESS_TOKEN=$(kubectl get secrets metadata-store-read-write-client -n metadata-store -o jsonpath="{.data.token}" --kubeconfig $VIEW_CLUSTER_KUBECONFIG | base64 -d)
CA_CERT=$(kubectl get secret -n metadata-store ingress-cert -o yaml --kubeconfig $VIEW_CLUSTER_KUBECONFIG | yq -r '.data."ca.crt"')

yq e -i '.clusters.view_cluster.metadata_store.auth = "Bearer " + env(METADATA_STORE_ACCESS_TOKEN) + ""' "$PARAMS_YAML"

information "Updating generated view profile with TAP GUI metadata store auth configuration"

ytt -f "$PARAMS_YAML" -f $VIEW_PROFILE -f profile-overlays/tap-gui-metadata-store-auth.yaml --output-files generated/profiles

$SCRIPTS/apply-view-profile.sh

$SCRIPTS/reconcile-view-cluster.sh

information "Adding metadata store auth on the Build Cluster"

kubectl create ns metadata-store-secrets --dry-run=client -o yaml | kubectl --kubeconfig $BUILD_CLUSTER_KUBECONFIG apply -f -
ytt -v ca_crt=$CA_CERT -f tap-declarative-yaml/metadata-store-ca.yaml | kubectl --kubeconfig $BUILD_CLUSTER_KUBECONFIG apply -f -
kubectl create secret generic store-auth-token --from-literal=auth_token=$METADATA_STORE_ACCESS_TOKEN -n metadata-store-secrets --dry-run=client -o yaml | kubectl --kubeconfig $BUILD_CLUSTER_KUBECONFIG apply -f -
kubectl apply -f tap-declarative-yaml/metadata-store-secrets-export.yaml --kubeconfig $BUILD_CLUSTER_KUBECONFIG
