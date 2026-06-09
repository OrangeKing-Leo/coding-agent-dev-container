# Changelog

All notable changes to the templates in this repo are documented here.
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
both templates share a single version line so entries below apply to
`claude-code-sandbox` and `codex-sandbox` unless noted otherwise.

## [Unreleased]

## [1.1.0] — 2026-06-09

### Added
- New seed file `gitignore.append` in each template. On first
  container start `install.sh` reads it and appends any missing lines
  (exact-match) to the project's `/workspace/.gitignore` under a
  one-time header. Default entries cover agent-local state that must
  never be committed:
  - `claude-code-sandbox`: `.claude/settings.local.json`,
    `.claude/.credentials.json`
  - `codex-sandbox`: `.codex/auth.json`, `.codex/log/`
- Repo-level pre-commit hook (`.githooks/pre-commit` +
  `scripts/check-template-versions.sh`) that fails the commit when a
  template has publishable changes but `version` in
  `devcontainer-template.json` was not bumped. Enable with
  `git config core.hooksPath .githooks`.
- README install instructions for invoking the template via a coding
  agent (paste-ready prompt).

### Changed
- Install instructions switched from `npm i -g @devcontainers/cli` to
  `npx -y @devcontainers/cli ...` — no global install required.
- Per-template READMEs gained a `gitignore.append details` section
  documenting the append rules and default entries.

## [1.0.0] — 2026-06-05

### Added
- Initial release of two templates on
  `mcr.microsoft.com/devcontainers/base:debian`:
  - `claude-code-sandbox` — Claude Code CLI + CodeGraph MCP +
    `harden-sandbox` + frontend VS Code extensions.
  - `codex-sandbox` — OpenAI Codex CLI + CodeGraph MCP +
    `harden-sandbox` + frontend VS Code extensions.
- Both templates ship with `cap-drop=ALL` + `no-new-privileges` and
  named-volume mounts for agent home (`~/.claude` / `~/.codex`) and
  shell history.
- Seed system under `.devcontainer/seed/` that idempotently primes
  agent config on first container start (`CLAUDE.md`/`AGENTS.md`,
  MCP server entries, marketplaces, plugins, prompts, commands,
  agents, skills).
- GitHub Actions:
  - `test.yaml` — builds each template end-to-end with
    `devcontainer up` on PR / `main` push and runs a smoke check.
  - `release.yaml` — publishes both templates to GHCR via
    `devcontainers/action` on `main` push.
