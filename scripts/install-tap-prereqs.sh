#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

$SCRIPTS/download-and-install-cluster-essentials.sh

$SCRIPTS/download-and-install-tanzu-cli.sh
