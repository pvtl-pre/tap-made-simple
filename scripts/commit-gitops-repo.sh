#!/bin/bash
set -e -o pipefail
shopt -s nocasematch

SCRIPTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source "$SCRIPTS/set-env.sh"

COMMIT_MSG=$1

GITOPS_REPO_DIR="generated/gitops-repo"

information "Committing GitOps Repo"

(
  cd $GITOPS_REPO_DIR

  git add .
  git status
  git diff --staged --quiet || git commit -m "$COMMIT_MSG"
  git push  
)
