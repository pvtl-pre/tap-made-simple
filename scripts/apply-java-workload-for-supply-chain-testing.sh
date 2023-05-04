#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

BUILD_CLUSTER_KUBECONFIG=$(yq e .clusters.build_cluster.k8s_info.kubeconfig $PARAMS_YAML)
RUN_CLUSTER_COUNT=$(yq e '.clusters.run_clusters | length' $PARAMS_YAML)

information "Updating workload tanzu-java-web-app for the testing supply chain on the Build Cluster"

tanzu apps workload apply tanzu-java-web-app \
  --label apps.tanzu.vmware.com/has-tests=true \
  --param-yaml testing_pipeline_matching_labels='{"apps.tanzu.vmware.com/language":"java", "apps.tanzu.vmware.com/pipeline":"test"}' \
  -n product-team1 \
  --yes \
  --kubeconfig $BUILD_CLUSTER_KUBECONFIG

# information "Creating workload python-function on the Build Cluster"

# tanzu apps workload apply python-function \
#   --label apps.tanzu.vmware.com/has-tests=true \
#   --param-yaml testing_pipeline_matching_labels='{"apps.tanzu.vmware.com/language":"python", "apps.tanzu.vmware.com/pipeline":"test"}' \
#   -n product-team1 \
#   --build-env BP_FUNCTION=func.main \
#   --yes \
#   --kubeconfig $BUILD_CLUSTER_KUBECONFIG
