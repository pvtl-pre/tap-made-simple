#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

BUILD_CLUSTER_KUBECONFIG=$(yq e .clusters.build_cluster.k8s_info.kubeconfig $PARAMS_YAML)
BUILD_CLUSTER_NAME=$(yq e .clusters.build_cluster.k8s_info.name $PARAMS_YAML)
ITERATE_CLUSTER_KUBECONFIG=$(yq e .clusters.iterate_cluster.k8s_info.kubeconfig $PARAMS_YAML)
ITERATE_CLUSTER_NAME=$(yq e .clusters.iterate_cluster.k8s_info.name $PARAMS_YAML)

function add_dev_namespace() {
  CLUSTER_NAME=$1
  KUBECONFIG=$2

  information "Create a Java pipeline on cluster '$CLUSTER_NAME'"

  kubectl apply -f tap-declarative-yaml/dev-namespace/java-pipeline.yaml -n product-team1 --kubeconfig $KUBECONFIG

  #information "Create a Python pipeline on cluster '$CLUSTER_NAME'"

  #kubectl apply -f tap-declarative-yaml/dev-namespace/python-pipeline.yaml -n product-team1 --kubeconfig $KUBECONFIG
}

add_dev_namespace $ITERATE_CLUSTER_NAME $ITERATE_CLUSTER_KUBECONFIG
add_dev_namespace $BUILD_CLUSTER_NAME $BUILD_CLUSTER_KUBECONFIG
