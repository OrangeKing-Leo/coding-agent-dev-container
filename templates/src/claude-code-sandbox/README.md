# Claude Code Sandbox

Hardened Debian dev container with the Claude Code CLI pre-installed and
wired to a local [CodeGraph](https://www.npmjs.com/package/@colbymchenry/codegraph)
MCP server.

## Apply

```bash
npx -y @devcontainers/cli templates apply \
  --template-id ghcr.io/orangeking-leo/coding-agent-dev-container/claude-code-sandbox \
  --workspace-folder .
```

## Options

| Option | Default | Description |
|---|---|---|
| `nodeVersion` | `20` | Major Node.js version installed by the CLI features. |
| `claudeCodeVersion` | `latest` | Version of `@anthropic-ai/claude-code` (npm dist-tag or semver). |
| `codegraphVersion` | `latest` | Version of `@colbymchenry/codegraph` (npm dist-tag or semver). |

## Features installed

Backed by [`OrangeKing-Leo/devcontainer-features`](https://github.com/OrangeKing-Leo/devcontainer-features):

- `harden-sandbox` — strips host credential env vars, forces
  `credential.helper=/bin/false`, persists shell history, disables core
  dumps, sets `git safe.directory='*'`.
- `claude-code` — installs Node + the Claude Code CLI, registers the
  `ccd` alias (`claude --dangerously-skip-permissions`).
- `codegraph` — installs CodeGraph and its `cgii` / `cgs` aliases.
- `frontend-extensions` — VS Code extensions for Vue, React, Tailwind.

## Sandbox guarantees

The container runs with `cap-drop=ALL` (only `CHOWN`, `DAC_OVERRIDE`,
`FOWNER`, `SETUID`, `SETGID` re-added for user/file ops) plus
`no-new-privileges`. Two named volumes persist agent state across
rebuilds:

| Volume | Mount | Purpose |
|---|---|---|
| `claude-code-config-${devcontainerId}` | `/home/vscode/.claude` | Plugins, agents, skills, MCP servers. |
| `claude-code-bashhistory-${devcontainerId}` | `/commandhistory` | Shell history. |

Anything written outside `/workspace` and these volumes is discarded on
rebuild.

## Seed (`.devcontainer/seed/`)

`postCreateCommand` runs `seed/install.sh` on first start. It is
idempotent — re-running never overwrites existing config.

| File | Purpose |
|---|---|
| `CLAUDE.md` | Seeded to `~/.claude/CLAUDE.md` if missing. |
| `mcp-servers.json` | Deep-merged into `~/.claude.json` (existing keys win). |
| `marketplaces.txt` | One marketplace per line; added via `claude plugin marketplace add`. |
| `plugins.txt` | One `plugin@marketplace` per line; installed via `claude plugin install`. |
| `commands/`, `agents/`, `skills/` | Copied per-file into `~/.claude/<dir>/`, skipping files that already exist. |
| `gitignore.append` | Lines appended to the project's `.gitignore` (in `/workspace`) if not already present. |

Edit these files in your project's `.devcontainer/seed/` after applying
the template to customize what each new container starts with.

### `gitignore.append` details

Each non-empty, non-comment line is matched against the project's
`/workspace/.gitignore` with exact-line equality (`grep -qxF`). Missing
lines are appended under a one-time header
`# Added by claude-code-sandbox dev container seed`. The script never
removes or rewrites existing entries — safe to run on repos that
already have a hand-tuned `.gitignore`. Default entries:

- `.claude/settings.local.json` — per-machine permission overrides
- `.claude/.credentials.json` — local auth token (must never be committed)

Add your own project-specific lines (e.g. `.env.local`, build artifacts)
to that file; they'll be applied on the next container create/rebuild.
