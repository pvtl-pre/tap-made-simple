#!/bin/bash
set -e -o pipefail

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $TKG_LAB_SCRIPTS/set-env.sh

$TKG_LAB_SCRIPTS/01-prep-azure-objects.sh
$TKG_LAB_SCRIPTS/02-deploy-azure-container-registry.sh
$TKG_LAB_SCRIPTS/03-deploy-azure-k8s-cluster.sh

$TKG_LAB_SCRIPTS/tap-prereqs-install.sh
$TKG_LAB_SCRIPTS/tap-metadata-store-install.sh
$TKG_LAB_SCRIPTS/tap-profiles-install.sh
$TKG_LAB_SCRIPTS/tap-dev-namespace-install.sh