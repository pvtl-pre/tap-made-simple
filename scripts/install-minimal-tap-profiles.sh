#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

$SCRIPTS/install-tap-package-repository.sh

$SCRIPTS/generate-profiles-from-templates.sh

$SCRIPTS/install-tap-view-profile.sh

$SCRIPTS/install-tap-build-profile.sh

$SCRIPTS/install-tap-run-profiles.sh

$SCRIPTS/install-tap-iterate-profile.sh
