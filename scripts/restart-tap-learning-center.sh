#!/bin/bash
set -e -o pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source $SCRIPTS/set-env.sh

VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.k8s_info.kubeconfig $PARAMS_YAML)

information "Restarting learning center"

kubectl delete deployment learningcenter-operator -n learningcenter --kubeconfig $VIEW_CLUSTER_KUBECONFIG

kctrl app kick -a learningcenter -n tap-install -y --kubeconfig $VIEW_CLUSTER_KUBECONFIG

kubectl delete trainingportals learning-center-guided --kubeconfig $VIEW_CLUSTER_KUBECONFIG

kctrl app kick -a learningcenter-workshops -n tap-install -y --kubeconfig $VIEW_CLUSTER_KUBECONFIG
