#!/usr/bin/env bash
# Start a deliberately non-destructive Vibe -> OpenCode two-pack inside a
# detached tmux driver. Vibe is the short-lived programmatic sender; OpenCode
# stays interactive as the receiver and cleanup owner.
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -n "$(git -C "$project_root" status --porcelain)" ]]; then
  echo "Refusing to clear generated swarm state: commit or stash project changes first." >&2
  exit 1
fi
ahead="$(git -C "$project_root" rev-list --count '@{upstream}..HEAD')"
if [[ "$ahead" != 0 ]]; then
  echo "Refusing to run: project commits have not been pushed to its upstream." >&2
  exit 1
fi

"$project_root/scripts/sync-to-lima.sh"

limactl shell nooa-swarm -- bash -lc '
  set -euo pipefail
  export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"
  cd "$HOME/workspace/nooa-deep-research"
  if [[ -f .swarmforge/tmux-socket ]]; then
    tmux -S "$(cat .swarmforge/tmux-socket)" kill-server 2>/dev/null || true
  fi
  touch .swarmforge/daemon/stop 2>/dev/null || true
  sleep 2
  rm -rf .swarmforge .worktrees swarmforge/scripts
  rm -f /tmp/nooa-vibe-smoke.log
  tmux kill-session -t nooa-vibe-smoke 2>/dev/null || true
  tmux new-session -d -s nooa-vibe-smoke \
    "SWARMFORGE_TERMINAL=none SWARMFORGE_PREVENT_SLEEP=0 SWARMFORGE_CONFIG=smoke-vibe.conf ./swarm > /tmp/nooa-vibe-smoke.log 2>&1"
  echo "Driver: tmux attach -t nooa-vibe-smoke"
  echo "Bootstrap log: /tmp/nooa-vibe-smoke.log"
  echo "Inspect: tmux ls; Vibe output is .swarmforge/agent-logs/smoke-vibe-specifier.log"
'
