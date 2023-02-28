#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

TAP_VERSION=$(yq e .tap.version tap-version.yaml)

information "Installing base TAP components on the View Cluster"

VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.k8s_info.name $PARAMS_YAML)
VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.k8s_info.kubeconfig $PARAMS_YAML)

CLUSTER_NAME=$VIEW_CLUSTER_NAME \
KUBECONFIG=$VIEW_CLUSTER_KUBECONFIG \
IS_BUILD_OR_RUN_CLUSTER=false \
$TKG_LAB_SCRIPTS/tap-profiles-base-install.sh

information "Installing base TAP components on the Iterate Cluster"

ITERATE_CLUSTER_NAME=$(yq e .clusters.iterate_cluster.k8s_info.name $PARAMS_YAML)
ITERATE_CLUSTER_KUBECONFIG=$(yq e .clusters.iterate_cluster.k8s_info.kubeconfig $PARAMS_YAML)
SA_TOKEN_PATH=".clusters.iterate_cluster.k8s_info.sa_token"

CLUSTER_NAME=$ITERATE_CLUSTER_NAME \
KUBECONFIG=$ITERATE_CLUSTER_KUBECONFIG \
SA_TOKEN_PATH=$SA_TOKEN_PATH \
IS_BUILD_OR_RUN_CLUSTER=false \
$TKG_LAB_SCRIPTS/tap-profiles-base-install.sh

information "Installing base TAP components on the Build Cluster"

BUILD_CLUSTER_NAME=$(yq e .clusters.build_cluster.k8s_info.name $PARAMS_YAML)
BUILD_CLUSTER_KUBECONFIG=$(yq e .clusters.build_cluster.k8s_info.kubeconfig $PARAMS_YAML)
SA_TOKEN_PATH=".clusters.build_cluster.k8s_info.sa_token"

CLUSTER_NAME=$BUILD_CLUSTER_NAME \
KUBECONFIG=$BUILD_CLUSTER_KUBECONFIG \
SA_TOKEN_PATH=$SA_TOKEN_PATH \
IS_BUILD_OR_RUN_CLUSTER=true \
$TKG_LAB_SCRIPTS/tap-profiles-base-install.sh

declare -a run_clusters=($(yq e -o=j -I=0 '.clusters.run_clusters[]' $PARAMS_YAML))

for ((i=0;i<${#run_clusters[@]};i++)); 
do
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)
  RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)
  SA_TOKEN_PATH=".clusters.run_clusters[$i].k8s_info.sa_token"

  information "Installing base TAP components on Run Cluster '$RUN_CLUSTER_NAME'"

  CLUSTER_NAME=$RUN_CLUSTER_NAME \
  KUBECONFIG=$RUN_CLUSTER_KUBECONFIG \
  SA_TOKEN_PATH=$SA_TOKEN_PATH \
  IS_BUILD_OR_RUN_CLUSTER=true \
  $TKG_LAB_SCRIPTS/tap-profiles-base-install.sh
done

information "Applying cert"

$TKG_LAB_SCRIPTS/apply-cert.sh

information "Installing view profile"

$TKG_LAB_SCRIPTS/tap-view-profile-install.sh

information "Installing iterate profile"

CLUSTER_TYPE=iterate \
VIEW_CLUSTER_KUBECONFIG=$VIEW_CLUSTER_KUBECONFIG \
$TKG_LAB_SCRIPTS/tap-build-or-iterate-profile-install.sh

information "Installing build profile"

CLUSTER_TYPE=build \
VIEW_CLUSTER_KUBECONFIG=$VIEW_CLUSTER_KUBECONFIG \
$TKG_LAB_SCRIPTS/tap-build-or-iterate-profile-install.sh

information "Installing run profiles"

$TKG_LAB_SCRIPTS/tap-run-profiles-install.sh

information "Applying cert delegation"

$TKG_LAB_SCRIPTS/apply-cert-delegation.sh

information "Waiting for reconciliation on the View Cluster"

kubectl wait pkgi --for condition=ReconcileSucceeded=True \
  -n tap-install tap \
  --kubeconfig $VIEW_CLUSTER_KUBECONFIG \
  --timeout=15m

information "Waiting for reconciliation on the Iterate Cluster"

kubectl wait pkgi --for condition=ReconcileSucceeded=True \
  -n tap-install tap \
  --kubeconfig $ITERATE_CLUSTER_KUBECONFIG \
  --timeout=15m

information "Waiting for reconciliation on the Build Cluster"

kubectl wait pkgi --for condition=ReconcileSucceeded=True \
  -n tap-install tap \
  --kubeconfig $BUILD_CLUSTER_KUBECONFIG \
  --timeout=15m

for ((i=0;i<${#run_clusters[@]};i++)); 
do
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)
  RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)

  information "Waiting for reconciliation on Run Cluster '$RUN_CLUSTER_NAME'"

  kubectl wait pkgi --for condition=ReconcileSucceeded=True \
    -n tap-install tap \
    --kubeconfig $RUN_CLUSTER_KUBECONFIG \
    --timeout=15m
done
