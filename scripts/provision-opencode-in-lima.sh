#!/usr/bin/env bash
# Install the pinned OpenCode CLI and write only the two required provider
# credentials in the Lima guest.  The host .env is never committed or copied
# into a Docker image; this is a deliberately explicit VM provisioning step.
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repo_root="$(cd "$project_root/../.." && pwd)"
vm_ssh_config="${LIMA_SSH_CONFIG:-$HOME/.lima/nooa-swarm/ssh.config}"
guest="lima-nooa-swarm"
guest_project="workspace/nooa-deep-research"

if [[ ! -f "$repo_root/.env" ]]; then
  echo "Expected secret file $repo_root/.env" >&2
  exit 1
fi

ssh -F "$vm_ssh_config" "$guest" "mkdir -p '$guest_project' && chmod 700 '$guest_project'"
rsync -a -e "ssh -F $vm_ssh_config" "$repo_root/.env" "$guest:$guest_project/.env"
ssh -F "$vm_ssh_config" "$guest" "chmod 600 '$guest_project/.env'"

ssh -F "$vm_ssh_config" "$guest" "bash -s -- '$guest_project'" <<'REMOTE'
set -euo pipefail
export PATH="$HOME/.local/bin:$HOME/.bun/bin:$PATH"
cd "$1"
mise exec -- npm install --global opencode-ai@1.18.9
global_root="$(mise exec -- npm root --global)"
global_prefix="$(mise exec -- npm prefix --global)"
case "$(uname -m)" in
  aarch64|arm64) platform_package="opencode-linux-arm64" ;;
  *) echo "Unsupported Lima architecture: $(uname -m)" >&2; exit 1 ;;
esac
binary_source="$global_root/opencode-ai/node_modules/$platform_package/bin/opencode"
test -x "$binary_source"
# npm 11 can leave the OpenCode package's postinstall pending.  The optional
# ARM package is present, so install its verified executable and global shim
# explicitly instead of relying on npm's interactive approval mechanism.
install -m 755 "$binary_source" "$global_root/opencode-ai/bin/opencode.exe"
ln -sfn "../lib/node_modules/opencode-ai/bin/opencode.exe" "$global_prefix/bin/opencode"
set -a
. ./.env
set +a
: "${OPENCODE_API_KEY:?OPENCODE_API_KEY is required}"
mkdir -p "$HOME/.local/share/opencode"
umask 077
mise exec -- node <<'NODE'
const fs = require("fs");
const key = process.env.OPENCODE_API_KEY;
fs.writeFileSync(
  process.env.HOME + "/.local/share/opencode/auth.json",
  JSON.stringify({
    "opencode-go": { type: "api", key },
    opencode: { type: "api", key },
  }, null, 2) + "\n",
  { mode: 0o600 },
);
NODE
mise exec -- opencode --version
mise exec -- opencode providers list
REMOTE
