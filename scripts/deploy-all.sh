#!/bin/bash
set -e -o pipefail

TKG_LAB_SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source $TKG_LAB_SCRIPTS/set-env.sh

$TKG_LAB_SCRIPTS/01-prep-azure-objects.sh
$TKG_LAB_SCRIPTS/02-deploy-azure-container-registry.sh
$TKG_LAB_SCRIPTS/03-deploy-azure-k8s-clusters.sh

$TKG_LAB_SCRIPTS/install-tap-prereqs.sh

$TKG_LAB_SCRIPTS/install-tap-profiles.sh

$TKG_LAB_SCRIPTS/install-tap-dev-namespace.sh
$TKG_LAB_SCRIPTS/install-tap-scan-policies.sh
$TKG_LAB_SCRIPTS/install-tap-pipelines.sh

$TKG_LAB_SCRIPTS/deploy-workloads.sh

$TKG_LAB_SCRIPTS/configure-dns.sh
