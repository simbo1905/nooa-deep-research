# NOOA Deep Research

This is an independent project repository that uses SwarmForge as an upstream
launcher/template. It does not modify or need a fork of `unclebob/swarm-forge`.

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
