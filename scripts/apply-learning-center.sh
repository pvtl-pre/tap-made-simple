#!/bin/bash
set -e -o pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source $SCRIPTS/set-env.sh

VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.k8s_info.kubeconfig $PARAMS_YAML)
VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.k8s_info.name $PARAMS_YAML)

KUBE_VERSION=$(kubectl version -o yaml --kubeconfig $VIEW_CLUSTER_KUBECONFIG | yq e '.serverVersion.minor')
VIEW_PROFILE="generated/profiles/$VIEW_CLUSTER_NAME.yaml"

information "Updating generated view profile with learning center configuration"

ytt -f "$PARAMS_YAML" -f $VIEW_PROFILE -f profile-overlays/learning-center.yaml --output-files generated/profiles

# NOTE: podsecuritypolicies were removed in 1.25 but TAP doesn't know to use Pod Security Admission instead
if [[ $KUBE_VERSION -ge 25 ]]; then
  ytt -v k8s_version="1.$KUBE_VERSION.0" -f "$PARAMS_YAML" -f $VIEW_PROFILE -f profile-overlays/learning-center-podsecuritypolicy-fix.yaml --output-files generated/profiles
fi

$SCRIPTS/apply-view-profile.sh

$SCRIPTS/reconcile-view-cluster.sh

$SCRIPTS/restart-learning-center.sh
