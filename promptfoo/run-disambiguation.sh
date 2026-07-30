#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
set -a
source "${ENV_FILE:-$project_root/../../.env}"
set +a
export OPENAI_API_KEY="$SCW_SECRET_KEY"

cd "$project_root/promptfoo"
capture="$(jq -c . fixtures/swarmforge-disambiguation.json)"
exec bunx --yes promptfoo@0.121.19 eval --config promptfooconfig.yaml --no-share \
  --var "tavily_capture=$capture" "$@"
