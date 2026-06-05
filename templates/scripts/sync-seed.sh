#!/usr/bin/env bash
# Copy shared seed content into each template's .devcontainer/seed/ tree.
# Run before publishing — keeps duplicates in sync. Safe to re-run.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SHARED="$ROOT/shared/seed-common"

copy_with_header() {
  local header="$1" src="$2" dest="$3"
  mkdir -p "$(dirname "$dest")"
  {
    printf '# %s\n\n' "$header"
    cat "$src"
  } > "$dest"
}

# Claude Code: shared sandbox notes → CLAUDE.md
copy_with_header \
  "Claude Code instructions" \
  "$SHARED/sandbox-notes.md" \
  "$ROOT/src/claude-code-sandbox/.devcontainer/seed/CLAUDE.md"

# Codex: shared sandbox notes → AGENTS.md
copy_with_header \
  "Codex agent instructions" \
  "$SHARED/sandbox-notes.md" \
  "$ROOT/src/codex-sandbox/.devcontainer/seed/AGENTS.md"

echo "synced shared seed content into both templates"
