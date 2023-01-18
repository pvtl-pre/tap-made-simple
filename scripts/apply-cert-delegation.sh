#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

CERT_PATH="generated/cert"

VIEW_CLUSTER_KUBECONFIG=$(yq e .clusters.view_cluster.k8s_info.kubeconfig $PARAMS_YAML)

information "Waiting for Contour CRD tlscertificatedelegations.projectcontour.io on the View Cluster"

while ! kubectl get crd tlscertificatedelegations.projectcontour.io --kubeconfig $VIEW_CLUSTER_KUBECONFIG >/dev/null 2>&1; do sleep 2; done

information "Applying TLS certificate delegation on the View Cluster"

kubectl apply -f tap-declarative-yaml/tls-delegation.yaml --kubeconfig $VIEW_CLUSTER_KUBECONFIG

ITERATE_CLUSTER_KUBECONFIG=$(yq e .clusters.iterate_cluster.k8s_info.kubeconfig $PARAMS_YAML)

information "Waiting for Contour CRD tlscertificatedelegations.projectcontour.io on the Iterate Cluster"

while ! kubectl get crd tlscertificatedelegations.projectcontour.io --kubeconfig $ITERATE_CLUSTER_KUBECONFIG >/dev/null 2>&1; do sleep 2; done

information "Applying TLS certificate delegation on the Iterate Cluster"

kubectl apply -f tap-declarative-yaml/tls-delegation.yaml --kubeconfig $ITERATE_CLUSTER_KUBECONFIG

declare -a run_clusters=($(yq e -o=j -I=0 '.clusters.run_clusters[]' $PARAMS_YAML))

for ((i=0;i<${#run_clusters[@]};i++)); 
do
  RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)

  information "Waiting for Contour CRD tlscertificatedelegations.projectcontour.io on Run Cluster '$RUN_CLUSTER_NAME'"

  while ! kubectl get crd tlscertificatedelegations.projectcontour.io --kubeconfig $RUN_CLUSTER_KUBECONFIG >/dev/null 2>&1; do sleep 2; done

  information "Applying TLS certificate delegation on Run Cluster '$RUN_CLUSTER_NAME'"

  kubectl apply -f tap-declarative-yaml/tls-delegation.yaml --kubeconfig $RUN_CLUSTER_KUBECONFIG
done
