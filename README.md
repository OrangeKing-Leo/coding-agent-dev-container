# coding-agent-dev-container

Dev Container **templates** for running coding agents in a hardened sandbox.

Backed by the custom features at
[OrangeKing-Leo/devcontainer-features](https://github.com/OrangeKing-Leo/devcontainer-features).

## Templates

| ID | Stack | Docs |
|---|---|---|
| `claude-code-sandbox` | `claude-code` + `codegraph` (wired to claude-code) + `harden-sandbox` + `frontend-extensions` | [README](templates/src/claude-code-sandbox/README.md) |
| `codex-sandbox` | `codex` + `codegraph` (wired to codex) + `harden-sandbox` + `frontend-extensions` | [README](templates/src/codex-sandbox/README.md) |

Both are based on `mcr.microsoft.com/devcontainers/base:debian` and ship
with `cap-drop=ALL` + `no-new-privileges`, plus named-volume mounts for
shell history and the agent's home directory.

## Apply a template locally

```bash
npm i -g @devcontainers/cli
devcontainer templates apply \
  --template-id ghcr.io/orangeking-leo/coding-agent-dev-container/claude-code-sandbox \
  --workspace-folder .
```

(Replace `claude-code-sandbox` with `codex-sandbox` for the Codex
variant.) See each template's README for options, seed layout, and
what's inside.

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
