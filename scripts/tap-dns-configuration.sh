#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

DNS_AUTO_CONFIGURE=$(yq e .azure.dns.auto_configure $PARAMS_YAML)
DNS_ZONE_NAME=$(yq e .azure.dns.dns_zone_name $PARAMS_YAML)
DNS_RESOURCE_GROUP=$(yq e .azure.dns.resource_group $PARAMS_YAML)
ITERATE_CLUSTER_KUBECONFIG=$(yq e .clusters.iterate_cluster.k8s_info.kubeconfig $PARAMS_YAML)
ITERATE_CLUSTER_INGRESS_DOMAIN=$(yq e .clusters.iterate_cluster.ingress_domain $PARAMS_YAML)
ITERATE_CLUSTER_INGRESS_IP=$(kubectl get service -n tanzu-system-ingress envoy --kubeconfig $ITERATE_CLUSTER_KUBECONFIG -o json | jq -r .status.loadBalancer.ingress[0].ip)
RUN_CLUSTER_COUNT=$(yq e '.clusters.run_clusters | length' $PARAMS_YAML)
VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.k8s_info.kubeconfig $PARAMS_YAML)
VIEW_CLUSTER_INGRESS_DOMAIN=$(yq e .clusters.view_cluster.ingress_domain $PARAMS_YAML)
VIEW_CLUSTER_INGRESS_IP=$(kubectl get service -n tanzu-system-ingress envoy -o jsonpath='{.status.loadBalancer.ingress[0].ip}' --kubeconfig $VIEW_CLUSTER_KUBECONFIG)

if [[ $DNS_AUTO_CONFIGURE == true ]]; then
  function update_a_record() {
    INGRESS_DOMAIN=$1
    IP_ADDRESS=$2

    # Remove dot domain/zone name to get the A Record name (e.g. *.subdomain)
    A_RECORD_NAME="*.${INGRESS_DOMAIN%%.$DNS_ZONE_NAME}"

    A_RECORD_EXISTS=$(az network dns record-set a list -z $DNS_ZONE_NAME -g $DNS_RESOURCE_GROUP | jq "any(.name == \"$A_RECORD_NAME\")")

    if [[ $A_RECORD_EXISTS == true ]]; then
      OLD_IP_ADDRESS=$(az network dns record-set a show -n $A_RECORD_NAME -z $DNS_ZONE_NAME -g $DNS_RESOURCE_GROUP | jq -r '.aRecords[0].ipv4Address')

      information "Removing old IP Adress for A Record $A_RECORD_NAME"
      az network dns record-set a remove-record -n $A_RECORD_NAME -a $OLD_IP_ADDRESS -z $DNS_ZONE_NAME -g $DNS_RESOURCE_GROUP
    fi

    information "Adding A Record $A_RECORD_NAME with address $IP_ADDRESS"
    az network dns record-set a add-record -n $A_RECORD_NAME -a $IP_ADDRESS -z $DNS_ZONE_NAME -g $DNS_RESOURCE_GROUP
  }

  information "Autoconfiguring DNS Zone"

  information "Configuring View Cluster"

  update_a_record $VIEW_CLUSTER_INGRESS_DOMAIN $VIEW_CLUSTER_INGRESS_IP

  information "Configuring Iterate Cluster"

  update_a_record $ITERATE_CLUSTER_INGRESS_DOMAIN $ITERATE_CLUSTER_INGRESS_IP

  for ((i=0;i<$RUN_CLUSTER_COUNT;i++)); 
  do
    RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)
    RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)

    RUN_CLUSTER_INGRESS_DOMAIN=$(yq e .clusters.run_clusters[$i].ingress_domain $PARAMS_YAML)
    RUN_CLUSTER_INGRESS_IP=$(kubectl get service -n tanzu-system-ingress envoy --kubeconfig $RUN_CLUSTER_KUBECONFIG -o json | jq -r .status.loadBalancer.ingress[0].ip)

    information "Configuring Run Cluster '$RUN_CLUSTER_NAME'"

    update_a_record $RUN_CLUSTER_INGRESS_DOMAIN $RUN_CLUSTER_INGRESS_IP
  done
else
  information "To proceed, you must register the wildcard DNS record with the following details:"

  echo "Domain Name: *.$VIEW_CLUSTER_INGRESS_DOMAIN"
  echo "IP Address: $VIEW_CLUSTER_INGRESS_IP"
  echo ""

  echo "Domain Name: *.$ITERATE_CLUSTER_INGRESS_DOMAIN"
  echo "IP Address: $ITERATE_CLUSTER_INGRESS_IP"
  echo ""

  for ((i=0;i<$RUN_CLUSTER_COUNT;i++)); 
  do
    RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)
    RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)

    RUN_CLUSTER_INGRESS_DOMAIN=$(yq e .clusters.run_clusters[$i].ingress_domain $PARAMS_YAML)
    RUN_CLUSTER_INGRESS_IP=$(kubectl get service -n tanzu-system-ingress envoy --kubeconfig $RUN_CLUSTER_KUBECONFIG -o json | jq -r .status.loadBalancer.ingress[0].ip)

    echo "Domain Name: *.$RUN_CLUSTER_INGRESS_DOMAIN"
    echo "IP Address: $RUN_CLUSTER_INGRESS_IP"
    echo ""
  done
fi

