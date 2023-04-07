#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

DNS_AUTO_CONFIGURE=$(yq e .azure.dns.auto_configure $PARAMS_YAML)

if [[ $DNS_AUTO_CONFIGURE == true ]]; then
  $SCRIPTS/configure-dns-automatically.sh
else
  $SCRIPTS/configure-dns-manually.sh
fi
