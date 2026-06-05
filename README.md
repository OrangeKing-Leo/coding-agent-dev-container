# coding-agent-dev-container

Dev Container **templates** for running coding agents in a hardened sandbox.

Backed by the custom features at
[OrangeKing-Leo/devcontainer-features](https://github.com/OrangeKing-Leo/devcontainer-features).

## Templates

| ID | Stack |
|---|---|
| [`claude-code-sandbox`](templates/src/claude-code-sandbox) | `claude-code` + `codegraph` (wired to claude-code) + `harden-sandbox` + `frontend-extensions` |
| [`codex-sandbox`](templates/src/codex-sandbox) | `codex` + `codegraph` (wired to codex) + `harden-sandbox` + `frontend-extensions` |

Both are based on `mcr.microsoft.com/devcontainers/base:debian` and ship with
`cap-drop=ALL` + `no-new-privileges`, plus named-volume mounts for shell history
and the agent's home directory.

## Apply a template locally

```bash
npm i -g @devcontainers/cli
devcontainer templates apply \
  --template-id ghcr.io/orangeking-leo/coding-agent-dev-container/claude-code-sandbox \
  --workspace-folder .
```

(Replace `claude-code-sandbox` with `codex-sandbox` for the Codex variant.)

## Publish

Use the official `devcontainers/action` GitHub Action with
`publish-templates: "true"` and `base-path-to-templates: templates/src`.
