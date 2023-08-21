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

function configure() {
  CLUSTER_NAME=$1

  (
    cd clusters/$CLUSTER_NAME

    ./tanzu-sync/scripts/configure.sh

    yq e -i '.tap_install.version.package_version = env(TAP_VERSIONZ)' "cluster-config/values/tap-install-values.yaml"
    yq e -i '.tap_install.version.package_repo_bundle_tag = env(TAP_VERSIONZ)' "cluster-config/values/tap-install-values.yaml"
  )
}

(
  cd $GITOPS_REPO_DIR

  information "Adding clusters to the GitOps Repo"

  ./setup-repo.sh $BUILD_CLUSTER_NAME sops
  ./setup-repo.sh $ITERATE_CLUSTER_NAME sops
  ./setup-repo.sh $VIEW_CLUSTER_NAME sops

  for ((i = 0; i < $RUN_CLUSTER_COUNT; i++)); do
    RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].name ../../$PARAMS_YAML)

    ./setup-repo.sh $RUN_CLUSTER_NAME sops
  done

  git add .
  git status
  git diff --staged --quiet || git commit -m "Adding clusters to the GitOps Repo"
  git push
  
  information "Configuring clusters to the GitOps Repo"

  configure $BUILD_CLUSTER_NAME
  configure $ITERATE_CLUSTER_NAME
  configure $VIEW_CLUSTER_NAME

  for ((i = 0; i < $RUN_CLUSTER_COUNT; i++)); do
    RUN_CLUSTER_NAME=$(yq e .clusters.run_clusters[$i].name ../../$PARAMS_YAML)

    configure $RUN_CLUSTER_NAME
  done

  git add .
  git status
  git diff --staged --quiet || git commit -m "Configuring clusters to the GitOps Repo"
  git push
)
