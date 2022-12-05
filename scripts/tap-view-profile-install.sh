#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

TAP_VERSION=$(yq e .tap.version tap-version.yaml)
VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.k8s_info.name $PARAMS_YAML)
VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.k8s_info.kubeconfig $PARAMS_YAML)
VIEW_PROFILE="generated/profile-templates/$VIEW_CLUSTER_NAME.yaml"

information "Generating view profile"

mkdir -p generated/profile-templates
ytt -f "$PARAMS_YAML" -f profile-templates/view.yaml > $VIEW_PROFILE

information "Installing view profile"

tanzu package install tap \
  -n tap-install \
  -p tap.tanzu.vmware.com \
  -v $TAP_VERSION \
  -f $VIEW_PROFILE \
  --kubeconfig $VIEW_CLUSTER_KUBECONFIG \
  --wait=false

information "Waiting for Contour to be given an IP on view cluster"

while ! kubectl get svc -n tanzu-system-ingress envoy --kubeconfig $VIEW_CLUSTER_KUBECONFIG -o jsonpath='{.status.loadBalancer.ingress[0].ip}' >/dev/null 2>&1; do sleep 2; done

VIEW_CLUSTER_INGRESS_DOMAIN=$(yq e .clusters.view_cluster.ingress_domain $PARAMS_YAML)
VIEW_CLUSTER_INGRESS_IP=$(kubectl get service -n tanzu-system-ingress envoy --kubeconfig $VIEW_CLUSTER_KUBECONFIG -o json | jq -r .status.loadBalancer.ingress[0].ip)

message=$(cat <<END
To proceed you must register the View Cluster Wildcard DNS record with the following details:

Domain Name: *.$VIEW_CLUSTER_INGRESS_DOMAIN
IP Address: $VIEW_CLUSTER_INGRESS_IP
END
)

information "$message"

read -p "Press any key to continue once the record is created" -n1 -s
echo ""

information "Waiting for the metadata-store namespace to be created"

while ! kubectl get namespace metadata-store --kubeconfig $VIEW_CLUSTER_KUBECONFIG >/dev/null 2>&1; do sleep 2; done

information "Create a service account for the metadata store"

KUBE_VERSION=$(kubectl version -o yaml --kubeconfig $VIEW_CLUSTER_KUBECONFIG | yq e '.serverVersion.minor')

if [[ "$KUBE_VERSION" -ge "24" ]]; then
  kubectl apply -f tap-declarative-yaml/cve-viewer-tap-gui-rbac.yaml --kubeconfig $VIEW_CLUSTER_KUBECONFIG
else
  kubectl apply -f tap-declarative-yaml/cve-viewer-tap-gui-rbac-k8s-23-and-below.yaml --kubeconfig $VIEW_CLUSTER_KUBECONFIG
fi

export METADATA_STORE_ACCESS_TOKEN=$(kubectl get secrets $(kubectl get sa -n metadata-store metadata-store-read-client -o yaml --kubeconfig $VIEW_CLUSTER_KUBECONFIG | yq -r '.secrets[0].name') -n metadata-store -o jsonpath="{.data.token}" --kubeconfig $VIEW_CLUSTER_KUBECONFIG | base64 -d)

yq e -i '.tap_gui.app_config.proxy./metadata-store.headers.Authorization = "Bearer " + env(METADATA_STORE_ACCESS_TOKEN) + ""' "$VIEW_PROFILE"

information "Update TAP GUI for CVE scan visibility"

tanzu package installed update tap \
  -n tap-install \
  -v $TAP_VERSION \
  -f $VIEW_PROFILE \
  --kubeconfig $VIEW_CLUSTER_KUBECONFIG \
  --wait=false
