#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

BUILD_CLUSTER_KUBECONFIG=$(yq e .clusters.build_cluster.k8s_info.kubeconfig $PARAMS_YAML)
DELIVERABLES_DIR="generated/deliverables"
RUN_CLUSTER_COUNT=$(yq e '.clusters.run_clusters | length' $PARAMS_YAML)

mkdir -p $DELIVERABLES_DIR

information "Creating workload tanzu-java-web-app on the Build Cluster"

tanzu apps workload apply tanzu-java-web-app \
  --git-repo https://github.com/pvtl-pre/tanzu-java-web-app.git \
  --git-branch main \
  --type web \
  --label app.kubernetes.io/part-of=tanzu-java-web-app \
  -n product-team1 \
  --yes \
  --kubeconfig $BUILD_CLUSTER_KUBECONFIG

information "Waiting for deliverable tanzu-java-web-app"

while ! kubectl get configmap tanzu-java-web-app-deliverable -n product-team1 -o yaml --kubeconfig $BUILD_CLUSTER_KUBECONFIG >/dev/null 2>&1; do sleep 2; done

kubectl get configmap tanzu-java-web-app-deliverable -n product-team1 -o go-template='{{.data.deliverable}}' --kubeconfig $BUILD_CLUSTER_KUBECONFIG >$DELIVERABLES_DIR/tanzu-java-web-app.yaml

for ((i = 0; i < $RUN_CLUSTER_COUNT; i++)); do
  RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)

  information "Deploying deliverables on Run Cluster '$RUN_CLUSTER_NAME'"

  kubectl apply -f $DELIVERABLES_DIR/tanzu-java-web-app.yaml -n product-team1 --kubeconfig $RUN_CLUSTER_KUBECONFIG
done
