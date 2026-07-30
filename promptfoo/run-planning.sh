#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
set -a
source "${ENV_FILE:-$project_root/../../.env}"
set +a
export OPENAI_API_KEY="$SCW_SECRET_KEY"

cd "$project_root/promptfoo"
planning_input="$(jq -c . fixtures/swarmforge-planning-input.json)"
exec bunx --yes promptfoo@0.121.19 eval --config planning-promptfooconfig.yaml --no-share \
  --var "planning_input=$planning_input" "$@"
