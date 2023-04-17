#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

DNS_AUTO_CONFIGURE=$(yq e .azure.dns.auto_configure $PARAMS_YAML)
DNS_ZONE_NAME=$(yq e .azure.dns.dns_zone_name $PARAMS_YAML)
DNS_RESOURCE_GROUP=$(yq e .azure.dns.resource_group $PARAMS_YAML)
ITERATE_CLUSTER_KUBECONFIG=$(yq e .clusters.iterate_cluster.k8s_info.kubeconfig $PARAMS_YAML)
ITERATE_CLUSTER_NAME=$(yq e .clusters.iterate_cluster.k8s_info.name $PARAMS_YAML)
ITERATE_CLUSTER_INGRESS_DOMAIN=$(yq e .clusters.iterate_cluster.ingress_domain $PARAMS_YAML)
RUN_CLUSTER_COUNT=$(yq e '.clusters.run_clusters | length' $PARAMS_YAML)
VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.k8s_info.name $PARAMS_YAML)
VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.k8s_info.kubeconfig $PARAMS_YAML)
VIEW_CLUSTER_INGRESS_DOMAIN=$(yq e .clusters.view_cluster.ingress_domain $PARAMS_YAML)

function update_a_record() {
  INGRESS_DOMAIN=$1
  IP_ADDRESS=$2

  # Remove dot domain/zone name to get the A Record name (e.g. *.subdomain)
  A_RECORD_NAME="*.${INGRESS_DOMAIN%%.$DNS_ZONE_NAME}"

  A_RECORD_EXISTS=$(az network dns record-set a list -z $DNS_ZONE_NAME -g $DNS_RESOURCE_GROUP | jq "any(.name == \"$A_RECORD_NAME\")")

  if [[ $A_RECORD_EXISTS == true ]]; then
    OLD_IP_ADDRESSES=$(az network dns record-set a show -n $A_RECORD_NAME -z $DNS_ZONE_NAME -g $DNS_RESOURCE_GROUP | jq -r 'select(.aRecords != null) | .aRecords | map(.ipv4Address)')

    if [[ ! -z "$OLD_IP_ADDRESSES" ]]; then
      for ((i = 0; i < $(jq length <<<$OLD_IP_ADDRESSES); i++)); do
        information "Removing old IP Adress for A Record $A_RECORD_NAME"

        OLD_IP_ADDRESS=$(jq -r .[$i] <<<$OLD_IP_ADDRESSES)

        az network dns record-set a remove-record -n $A_RECORD_NAME -a $OLD_IP_ADDRESS -z $DNS_ZONE_NAME -g $DNS_RESOURCE_GROUP
      done
    fi
  fi

  information "Adding A Record $A_RECORD_NAME with address $IP_ADDRESS"

  az network dns record-set a add-record -n $A_RECORD_NAME -a $IP_ADDRESS -z $DNS_ZONE_NAME -g $DNS_RESOURCE_GROUP
}

function wait_for_load_balancer() {
  CLUSTER_NAME=$1
  KUBECONFIG=$2

  information "Waiting for load balancer on cluster '$CLUSTER_NAME'"

  # Purposefully not displaying any results of the kubectl command in the terminal while we wait
  while ! kubectl get service -n tanzu-system-ingress envoy -o jsonpath='{.status.loadBalancer.ingress[0].ip}' --kubeconfig $KUBECONFIG >/dev/null 2>&1; do sleep 2; done

  # Account for the delay between service creation and ip address getting assigned so wait again
  while [ -z $(kubectl get service -n tanzu-system-ingress envoy -o jsonpath='{.status.loadBalancer.ingress[0].ip}' --kubeconfig $KUBECONFIG) ]; do sleep 2; done
}

wait_for_load_balancer $VIEW_CLUSTER_NAME $VIEW_CLUSTER_KUBECONFIG
VIEW_CLUSTER_INGRESS_IP=$(kubectl get service -n tanzu-system-ingress envoy -o jsonpath='{.status.loadBalancer.ingress[0].ip}' --kubeconfig $KUBECONFIG)

wait_for_load_balancer $ITERATE_CLUSTER_NAME $ITERATE_CLUSTER_KUBECONFIG
ITERATE_CLUSTER_INGRESS_IP=$(kubectl get service -n tanzu-system-ingress envoy -o jsonpath='{.status.loadBalancer.ingress[0].ip}' --kubeconfig $KUBECONFIG)

information "Autoconfiguring DNS Zone"

information "Configuring View Cluster"

update_a_record $VIEW_CLUSTER_INGRESS_DOMAIN $VIEW_CLUSTER_INGRESS_IP

information "Configuring Iterate Cluster"

update_a_record $ITERATE_CLUSTER_INGRESS_DOMAIN $ITERATE_CLUSTER_INGRESS_IP

for ((i = 0; i < $RUN_CLUSTER_COUNT; i++)); do
  RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)

  RUN_CLUSTER_INGRESS_DOMAIN=$(yq e .clusters.run_clusters[$i].ingress_domain $PARAMS_YAML)

  wait_for_load_balancer $RUN_CLUSTER_NAME $RUN_CLUSTER_KUBECONFIG
  RUN_CLUSTER_INGRESS_IP=$(kubectl get service -n tanzu-system-ingress envoy -o jsonpath='{.status.loadBalancer.ingress[0].ip}' --kubeconfig $KUBECONFIG)

  information "Configuring Run Cluster '$RUN_CLUSTER_NAME'"

  update_a_record $RUN_CLUSTER_INGRESS_DOMAIN $RUN_CLUSTER_INGRESS_IP
done
