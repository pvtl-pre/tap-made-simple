#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

KUBECONFIG=$(yq e .clusters.build_cluster.k8s_info.kubeconfig $PARAMS_YAML)

information "Deploying workload tanzu-java-web-app"

tanzu apps workload apply tanzu-java-web-app \
  --git-repo https://github.com/pvtl-pre/tanzu-java-web-app.git \
  --git-branch main \
  --type web \
  --label app.kubernetes.io/part-of=tanzu-java-web-app \
  --label apps.tanzu.vmware.com/has-tests=true \
  --param-yaml testing_pipeline_matching_labels='{"apps.tanzu.vmware.com/language":"java", "apps.tanzu.vmware.com/pipeline":"test"}' \
  --namespace default \
  --yes \
  --kubeconfig $KUBECONFIG

information "Deploying workload python-function"

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
  --kubeconfig $KUBECONFIG
