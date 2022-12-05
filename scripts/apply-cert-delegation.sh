#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

CERT_PATH="generated/cert"

information "Applying TLS certificate delegation on the View Cluster"

VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.k8s_info.kubeconfig $PARAMS_YAML)

{ sed -n /tlscertificatedelegations.projectcontour.io/q; kill $!; } < <(kubectl get crd -w --kubeconfig $VIEW_CLUSTER_KUBECONFIG)
kubectl apply -f tap-declarative-yaml/tls-delegation.yaml --kubeconfig $VIEW_CLUSTER_KUBECONFIG

declare -a run_clusters=($(yq e -o=j -I=0 '.clusters.run_clusters[]' $PARAMS_YAML))

for ((i=0;i<${#run_clusters[@]};i++)); 
do
  RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)

  information "Applying TLS certificate delegation on Run Cluster '$RUN_CLUSTER_NAME'"

  { sed -n /tlscertificatedelegations.projectcontour.io/q; kill $!; } < <(kubectl get crd -w --kubeconfig $RUN_CLUSTER_KUBECONFIG)
  kubectl apply -f tap-declarative-yaml/tls-delegation.yaml --kubeconfig $RUN_CLUSTER_KUBECONFIG
done
