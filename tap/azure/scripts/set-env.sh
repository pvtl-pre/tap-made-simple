#!/bin/bash
set -e -o pipefail

: ${PARAMS_YAML?"Need to set PARAMS_YAML environment variable"}

# Give some information timestamps to know how long things take
echo $(date)