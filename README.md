# coding-agent-dev-container

Dev Container **templates** for running coding agents in a hardened sandbox.

Backed by the custom features at
[OrangeKing-Leo/devcontainer-features](https://github.com/OrangeKing-Leo/devcontainer-features).
Release history: see [CHANGELOG.md](CHANGELOG.md).

## Templates

| ID | Stack | Docs |
|---|---|---|
| `claude-code-sandbox` | `claude-code` + `codegraph` (wired to claude-code) + `harden-sandbox` + `frontend-extensions` | [README](templates/src/claude-code-sandbox/README.md) |
| `codex-sandbox` | `codex` + `codegraph` (wired to codex) + `harden-sandbox` + `frontend-extensions` | [README](templates/src/codex-sandbox/README.md) |

Both are based on `mcr.microsoft.com/devcontainers/base:debian` and ship
with `cap-drop=ALL` + `no-new-privileges`, plus named-volume mounts for
shell history and the agent's home directory.

Each template includes a `.devcontainer/seed/` directory whose
`install.sh` runs once on container creation. It seeds the agent's home
config (`~/.claude` or `~/.codex`), and refreshes the project's
`.gitignore` with agent-specific entries (e.g. local settings, auth
files) — idempotent, only appends what's missing, never removes lines.
See each template's README for the full seed layout.

## Apply a template locally

```bash
npx -y @devcontainers/cli templates apply \
  --template-id ghcr.io/orangeking-leo/coding-agent-dev-container/claude-code-sandbox \
  --workspace-folder .
```

(Replace `claude-code-sandbox` with `codex-sandbox` for the Codex
variant.) See each template's README for options, seed layout, and
what's inside.

## Apply via a coding agent

Paste this prompt into Claude Code / Codex / Cursor / any agent with
shell access, from the target project's root:

> Set up the `claude-code-sandbox` dev container template from
> `ghcr.io/orangeking-leo/coding-agent-dev-container` in this project.
> Run `npx -y @devcontainers/cli templates apply --template-id
> ghcr.io/orangeking-leo/coding-agent-dev-container/claude-code-sandbox
> --workspace-folder .` in the project root, then show me the generated
> `.devcontainer/` layout and summarize what the seed files
> (`CLAUDE.md`, `mcp-servers.json`, `marketplaces.txt`, `plugins.txt`,
> `commands/`, `agents/`, `skills/`, `gitignore.append`) will do on
> first container start so I can customize them before reopening in
> container.

Swap `claude-code-sandbox` → `codex-sandbox` (and `CLAUDE.md` →
`AGENTS.md`, `mcp-servers.json` → `mcp-servers.toml`) for the Codex
variant.

## CI / Release

- [`.github/workflows/test.yaml`](.github/workflows/test.yaml) — on PR
  and `main` push, builds each template end-to-end with
  `devcontainer up` and runs a smoke check (CLI versions + sandbox
  hardening flag).
- [`.github/workflows/release.yaml`](.github/workflows/release.yaml) —
  on `main` push, publishes both templates to GHCR via the official
  `devcontainers/action`.

After the first publish, set each GHCR package's visibility to
**public** on github.com or anonymous `devcontainer templates apply`
will 401.

### Bumping template versions

`devcontainers/action` publishes by version. If you change any
publishable file in a template (anything under `templates/src/<id>/`
except `README.md` / `NOTES.md`) **without** bumping `version` in
`devcontainer-template.json`, the release workflow logs

```
(!) WARNING: Version X.Y.Z already exists, skipping X.Y.Z...
```

and the GHCR `:latest` tag keeps serving the old tarball — your changes
silently never reach users.

To avoid this, this repo ships a pre-commit hook that fails the commit
if a template has staged changes but its version line in
`devcontainer-template.json` wasn't also touched. Enable it once per
clone:

```bash
git config core.hooksPath .githooks
```

You can also run the check manually at any time:

```bash
./scripts/check-template-versions.sh
```

The hook only inspects staged files, so it won't complain about
unrelated working-tree edits.

When you bump the version, also move the relevant entries in
[CHANGELOG.md](CHANGELOG.md) from `[Unreleased]` into a new dated
section.
