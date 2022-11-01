#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

CLUSTER_NAME=$(yq e .azure.aks_cluster_name $PARAMS_YAML)
export KUBECONFIG=$(yq e .azure.kubeconfig $PARAMS_YAML)
INSTALL_REGISTRY_HOSTNAME=$(yq e .tap_install.registry.hostname $PARAMS_YAML)
INSTALL_REGISTRY_USERNAME=$(yq e .tap_install.registry.username $PARAMS_YAML)
INSTALL_REGISTRY_PASSWORD=$(yq e .tap_install.registry.password $PARAMS_YAML)
TAP_VALUES_FILE='generated/tap-values.yaml'

rm -f $TAP_VALUES_FILE
yq e .tap_values $PARAMS_YAML > $TAP_VALUES_FILE

echo "## $KUBECONFIG Adding the TAP package repository"

kubectl create ns tap-install --dry-run=client -o yaml | kubectl apply -f -

tanzu secret registry add tap-registry \
  --username $INSTALL_REGISTRY_USERNAME --password $INSTALL_REGISTRY_PASSWORD \
  --server $INSTALL_REGISTRY_HOSTNAME \
  --export-to-all-namespaces --yes --namespace tap-install

tanzu package repository add tanzu-tap-repository \
  --url registry.tanzu.vmware.com/tanzu-application-platform/tap-packages:1.1.0 \
  --namespace tap-install

tanzu package repository get tanzu-tap-repository --namespace tap-install

tanzu package available list --namespace tap-install

if [[ -z $(tanzu package installed list -n tap-install -o yaml | yq '.[] | select(.name == "tap")') ]]; then
  echo "## Installing a Tanzu Application Platform profile"
  tanzu package install tap -p tap.tanzu.vmware.com -v 1.1.0 --values-file $TAP_VALUES_FILE -n tap-install
else
  echo "## Updating a Tanzu Application Platform profile"
  tanzu package installed update tap -p tap.tanzu.vmware.com -v 1.1.0 --values-file $TAP_VALUES_FILE -n tap-install
fi

tanzu package installed get tap -n tap-install

tanzu package installed list -A