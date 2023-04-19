#!/bin/bash
set -e -o pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source $SCRIPTS/set-env.sh

ITERATE_CLUSTER_INGRESS_DOMAIN=$(yq e .clusters.iterate_cluster.ingress_domain $PARAMS_YAML)
ITERATE_CLUSTER_KUBECONFIG=$(yq e .clusters.iterate_cluster.k8s_info.kubeconfig $PARAMS_YAML)
ITERATE_CLUSTER_NAME=$(yq e .clusters.iterate_cluster.k8s_info.name $PARAMS_YAML)
RUN_CLUSTER_COUNT=$(yq e '.clusters.run_clusters | length' $PARAMS_YAML)

ITERATE_PROFILE="generated/profiles/$ITERATE_CLUSTER_NAME.yaml"

information "Updating generated profiles with cloud native runtimes configuration"

ytt -f "$PARAMS_YAML" -v ingress_domain=$ITERATE_CLUSTER_INGRESS_DOMAIN -f $ITERATE_PROFILE -f profile-overlays/cloud-native-runtimes.yaml --output-files generated/profiles

for ((i = 0; i < $RUN_CLUSTER_COUNT; i++)); do
  RUN_CLUSTER_KUBECONFIG=$(yq e .clusters.run_clusters[$i].k8s_info.kubeconfig $PARAMS_YAML)
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].k8s_info.name $PARAMS_YAML)

  RUN_PROFILE="generated/profiles/$RUN_CLUSTER_NAME.yaml"
  RUN_CLUSTER_INGRESS_DOMAIN=$(yq e .clusters.run_clusters[$i].ingress_domain $PARAMS_YAML)

  ytt -f "$PARAMS_YAML" -v ingress_domain=$RUN_CLUSTER_INGRESS_DOMAIN -f $RUN_PROFILE -f profile-overlays/cloud-native-runtimes.yaml --output-files generated/profiles
done

$SCRIPTS/install-tap-iterate-profile.sh
$SCRIPTS/install-tap-run-profiles.sh

$SCRIPTS/reconcile-tap-install-for-iterate-cluster.sh
$SCRIPTS/reconcile-tap-install-for-run-clusters.sh
