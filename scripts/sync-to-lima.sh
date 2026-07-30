#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
vm_ssh_config="${LIMA_SSH_CONFIG:-$HOME/.lima/nooa-swarm/ssh.config}"

rsync -a --delete \
  --exclude='.env' --exclude='.git' --exclude='.swarmforge' \
  --exclude='.worktrees' --exclude='swarmforge/scripts' \
  --exclude='.tmp' --exclude='artifacts' --exclude='reports' \
  -e "ssh -F $vm_ssh_config" \
  "$project_root/" lima-nooa-swarm:workspace/nooa-deep-research/

rsync -a --delete --exclude='.git' -e "ssh -F $vm_ssh_config" \
  "$project_root/../../.tmp/labs-OO-Agents-v0.0.8/" \
  lima-nooa-swarm:workspace/nooa-deep-research/.tmp/labs-OO-Agents-v0.0.8/
