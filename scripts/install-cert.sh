#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

CERT_PATH="generated/cert"
GENERATE_CERT=$(yq e .tls.generate $PARAMS_YAML)
ITERATE_CLUSTER_KUBECONFIG=$(yq e .clusters.iterate_cluster.k8s_info.kubeconfig $PARAMS_YAML)
ITERATE_CLUSTER_NAME=$(yq e .clusters.iterate_cluster.k8s_info.name $PARAMS_YAML)
RUN_CLUSTER_COUNT=$(yq e '.clusters.run_clusters | length' $PARAMS_YAML)
VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.k8s_info.name $PARAMS_YAML)
VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.k8s_info.kubeconfig $PARAMS_YAML)

ITERATE_PROFILE="generated/profiles/$ITERATE_CLUSTER_NAME.yaml"
VIEW_PROFILE="generated/profiles/$VIEW_CLUSTER_NAME.yaml"

function install_cert() {
  CLUSTER_NAME=$1
  KUBECONFIG=$2

  information "Applying TLS secret on cluster '$CLUSTER_NAME'"

  kubectl apply -f $CERT_PATH/tls-secret.yaml --kubeconfig $KUBECONFIG

  information "Waiting for Contour CRD tlscertificatedelegations.projectcontour.io on cluster '$CLUSTER_NAME'"

  while ! kubectl get crd tlscertificatedelegations.projectcontour.io --kubeconfig $KUBECONFIG >/dev/null 2>&1; do sleep 2; done

  information "Applying TLS certificate delegation on cluster '$CLUSTER_NAME'"

  kubectl apply -f tap-declarative-yaml/tls-delegation.yaml --kubeconfig $KUBECONFIG
}

mkdir -p $CERT_PATH

if [[ $GENERATE_CERT == true ]]; then
  $SCRIPTS/generate-cert.sh
else
  information "Skipped cert generation due to user providing cert"

  information "Getting cert details"

  yq e .tls.cert_data $PARAMS_YAML | base64 --decode >$CERT_PATH/wildcard.cer
  yq e .tls.key_data $PARAMS_YAML | base64 --decode >$CERT_PATH/wildcard.key
fi

information "Creating TLS secret yaml"

kubectl create secret tls wildcard -n tap-install --cert=$CERT_PATH/wildcard.cer --key=$CERT_PATH/wildcard.key --dry-run=client -o yaml >$CERT_PATH/tls-secret.yaml

install_cert $VIEW_CLUSTER_NAME $VIEW_CLUSTER_KUBECONFIG
install_cert $ITERATE_CLUSTER_NAME $ITERATE_CLUSTER_KUBECONFIG

for ((i = 0; i < $RUN_CLUSTER_COUNT; i++)); do
  RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)

  install_cert $RUN_CLUSTER_NAME $RUN_CLUSTER_KUBECONFIG
done

information "Updating generated profiles with load balancer configuration"

ytt \
  --data-value-file app_live_view_cert=$CERT_PATH/wildcard.cer \
  --data-value-file learning_center_cert=$CERT_PATH/wildcard.cer \
  --data-value-file learning_center_private_key=$CERT_PATH/wildcard.key \
  -v tls_namespace=tap-install \
  -v tls_secret_name=wildcard \
  -f "$PARAMS_YAML" \
  -f $VIEW_PROFILE \
  -f profile-overlays/tls.yaml \
  --output-files generated/profiles

ytt \
  --data-value-file app_live_view_cert=$CERT_PATH/wildcard.cer \
  --data-value-file learning_center_cert=$CERT_PATH/wildcard.cer \
  --data-value-file learning_center_private_key=$CERT_PATH/wildcard.key \
  -v tls_namespace=tap-install \
  -v tls_secret_name=wildcard \
  -f "$PARAMS_YAML" \
  -f $ITERATE_PROFILE \
  -f profile-overlays/tls.yaml \
  --output-files generated/profiles

for ((i = 0; i < $RUN_CLUSTER_COUNT; i++)); do
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)

  RUN_PROFILE="generated/profiles/$RUN_CLUSTER_NAME.yaml"

  ytt \
    --data-value-file app_live_view_cert=$CERT_PATH/wildcard.cer \
    --data-value-file learning_center_cert=$CERT_PATH/wildcard.cer \
    --data-value-file learning_center_private_key=$CERT_PATH/wildcard.key \
    -v tls_namespace=tap-install \
    -v tls_secret_name=wildcard \
    -f "$PARAMS_YAML" \
    -f $RUN_PROFILE \
    -f profile-overlays/tls.yaml \
    --output-files generated/profiles
done

$SCRIPTS/install-tap-view-profile.sh
$SCRIPTS/install-tap-iterate-profile.sh
$SCRIPTS/install-tap-run-profiles.sh

$SCRIPTS/reconcile-tap-install-for-view-cluster.sh
$SCRIPTS/reconcile-tap-install-for-iterate-cluster.sh
$SCRIPTS/reconcile-tap-install-for-run-clusters.sh

$SCRIPTS/restart-tap-learning-center.sh
