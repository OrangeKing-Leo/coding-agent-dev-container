#!/usr/bin/env bash
# Seed Codex CLI home directory on first container start.
# Idempotent: appends a TOML section only when the [mcp_servers.<name>] header
# is missing; copies files only when destination is absent.
set -euo pipefail

SEED_DIR="$(cd "$(dirname "$0")" && pwd)"
CODEX_HOME="$HOME/.codex"
CODEX_TOML="$CODEX_HOME/config.toml"

mkdir -p "$CODEX_HOME/prompts"
touch "$CODEX_TOML"

# 1. Append [mcp_servers.<name>] blocks from seed if the header isn't present.
if [ -f "$SEED_DIR/mcp-servers.toml" ]; then
  python3 - "$CODEX_TOML" "$SEED_DIR/mcp-servers.toml" <<'PY'
import re, sys
target, seed = sys.argv[1], sys.argv[2]
with open(target) as f:
    existing = f.read()
with open(seed) as f:
    seed_text = f.read()

# Split seed into [mcp_servers.<name>] blocks.
blocks = re.split(r'(?m)^(?=\[mcp_servers\.)', seed_text)
to_append = []
for block in blocks:
    m = re.match(r'\[(mcp_servers\.[^\]]+)\]', block.strip())
    if not m:
        continue
    header = '[' + m.group(1) + ']'
    if header in existing:
        continue
    to_append.append(block.strip())

if to_append:
    sep = '' if existing.endswith('\n\n') or not existing else ('\n' if existing.endswith('\n') else '\n\n')
    with open(target, 'a') as f:
        f.write(sep + '\n\n'.join(to_append) + '\n')
PY
fi

# 2. Seed AGENTS.md if missing.
[ -f "$SEED_DIR/AGENTS.md" ] && [ ! -e "$CODEX_HOME/AGENTS.md" ] \
  && cp "$SEED_DIR/AGENTS.md" "$CODEX_HOME/AGENTS.md"

# 3. Seed prompts directory per-file (skip if dest exists).
if [ -d "$SEED_DIR/prompts" ]; then
  cp -rn "$SEED_DIR/prompts/." "$CODEX_HOME/prompts/" 2>/dev/null || true
fi

echo "codex seed: done"
