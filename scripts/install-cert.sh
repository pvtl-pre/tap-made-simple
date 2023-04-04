#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

CERT_PATH="generated/cert"
GENERATE_CERT=$(yq e .tls.generate $PARAMS_YAML)
ITERATE_CLUSTER_KUBECONFIG=$(yq e .clusters.iterate_cluster.k8s_info.kubeconfig $PARAMS_YAML)
RUN_CLUSTER_COUNT=$(yq e '.clusters.run_clusters | length' $PARAMS_YAML)
VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.k8s_info.kubeconfig $PARAMS_YAML)

mkdir -p $CERT_PATH

if [[ $GENERATE_CERT == true ]]; then
  $TKG_LAB_SCRIPTS/generate-cert.sh
else
  information "Skipped cert generation due to user providing cert"

  information "Getting cert details"

  echo $(yq e .tls.cert_data $PARAMS_YAML) | base64 --decode > $CERT_PATH/wildcard.cer
  echo $(yq e .tls.key_data $PARAMS_YAML) | base64 --decode > $CERT_PATH/wildcard.key
fi

information "Creating TLS secret yaml"

kubectl create secret tls wildcard -n tap-install --cert=$CERT_PATH/wildcard.cer --key=$CERT_PATH/wildcard.key --dry-run=client -o yaml > $CERT_PATH/tls-secret.yaml

information "Applying TLS secret on the View Cluster"

kubectl apply -f $CERT_PATH/tls-secret.yaml --kubeconfig $VIEW_CLUSTER_KUBECONFIG

information "Applying TLS secret on the Iterate Cluster"

kubectl apply -f $CERT_PATH/tls-secret.yaml --kubeconfig $ITERATE_CLUSTER_KUBECONFIG

for ((i=0;i<$RUN_CLUSTER_COUNT;i++)); 
do
  RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)

  information "Applying TLS secret on Run Cluster '$RUN_CLUSTER_NAME'"

  kubectl apply -f $CERT_PATH/tls-secret.yaml --kubeconfig $RUN_CLUSTER_KUBECONFIG
done
