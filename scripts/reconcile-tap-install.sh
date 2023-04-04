#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

BUILD_CLUSTER_KUBECONFIG=$(yq e .clusters.build_cluster.k8s_info.kubeconfig $PARAMS_YAML)
BUILD_CLUSTER_NAME=$(yq e .clusters.build_cluster.k8s_info.name $PARAMS_YAML)
ITERATE_CLUSTER_KUBECONFIG=$(yq e .clusters.iterate_cluster.k8s_info.kubeconfig $PARAMS_YAML)
ITERATE_CLUSTER_NAME=$(yq e .clusters.iterate_cluster.k8s_info.name $PARAMS_YAML)
RUN_CLUSTER_COUNT=$(yq e '.clusters.run_clusters | length' $PARAMS_YAML)
VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.k8s_info.kubeconfig $PARAMS_YAML)
VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.k8s_info.name $PARAMS_YAML)

function reconcile() {
  CLUSTER_NAME=$1
  KUBECONFIG=$2

  information "Waiting for reconciliation on cluster '$CLUSTER_NAME'"

  kubectl wait pkgi --for condition=ReconcileSucceeded=True \
  -n tap-install tap \
  --kubeconfig $KUBECONFIG \
  --timeout=15m
}

reconcile $VIEW_CLUSTER_NAME    $VIEW_CLUSTER_KUBECONFIG
reconcile $ITERATE_CLUSTER_NAME $ITERATE_CLUSTER_KUBECONFIG
reconcile $BUILD_CLUSTER_NAME   $BUILD_CLUSTER_KUBECONFIG

for ((i=0;i<$RUN_CLUSTER_COUNT;i++)); 
do
  RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)

  reconcile $RUN_CLUSTER_NAME $RUN_CLUSTER_KUBECONFIG
done