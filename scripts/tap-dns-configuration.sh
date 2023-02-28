#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

information "To proceed, you must register the wildcard DNS record with the following details:"

VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.k8s_info.kubeconfig $PARAMS_YAML)
VIEW_CLUSTER_INGRESS_DOMAIN=$(yq e .clusters.view_cluster.ingress_domain $PARAMS_YAML)
VIEW_CLUSTER_INGRESS_IP=$(kubectl get service -n tanzu-system-ingress envoy -o jsonpath='{.status.loadBalancer.ingress[0].ip}' --kubeconfig $VIEW_CLUSTER_KUBECONFIG)

echo "Domain Name: *.$VIEW_CLUSTER_INGRESS_DOMAIN"
echo "IP Address: $VIEW_CLUSTER_INGRESS_IP"
echo ""



ITERATE_CLUSTER_KUBECONFIG=$(yq e .clusters.iterate_cluster.k8s_info.kubeconfig $PARAMS_YAML)
ITERATE_CLUSTER_INGRESS_DOMAIN=$(yq e .clusters.iterate_cluster.ingress_domain $PARAMS_YAML)
ITERATE_CLUSTER_INGRESS_IP=$(kubectl get service -n tanzu-system-ingress envoy --kubeconfig $ITERATE_CLUSTER_KUBECONFIG -o json | jq -r .status.loadBalancer.ingress[0].ip)

echo "Domain Name: *.$ITERATE_CLUSTER_INGRESS_DOMAIN"
echo "IP Address: $ITERATE_CLUSTER_INGRESS_IP"
echo ""



declare -a run_clusters=($(yq e -o=j -I=0 '.clusters.run_clusters[]' $PARAMS_YAML))

for ((i=0;i<${#run_clusters[@]};i++)); 
do
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)
  RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)

  RUN_CLUSTER_INGRESS_DOMAIN=$(yq e .clusters.run_clusters[$i].ingress_domain $PARAMS_YAML)
  RUN_CLUSTER_INGRESS_IP=$(kubectl get service -n tanzu-system-ingress envoy --kubeconfig $RUN_CLUSTER_KUBECONFIG -o json | jq -r .status.loadBalancer.ingress[0].ip)

  echo "Domain Name: *.$RUN_CLUSTER_INGRESS_DOMAIN"
  echo "IP Address: $RUN_CLUSTER_INGRESS_IP"
  echo ""
done
