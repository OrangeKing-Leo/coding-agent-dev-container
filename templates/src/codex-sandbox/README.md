# Codex Sandbox

Hardened Debian dev container with the OpenAI Codex CLI pre-installed
and wired to a local [CodeGraph](https://www.npmjs.com/package/@colbymchenry/codegraph)
MCP server.

## Apply

```bash
npm i -g @devcontainers/cli
devcontainer templates apply \
  --template-id ghcr.io/orangeking-leo/coding-agent-dev-container/codex-sandbox \
  --workspace-folder .
```

## Options

| Option | Default | Description |
|---|---|---|
| `nodeVersion` | `20` | Major Node.js version installed by the CLI features. |
| `codexVersion` | `latest` | Version of `@openai/codex` (npm dist-tag or semver). |
| `codegraphVersion` | `latest` | Version of `@colbymchenry/codegraph` (npm dist-tag or semver). |

## Features installed

Backed by [`OrangeKing-Leo/devcontainer-features`](https://github.com/OrangeKing-Leo/devcontainer-features):

- `harden-sandbox` — strips host credential env vars, forces
  `credential.helper=/bin/false`, persists shell history, disables core
  dumps, sets `git safe.directory='*'`.
- `codex` — installs Node + the Codex CLI, registers the `cxd` alias
  (`codex --dangerously-bypass-approvals-and-sandbox`).
- `codegraph` — installs CodeGraph and its `cgii` / `cgs` aliases.
- `frontend-extensions` — VS Code extensions for Vue, React, Tailwind.

## Sandbox guarantees

The container runs with `cap-drop=ALL` (only `CHOWN`, `DAC_OVERRIDE`,
`FOWNER`, `SETUID`, `SETGID` re-added for user/file ops) plus
`no-new-privileges`. Two named volumes persist agent state across
rebuilds:

| Volume | Mount | Purpose |
|---|---|---|
| `codex-config-${devcontainerId}` | `/home/vscode/.codex` | `config.toml`, prompts, auth. |
| `codex-bashhistory-${devcontainerId}` | `/commandhistory` | Shell history. |

Anything written outside `/workspace` and these volumes is discarded on
rebuild.

## Seed (`.devcontainer/seed/`)

`postCreateCommand` runs `seed/install.sh` on first start. It is
idempotent — re-running never overwrites existing config.

| File | Purpose |
|---|---|
| `AGENTS.md` | Seeded to `~/.codex/AGENTS.md` if missing. |
| `mcp-servers.toml` | Each `[mcp_servers.<name>]` block appended to `~/.codex/config.toml` if that header isn't already present. |
| `prompts/` | Copied per-file into `~/.codex/prompts/`, skipping files that already exist. |

Edit these files in your project's `.devcontainer/seed/` after applying
the template to customize what each new container starts with.
