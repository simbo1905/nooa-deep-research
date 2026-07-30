#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
vm_ssh_config="${LIMA_SSH_CONFIG:-$HOME/.lima/nooa-swarm/ssh.config}"

rsync -a \
  --exclude='.env' --exclude='.git' --exclude='.swarmforge' \
  --exclude='.worktrees' --exclude='swarmforge/scripts' --exclude='.tmp' \
  -e "ssh -F $vm_ssh_config" \
  lima-nooa-swarm:workspace/nooa-deep-research/ "$project_root/"
