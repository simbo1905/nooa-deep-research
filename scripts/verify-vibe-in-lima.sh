#!/usr/bin/env bash
# Verify only the non-secret facts needed before a Vibe-backed swarm.  Do not
# read, copy, print, or synchronise ~/.vibe files: they may contain credentials
# and are owned by the Lima guest.
set -euo pipefail

vm_ssh_config="${LIMA_SSH_CONFIG:-$HOME/.lima/nooa-swarm/ssh.config}"

ssh -F "$vm_ssh_config" lima-nooa-swarm 'bash -s' <<'REMOTE'
set -euo pipefail
vibe_bin="${VIBE_BIN:-$HOME/.local/bin/vibe}"

if [[ ! -x "$vibe_bin" ]]; then
  echo "Vibe executable not found at $vibe_bin" >&2
  exit 127
fi

echo "Vibe version: $($vibe_bin --version)"

# This is a presence check only.  It intentionally does not inspect the file
# because Vibe's authentication material is secret guest-local state.
if [[ -s "$HOME/.vibe/.env" ]]; then
  echo "Vibe authentication state: present (not inspected)"
else
  echo "Vibe authentication state: not detected; run vibe --setup in Lima" >&2
  exit 1
fi
REMOTE
