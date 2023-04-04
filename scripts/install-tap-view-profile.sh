#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

TKG_LAB_SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$TKG_LAB_SCRIPTS/set-env.sh"

VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.k8s_info.name $PARAMS_YAML)
VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.k8s_info.kubeconfig $PARAMS_YAML)
VIEW_PROFILE="generated/profiles/$VIEW_CLUSTER_NAME.yaml"

TAP_VERSION_YAML="tap-version.yaml"
TAP_VERSION=$(yq e .tap.version $TAP_VERSION_YAML)

information "Generating view profile"

mkdir -p generated/profiles
ytt -f "$PARAMS_YAML" -f profile-templates/view.yaml >$VIEW_PROFILE

information "Installing view profile"

tanzu package install tap \
  -n tap-install \
  -p tap.tanzu.vmware.com \
  -v $TAP_VERSION \
  -f $VIEW_PROFILE \
  --kubeconfig $VIEW_CLUSTER_KUBECONFIG \
  --wait=false

information "Waiting for the metadata-store-read-write-client secret to be created"

while ! kubectl get secrets metadata-store-read-write-client -n metadata-store --kubeconfig $VIEW_CLUSTER_KUBECONFIG >/dev/null 2>&1; do sleep 2; done

information "Create a service account for the metadata store"

export METADATA_STORE_ACCESS_TOKEN=$(kubectl get secrets metadata-store-read-write-client -n metadata-store -o jsonpath="{.data.token}" --kubeconfig $VIEW_CLUSTER_KUBECONFIG | base64 -d)

yq e -i '.tap_gui.app_config.proxy./metadata-store.headers.Authorization = "Bearer " + env(METADATA_STORE_ACCESS_TOKEN) + ""' "$VIEW_PROFILE"

information "Deploy TAP GUI database"

helm repo add bitnami https://charts.bitnami.com/bitnami

kubectl create ns tap-gui-backend --dry-run=client -o yaml | kubectl --kubeconfig $VIEW_CLUSTER_KUBECONFIG apply -f -

helm upgrade --install tap-gui-db bitnami/postgresql -n tap-gui-backend --set auth.postgresPassword="VMware1!" --set auth.username="tapuser" --set auth.password="VMware1!" --kubeconfig $VIEW_CLUSTER_KUBECONFIG

information "Update TAP GUI for CVE scan visibility"

tanzu package installed update tap \
  -n tap-install \
  -v $TAP_VERSION \
  -f $VIEW_PROFILE \
  --kubeconfig $VIEW_CLUSTER_KUBECONFIG \
  --wait=false
