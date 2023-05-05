#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

BUILD_CLUSTER_NAME=$(yq e .clusters.build_cluster.name $PARAMS_YAML)
ITERATE_CLUSTER_NAME=$(yq e .clusters.iterate_cluster.name $PARAMS_YAML)
RUN_CLUSTER_COUNT=$(yq e '.clusters.run_clusters | length' $PARAMS_YAML)
VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.name $PARAMS_YAML)

BUILD_PROFILE="generated/profiles/$BUILD_CLUSTER_NAME.yaml"
ITERATE_PROFILE="generated/profiles/$ITERATE_CLUSTER_NAME.yaml"
VIEW_PROFILE="generated/profiles/$VIEW_CLUSTER_NAME.yaml"

information "Generating profiles from templates"

mkdir -p generated/profiles
ytt -f "$PARAMS_YAML" -f profile-templates/view.yaml >$VIEW_PROFILE
ytt -f "$PARAMS_YAML" -f profile-templates/iterate.yaml >$ITERATE_PROFILE
ytt -f "$PARAMS_YAML" -f profile-templates/build.yaml >$BUILD_PROFILE

for ((i = 0; i < $RUN_CLUSTER_COUNT; i++)); do
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].name $PARAMS_YAML)

  RUN_PROFILE="generated/profiles/$RUN_CLUSTER_NAME.yaml"

  ytt --data-value-yaml index=$i -f "$PARAMS_YAML" -f profile-templates/run.yaml >$RUN_PROFILE
done
