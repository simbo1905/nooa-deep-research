#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
set -a
source "${ENV_FILE:-$project_root/../../.env}"
set +a
export OPENAI_API_KEY="$SCW_SECRET_KEY"

cd "$project_root/promptfoo"
fixture="$(jq -c . fixtures/swarmforge-candidate-selection.json)"
exec bunx --yes promptfoo@0.121.19 eval --config candidate-selection-promptfooconfig.yaml --no-share \
  --var "user_question=$(jq -r .user_question <<<"$fixture")" \
  --var "resolved_entity=$(jq -r .resolved_entity <<<"$fixture")" \
  --var "all_subtopics=$(jq -c .all_subtopics <<<"$fixture")" \
  --var "candidate_results=$(jq -c .candidate_results <<<"$fixture")" "$@"
