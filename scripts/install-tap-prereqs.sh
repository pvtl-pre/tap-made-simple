#!/bin/bash
set -e -o pipefail
shopt -s nocasematch;

TKG_LAB_SCRIPTS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source "$TKG_LAB_SCRIPTS/set-env.sh"

$TKG_LAB_SCRIPTS/download-and-install-cluster-essentials.sh

$TKG_LAB_SCRIPTS/download-and-install-tanzu-cli.sh
