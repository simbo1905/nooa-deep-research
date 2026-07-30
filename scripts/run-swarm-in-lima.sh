#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
"$project_root/scripts/sync-to-lima.sh"

exec limactl shell nooa-swarm -- zsh -lc '
  export PATH="$HOME/.local/bin:$PATH"
  cd "$HOME/workspace/nooa-deep-research"
  mise exec -- env SWARMFORGE_TERMINAL=none SWARMFORGE_PREVENT_SLEEP=0 ./swarm
'
