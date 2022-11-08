#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

export KUBECONFIG=$(yq e .azure.kubeconfig $PARAMS_YAML)
TAP_VERSION=$(yq e .tap_version $PARAMS_YAML)
TAP_VALUES_FILE='generated/tap-values.yaml'

rm -f $TAP_VALUES_FILE
yq e .tap_values $PARAMS_YAML > $TAP_VALUES_FILE

echo "## Updating a Tanzu Application Platform profile"
tanzu package installed update tap -p tap.tanzu.vmware.com -v $TAP_VERSION --values-file $TAP_VALUES_FILE -n tap-install
