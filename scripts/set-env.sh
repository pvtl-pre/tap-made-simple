#!/bin/bash
set -e -o pipefail

information() {
  RED='\033[0;31m'
  NO_COLOR='\033[0m'

  echo -e "${RED}##############################################################################"
  echo -e "$@"
  echo -e "##############################################################################${NO_COLOR}"
  echo ""
}

: ${PARAMS_YAML?"Need to set PARAMS_YAML environment variable"}

# Copy params file to the generated dir and use that instead
mkdir -p generated

if [[ ! -f "generated/params.yaml" ]]; then
  cp -p $PARAMS_YAML generated/params.yaml
fi

PARAMS_YAML="generated/params.yaml"
