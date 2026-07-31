#!/usr/bin/env bash
# Start a deliberately non-destructive Claude -> OpenCode Go two-pack inside a
# tmux driver.  The driver is detached so callers can inspect the two agent
# sessions and export OpenCode telemetry before ending the swarm.
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
"$project_root/scripts/sync-to-lima.sh"

limactl shell nooa-swarm -- bash -lc '
  set -euo pipefail
  export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"
  cd "$HOME/workspace/nooa-deep-research"
  rm -rf swarmforge/scripts
  tmux kill-session -t nooa-opencode-go-smoke 2>/dev/null || true
  tmux new-session -d -s nooa-opencode-go-smoke \
    "SWARMFORGE_TERMINAL=none SWARMFORGE_PREVENT_SLEEP=0 SWARMFORGE_CONFIG=smoke-opencode-go.conf ./swarm"
  echo "Driver: tmux attach -t nooa-opencode-go-smoke"
  echo "Inspect: tmux ls; OpenCode session export is under ~/.local/share/opencode"
'
