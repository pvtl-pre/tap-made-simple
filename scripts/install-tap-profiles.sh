#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

TKG_LAB_SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$TKG_LAB_SCRIPTS/set-env.sh"

$TKG_LAB_SCRIPTS/install-tap-package-repository.sh

$TKG_LAB_SCRIPTS/install-tap-components-for-view-cluster-visibility.sh

$TKG_LAB_SCRIPTS/install-cert.sh

$TKG_LAB_SCRIPTS/install-tap-view-profile.sh

$TKG_LAB_SCRIPTS/install-tap-build-or-iterate-profile.sh

$TKG_LAB_SCRIPTS/install-tap-run-profile.sh

$TKG_LAB_SCRIPTS/install-cert-delegation.sh

$TKG_LAB_SCRIPTS/reconcile-tap-install.sh
