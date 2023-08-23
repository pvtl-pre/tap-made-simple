#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

BUILD_CLUSTER_NAME=$(yq e .clusters.build_cluster.name $PARAMS_YAML)
GITOPS_REPO_DIR="generated/gitops-repo"
ITERATE_CLUSTER_NAME=$(yq e .clusters.iterate_cluster.name $PARAMS_YAML)
RUN_CLUSTER_COUNT=$(yq e '.clusters.run_clusters | length' $PARAMS_YAML)
VIEW_CLUSTER_NAME=$(yq e .clusters.view_cluster.name $PARAMS_YAML)

TAP_VERSION_YAML="tap-version.yaml"
# NOTE: this var intentionally has a "Z" to avoid conflicts when running ./setup-repo.sh
export TAP_VERSIONZ=$(yq e .tap.version $TAP_VERSION_YAML)

function setup() {
  CLUSTER_NAME=$1

  (
    cd $GITOPS_REPO_DIR

    ./setup-repo.sh $CLUSTER_NAME sops
  )
}

function configure() {
  CLUSTER_NAME=$1

  (
    cd $GITOPS_REPO_DIR/clusters/$CLUSTER_NAME

    ./tanzu-sync/scripts/configure.sh

    yq e -i '.tap_install.version.package_version = env(TAP_VERSIONZ)' "cluster-config/values/tap-install-values.yaml"
    yq e -i '.tap_install.version.package_repo_bundle_tag = env(TAP_VERSIONZ)' "cluster-config/values/tap-install-values.yaml"
  )
}

information "Adding clusters to the GitOps Repo"

setup $BUILD_CLUSTER_NAME
setup $ITERATE_CLUSTER_NAME
setup $VIEW_CLUSTER_NAME

for ((i = 0; i < $RUN_CLUSTER_COUNT; i++)); do
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].name $PARAMS_YAML)

  setup $RUN_CLUSTER_NAME
done

$SCRIPTS/commit-gitops-repo.sh "Adding clusters"

information "Configuring clusters to the GitOps Repo"

configure $BUILD_CLUSTER_NAME
configure $ITERATE_CLUSTER_NAME
configure $VIEW_CLUSTER_NAME

for ((i = 0; i < $RUN_CLUSTER_COUNT; i++)); do
  RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].name $PARAMS_YAML)

  configure $RUN_CLUSTER_NAME
done

$SCRIPTS/commit-gitops-repo.sh "Configuring clusters"
