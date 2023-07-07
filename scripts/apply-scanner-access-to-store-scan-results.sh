#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

BUILD_CLUSTER_KUBECONFIG=$(yq e .clusters.build_cluster.kubeconfig $PARAMS_YAML)
BUILD_CLUSTER_NAME=$(yq e .clusters.build_cluster.name $PARAMS_YAML)
VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.kubeconfig $PARAMS_YAML)

BUILD_PROFILE="generated/profiles/$BUILD_CLUSTER_NAME.yaml"

information "Getting metadata store access token and CA cert"

export METADATA_STORE_ACCESS_TOKEN=$(kubectl get secrets metadata-store-read-write-client -n metadata-store -o jsonpath="{.data.token}" --kubeconfig $VIEW_CLUSTER_KUBECONFIG | base64 -d)
CA_CERT=$(kubectl get secret -n metadata-store ingress-cert -o yaml --kubeconfig $VIEW_CLUSTER_KUBECONFIG | yq -r '.data."ca.crt"')

information "Adding metadata store auth on the Build Cluster"

kubectl create ns metadata-store-secrets --dry-run=client -o yaml | kubectl --kubeconfig $BUILD_CLUSTER_KUBECONFIG apply -f -
ytt -v ca_crt=$CA_CERT -f tap-declarative-yaml/metadata-store-ca.yaml | kubectl --kubeconfig $BUILD_CLUSTER_KUBECONFIG apply -f -
kubectl create secret generic store-auth-token --from-literal=auth_token=$METADATA_STORE_ACCESS_TOKEN -n metadata-store-secrets --dry-run=client -o yaml | kubectl --kubeconfig $BUILD_CLUSTER_KUBECONFIG apply -f -
kubectl apply -f tap-declarative-yaml/metadata-store-secrets-export.yaml --kubeconfig $BUILD_CLUSTER_KUBECONFIG

information "Updating generated build profile with scanner access to the metadata store configuration"

ytt -f "$PARAMS_YAML" -f $BUILD_PROFILE -f profile-overlays/scanner-metadata-store-auth.yaml --output-files generated/profiles

$SCRIPTS/apply-build-profile.sh

$SCRIPTS/reconcile-build-cluster.sh
