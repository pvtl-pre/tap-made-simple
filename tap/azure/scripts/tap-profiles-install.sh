#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

# export INSTALL_DEV_NAMESPACE=$(yq e .tap_install.dev_namespace $PARAMS_YAML)
# export SC_REGISTRY_SECRET_NAME=$(yq e .tap_install.supply_chain_registry_secret $PARAMS_YAML)

# yq e -i '.tap_values.metadata_store.ns_for_export_app_cert = env(INSTALL_DEV_NAMESPACE)' "$PARAMS_YAML"
# yq e -i '.tap_values.grype.namespace = env(INSTALL_DEV_NAMESPACE)' "$PARAMS_YAML"
# yq e -i '.tap_values.grype.targetImagePullSecret = env(SC_REGISTRY_SECRET_NAME)' "$PARAMS_YAML"

TAP_VERSION=$(yq e .tap_version $PARAMS_YAML)

information "Installing base TAP components on view cluster"

VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.k8s_info.kubeconfig $PARAMS_YAML)

KUBECONFIG=$VIEW_CLUSTER_KUBECONFIG \
IS_VIEW_CLUSTER=true \
$TKG_LAB_SCRIPTS/tap-profiles-base-install.sh

information "Installing base TAP components on build cluster"

BUILD_CLUSTER_KUBECONFIG=$(yq e .clusters.build_cluster.k8s_info.kubeconfig $PARAMS_YAML)
SA_TOKEN_PATH=".clusters.build_cluster.k8s_info.saToken"

KUBECONFIG=$BUILD_CLUSTER_KUBECONFIG \
SA_TOKEN_PATH=$SA_TOKEN_PATH \
IS_VIEW_CLUSTER=false \
$TKG_LAB_SCRIPTS/tap-profiles-base-install.sh

information "Installing base TAP components on run clusters"

declare -a run_clusters=($(yq e -o=j -I=0 '.clusters.run_clusters[]' $PARAMS_YAML))

for ((i=0;i<${#run_clusters[@]};i++)); 
do
  RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)
  SA_TOKEN_PATH=".clusters.run_clusters[$i].k8s_info.saToken"

  KUBECONFIG=$RUN_CLUSTER_KUBECONFIG \
  SA_TOKEN_PATH=$SA_TOKEN_PATH \
  IS_VIEW_CLUSTER=false \
  $TKG_LAB_SCRIPTS/tap-profiles-base-install.sh
done

information "Installing view profile"

$TKG_LAB_SCRIPTS/tap-view-profile-install.sh

information "Installing build profile"

VIEW_CLUSTER_KUBECONFIG=$VIEW_CLUSTER_KUBECONFIG $TKG_LAB_SCRIPTS/tap-build-profile-install.sh

information "Installing run profiles"

$TKG_LAB_SCRIPTS/tap-run-profiles-install.sh

information "Waiting for reconciliation of TAP clusters"

kubectl wait pkgi --for condition=ReconcileSucceeded=True \
  -n tap-install tap \
  --kubeconfig $VIEW_CLUSTER_KUBECONFIG \
  --timeout=15m

kubectl wait pkgi --for condition=ReconcileSucceeded=True \
  -n tap-install tap \
  --kubeconfig $BUILD_CLUSTER_KUBECONFIG \
  --timeout=15m

for ((i=0;i<${#run_clusters[@]};i++)); 
do
  RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)

  kubectl wait pkgi --for condition=ReconcileSucceeded=True \
    -n tap-install tap \
    --kubeconfig $RUN_CLUSTER_KUBECONFIG \
    --timeout=15m
done

for ((i=0;i<${#run_clusters[@]};i++)); 
do
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)
  RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)

  RUN_CLUSTER_INGRESS_DOMAIN=$(yq e .clusters.run_clusters[$i].ingressDomain $PARAMS_YAML)
  RUN_CLUSTER_INGRESS_IP=$(kubectl get service -n tanzu-system-ingress envoy --kubeconfig $RUN_CLUSTER_KUBECONFIG -o json | jq -r .status.loadBalancer.ingress[0].ip)

  message=$(cat <<END
To proceed you must register the Run Cluster ($RUN_CLUSTER_NAME) Wildcard DNS record with the following details:

Domain Name: *.$RUN_CLUSTER_INGRESS_DOMAIN
IP Address: $RUN_CLUSTER_INGRESS_IP
END
  )

  information "$message"

  read -p "Press any key to continue once the record is created" -n1 -s
  echo ""
done
