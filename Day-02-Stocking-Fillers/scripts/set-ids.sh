#!/bin/bash
# Fills in the GitHub raw base URL and the CloudLabs validation step IDs.
# Usage (from the package root):
#   ./scripts/set-ids.sh <github-owner>/<repo> [branch] \
#       EX1=<step-id> EX2=<step-id> EX3=<step-id> EX4=<step-id> EX5=<step-id> EX6=<step-id>
# Run it once with only the repo to set URLs, and again with the step IDs once
# the validation steps exist in the CloudLabs template.
set -euo pipefail
REPO="${1:?owner/repo required}"; shift
BRANCH="main"
if [[ $# -gt 0 && "$1" != *=* ]]; then BRANCH="$1"; shift; fi
RAW="https://raw.githubusercontent.com/${REPO}/refs/heads/${BRANCH}"
FILES=$(grep -rl --exclude-dir=.git --exclude=set-ids.sh -e '{{REPO_RAW}}' -e '{{STEP_EX' . || true)
for f in $FILES; do sed -i "s#{{REPO_RAW}}#${RAW}#g" "$f"; done
for kv in "$@"; do
  k="${kv%%=*}"; v="${kv#*=}"
  for f in $(grep -rl --exclude-dir=.git --exclude=set-ids.sh "{{STEP_${k}}}" . || true); do sed -i "s#{{STEP_${k}}}#${v}#g" "$f"; done
done
echo "Raw base: $RAW"
echo "Still to fill:"; grep -rn --exclude-dir=.git --exclude=set-ids.sh -e '{{REPO_RAW}}' -e '{{STEP_EX' . || echo "  nothing - ready to publish"
