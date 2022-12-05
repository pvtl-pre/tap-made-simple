#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

DELIVERABLES_DIR="generated/deliverables"
BUILD_CLUSTER_KUBECONFIG=$(yq e .clusters.build_cluster.k8s_info.kubeconfig $PARAMS_YAML)

mkdir -p $DELIVERABLES_DIR

information "Creating workload tanzu-java-web-app on the Build Cluster"

tanzu apps workload apply tanzu-java-web-app \
  --git-repo https://github.com/pvtl-pre/tanzu-java-web-app.git \
  --git-branch main \
  --type web \
  --label app.kubernetes.io/part-of=tanzu-java-web-app \
  --label apps.tanzu.vmware.com/has-tests=true \
  --param-yaml testing_pipeline_matching_labels='{"apps.tanzu.vmware.com/language":"java", "apps.tanzu.vmware.com/pipeline":"test"}' \
  --namespace default \
  --yes \
  --kubeconfig $BUILD_CLUSTER_KUBECONFIG

information "Creating workload python-function on the Build Cluster"

tanzu apps workload apply python-function \
  --git-repo https://github.com/pvtl-pre/python-function.git \
  --git-branch main \
  --type web \
  --label app.kubernetes.io/part-of=python-function \
  --label apps.tanzu.vmware.com/has-tests=true \
  --param-yaml testing_pipeline_matching_labels='{"apps.tanzu.vmware.com/language":"python", "apps.tanzu.vmware.com/pipeline":"test"}' \
  --namespace default \
  --build-env BP_FUNCTION=func.main \
  --yes \
  --kubeconfig $BUILD_CLUSTER_KUBECONFIG

information "Waiting for deliverable tanzu-java-web-app"

while ! kubectl get configmap tanzu-java-web-app -o yaml --kubeconfig $BUILD_CLUSTER_KUBECONFIG >/dev/null 2>&1; do sleep 2; done

information "Waiting for deliverable python-function"

while ! kubectl get configmap python-function -o yaml --kubeconfig $BUILD_CLUSTER_KUBECONFIG >/dev/null 2>&1; do sleep 2; done

kubectl get configmap tanzu-java-web-app -o go-template='{{.data.deliverable}}' --kubeconfig $BUILD_CLUSTER_KUBECONFIG > $DELIVERABLES_DIR/tanzu-java-web-app.yaml
kubectl get configmap python-function -o go-template='{{.data.deliverable}}' --kubeconfig $BUILD_CLUSTER_KUBECONFIG > $DELIVERABLES_DIR/python-function.yaml

declare -a run_clusters=($(yq e -o=j -I=0 '.clusters.run_clusters[]' $PARAMS_YAML))

for ((i=0;i<${#run_clusters[@]};i++)); 
do
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)
  RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)

  information "Deploying deliverables on Run Cluster '$RUN_CLUSTER_NAME'"

  kubectl apply -f $DELIVERABLES_DIR/tanzu-java-web-app.yaml --kubeconfig $RUN_CLUSTER_KUBECONFIG
  kubectl apply -f $DELIVERABLES_DIR/python-function.yaml --kubeconfig $RUN_CLUSTER_KUBECONFIG
done