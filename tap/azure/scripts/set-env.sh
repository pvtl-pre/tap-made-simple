#!/bin/bash
set -e -o pipefail

: ${PARAMS_YAML?"Need to set PARAMS_YAML environment variable"}

information () {
  RED='\033[0;31m'
  NO_COLOR='\033[0m'

  echo -e "${RED}##############################################################################"
  echo -e "$@"
  echo -e "##############################################################################${NO_COLOR}"
  echo ""
}

# Give some information timestamps to know how long things take
information $(date)