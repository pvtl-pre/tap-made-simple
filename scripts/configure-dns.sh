#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

TKG_LAB_SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$TKG_LAB_SCRIPTS/set-env.sh"

DNS_AUTO_CONFIGURE=$(yq e .azure.dns.auto_configure $PARAMS_YAML)

if [[ $DNS_AUTO_CONFIGURE == true ]]; then
  $TKG_LAB_SCRIPTS/configure-dns-automatically.sh
else
  $TKG_LAB_SCRIPTS/configure-dns-manually.sh
fi
