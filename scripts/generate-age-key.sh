#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

AGE_KEY_PATH=$(yq e .gitops.age_key_path $PARAMS_YAML)

if [[ -n "$AGE_KEY_PATH" ]]; then
  if [[ -f "$AGE_KEY_PATH" ]]; then
    information "Skipping age key generation since it exists"
  else
    information "Age key does not exist at $AGE_KEY_PATH"
    exit 1
  fi
 else
  export AGE_KEY_PATH="generated/age-key.txt"

  information "Generating age key at $AGE_KEY_PATH"

  age-keygen -o $AGE_KEY_PATH

  yq e -i '.gitops.age_key_path = env(AGE_KEY_PATH)' "$PARAMS_YAML"
fi
