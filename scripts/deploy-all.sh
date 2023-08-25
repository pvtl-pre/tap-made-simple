#!/bin/bash
set -e -o pipefail

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source $SCRIPTS/set-env.sh

$SCRIPTS/01-prep-azure-objects.sh
$SCRIPTS/02-deploy-azure-container-registry.sh
$SCRIPTS/03-deploy-azure-k8s-clusters.sh

$SCRIPTS/download-and-install-cluster-essentials.sh
$SCRIPTS/download-and-install-tanzu-cli.sh
$SCRIPTS/download-gitops-ri.sh
$SCRIPTS/generate-age-key.sh

$SCRIPTS/initialize-gitops-repo.sh
$SCRIPTS/setup-and-configure-gitops-repo.sh
$SCRIPTS/add-tanzu-sync-values.sh
$SCRIPTS/add-tap-values.sh
$SCRIPTS/deploy-tanzu-sync.sh
$SCRIPTS/allow-tap-gui-to-view-resources.sh

# $SCRIPTS/apply-load-balancer.sh
# $SCRIPTS/configure-dns.sh

# $SCRIPTS/apply-tap-gui-auth.sh
# $SCRIPTS/apply-tap-gui-database.sh

# $SCRIPTS/apply-supply-chain-basic.sh
# $SCRIPTS/apply-dev-namespace-legacy.sh

# $SCRIPTS/apply-application-accelerator.sh
# $SCRIPTS/apply-tap-gui-catalogs.sh
# $SCRIPTS/apply-application-live-view.sh
# $SCRIPTS/apply-java-workload.sh

# $SCRIPTS/apply-pipelines.sh
# $SCRIPTS/apply-supply-chain-testing.sh
# $SCRIPTS/apply-java-workload-for-supply-chain-testing.sh

# $SCRIPTS/apply-scan-policies.sh
# $SCRIPTS/apply-scanner-access-to-store-scan-results.sh
# $SCRIPTS/apply-tap-gui-access-to-scan-results.sh
# $SCRIPTS/apply-supply-chain-testing-and-scanning.sh

# $SCRIPTS/apply-learning-center.sh

# $SCRIPTS/apply-cloud-native-runtimes.sh
# $SCRIPTS/apply-cert.sh
