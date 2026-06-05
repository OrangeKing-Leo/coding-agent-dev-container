# Codex agent instructions

## Sandbox

You are running inside a hardened dev container sandbox. The host machine is
isolated from this environment:

- All Linux capabilities are dropped except `CHOWN`, `DAC_OVERRIDE`, `FOWNER`,
  `SETUID`, `SETGID`. `no-new-privileges` is set.
- Host credentials are blocked: `GH_TOKEN`, `GITHUB_TOKEN`, `AWS_*`, `GCLOUD_*`,
  `KUBECONFIG`, `DOCKER_*`, `NPM_TOKEN`, `SSH_AUTH_SOCK`, `GIT_ASKPASS` are all
  unset; `credential.helper` is forced to `/bin/false`.
- Only `/workspace` (bind-mounted from the host repo) and the named volumes
  for this agent's home directory and shell history are persistent. Anything
  else written to the container filesystem is lost on rebuild.

Treat anything outside `/workspace` as ephemeral. Do not try to reach external
services that require host credentials — they have been stripped on purpose.

## Pre-installed tooling

- `codegraph` — pre-indexed code knowledge graph, exposed as an MCP server
  (already wired into this agent). Run `codegraph init -i` (alias: `cgii`) in
  a project to build the index, then ask for `codegraph_*` tools.

## House rules

- **Never push code without explicit user consent.** This includes
  `git push`, `git push --force`, opening pull requests, or any other
  operation that publishes commits to a remote. Local commits are fine,
  but pushing requires the user to say so in this turn — prior approval
  does not carry over. If unsure, ask first.
- **Always reply in Simplified Chinese (简体中文).** This is the user's
  preferred language for all conversational responses, including
  explanations, summaries, and questions back to the user. Code,
  identifiers, commit messages, and tool/CLI output stay in their
  original language; only the prose you write to the user is in Chinese.
