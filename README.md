# NOOA Deep Research

This is an independent project repository that uses SwarmForge as an upstream
launcher/template. It does not modify or need a fork of `unclebob/swarm-forge`.
By default its launcher downloads shared scripts from
`simbo1905/swarm-forge:simbo1905`; set `SWARMFORGE_SCRIPTS_URL` or
`SWARMFORGE_SCRIPTS_BRANCH` to test another revision.

## Map

```
your fork of unclebob/swarm-forge (branch: simbo1905)
  └─ shared SwarmForge launcher and generic scripts
       └─ this repository: NOOA deep-research project configuration
            ├─ design/validation: Promptfoo frozen fixtures and gates D1, D3, D4
            ├─ implementation: NOOA Python agent and deterministic adapters
            ├─ deployment: rsync → Lima VM `nooa-swarm`
            ├─ instantiation: a new ResearchRun with explicit provider adapters
            └─ runtime: persisted run state, Tavily captures, page cache, report
```

The SwarmForge fork is infrastructure. This repository is the product. Keep
their histories and remotes separate.

## Configuration boundaries

- Commit this repository: roles, constitution, Promptfoo fixtures, the NOOA
  seed, and Lima sync/run scripts.
- Do not commit: `.env`, Lima/mise/tmux/Codex/Claude authentication state,
  `.swarmforge/`, `.worktrees/`, generated reports, or `.tmp/` release copies.
- The Lima guest is `nooa-swarm`; it has no host mounts. Synchronize with the
  provided rsync scripts. `run-swarm-in-lima.sh` disables only SwarmForge's
  unsupported `systemd-inhibit` wrapper.

## Required guest tools

`mise.toml` pins Python 3.13.14, Java, and Node. Run Python through `uv` and
Promptfoo through Bun. SwarmForge roles run headlessly through project-local
Codex and Claude shims; they use `codex exec` and `claude --print` respectively.

## Execution order

Run the frozen Promptfoo gates first, then the seed NOOA smoke, before any
bounded live Tavily run. The authoritative gate definitions are in
`swarmforge/constitution/articles/project.prompt`.

## Resumability stretch goal

The first runnable agent will persist a versioned JSON `ResearchRunState` after
each phase and can rehydrate it in a new process. That is safer and more stable
than persisting a Python/LLM object with pickle. A later optional Jupyter or
service process may keep a live agent object in memory, but restart/resume must
always work from the persisted state and cache.

## OpenCode backend provisioning

The OpenCode backend is intentionally provisioned in the Lima guest instead
of inheriting an ambient Mac login. From the Mac host run:

```bash
./scripts/provision-opencode-in-lima.sh
```

It installs OpenCode 1.18.9 into the project-pinned mise Node runtime and
creates `~/.local/share/opencode/auth.json` in Lima with two entries from the
single uncommitted root `OPENCODE_API_KEY`: `opencode-go` for Go and `opencode`
for Zen. A role chooses a provider/model in `swarmforge.conf`, for example:

```text
window coder opencode coder task --model opencode-go/qwen3.7-plus
window refactorer opencode refactorer task --model opencode/kimi-k3
```

Run `mise exec -- opencode models opencode-go --refresh` and
`mise exec -- opencode models opencode --refresh` in Lima before selecting a
model, because the provider catalogues change over time.
