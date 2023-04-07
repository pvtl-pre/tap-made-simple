#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

TKG_LAB_SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$TKG_LAB_SCRIPTS/set-env.sh"

$TKG_LAB_SCRIPTS/install-tap-package-repository.sh

$TKG_LAB_SCRIPTS/generate-profiles-from-templates.sh

$TKG_LAB_SCRIPTS/install-tap-view-profile.sh

$TKG_LAB_SCRIPTS/install-tap-build-profile.sh

$TKG_LAB_SCRIPTS/install-tap-run-profiles.sh

$TKG_LAB_SCRIPTS/install-tap-iterate-profile.sh
