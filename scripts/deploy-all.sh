#!/bin/bash
set -e -o pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source $SCRIPTS/set-env.sh

$SCRIPTS/01-prep-azure-objects.sh
$SCRIPTS/02-deploy-azure-container-registry.sh
$SCRIPTS/03-deploy-azure-k8s-clusters.sh

$SCRIPTS/install-tap-prereqs.sh

$SCRIPTS/install-minimal-tap-profiles.sh

$SCRIPTS/install-load-balancer.sh
$SCRIPTS/configure-dns.sh

$SCRIPTS/install-tap-gui-database.sh

$SCRIPTS/install-tap-supply-chain-basic.sh

$SCRIPTS/install-tap-components-to-view-cluster-resources.sh

# $SCRIPTS/install-cert.sh

# $SCRIPTS/install-cert-delegation.sh

# $SCRIPTS/install-tap-dev-namespace.sh
# $SCRIPTS/install-tap-scan-policies.sh
# $SCRIPTS/install-tap-pipelines.sh

# $SCRIPTS/deploy-workloads.sh
