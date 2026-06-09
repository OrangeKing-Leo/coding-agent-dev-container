#!/usr/bin/env bash
# Seed Claude Code home directory on first container start.
# Idempotent: deep-merges JSON for ~/.claude.json (existing keys win),
# copies dir contents only when destination file is absent,
# adds marketplaces and installs plugins only when not already present.
set -euo pipefail

SEED_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_HOME="$HOME/.claude"
CLAUDE_JSON="$HOME/.claude.json"

mkdir -p "$CLAUDE_HOME/commands" "$CLAUDE_HOME/agents" "$CLAUDE_HOME/skills" "$CLAUDE_HOME/plugins"

# 1. Deep-merge mcp-servers.json into ~/.claude.json (existing keys win).
if [ -f "$SEED_DIR/mcp-servers.json" ]; then
  python3 - "$CLAUDE_JSON" "$SEED_DIR/mcp-servers.json" <<'PY'
import json, os, sys
target, seed_path = sys.argv[1], sys.argv[2]
base = {}
if os.path.exists(target):
    try:
        with open(target) as f:
            base = json.load(f) or {}
    except Exception:
        base = {}
with open(seed_path) as f:
    seed = json.load(f)

def merge(b, s):
    if not isinstance(b, dict) or not isinstance(s, dict):
        return
    for k, v in s.items():
        if k not in b:
            b[k] = v
        else:
            merge(b[k], v)

merge(base, seed)
with open(target, 'w') as f:
    json.dump(base, f, indent=2)
PY
fi

# 2. Seed top-level CLAUDE.md if missing.
[ -f "$SEED_DIR/CLAUDE.md" ] && [ ! -e "$CLAUDE_HOME/CLAUDE.md" ] \
  && cp "$SEED_DIR/CLAUDE.md" "$CLAUDE_HOME/CLAUDE.md"

# 3. Seed commands/agents/skills directories per-file (skip if dest exists).
for sub in commands agents skills; do
  src="$SEED_DIR/$sub"
  [ -d "$src" ] || continue
  cp -rn "$src/." "$CLAUDE_HOME/$sub/" 2>/dev/null || true
done

# 4. Register marketplaces and install plugins (no-op if already present).
strip_comments() { sed -E 's/[[:space:]]+#.*$//; s/^[[:space:]]+//; s/[[:space:]]+$//' "$1" | grep -Ev '^(#|$)'; }

if command -v claude >/dev/null 2>&1; then
  if [ -f "$SEED_DIR/marketplaces.txt" ]; then
    existing_mkt="$(claude plugin marketplace list 2>/dev/null || true)"
    while IFS= read -r src; do
      [ -n "$src" ] || continue
      # Cheap name extraction: take basename of repo/url/path.
      name="${src##*/}"; name="${name%.git}"
      if ! printf '%s' "$existing_mkt" | grep -qiF "$name"; then
        echo "claude-code seed: adding marketplace $src"
        claude plugin marketplace add "$src" || true
      fi
    done < <(strip_comments "$SEED_DIR/marketplaces.txt")
  fi

  if [ -f "$SEED_DIR/plugins.txt" ]; then
    existing_pl="$(claude plugin list 2>/dev/null || true)"
    while IFS= read -r entry; do
      [ -n "$entry" ] || continue
      pl_name="${entry%@*}"
      if ! printf '%s' "$existing_pl" | grep -qiF "$pl_name"; then
        echo "claude-code seed: installing plugin $entry"
        claude plugin install "$entry" --scope user || true
      fi
    done < <(strip_comments "$SEED_DIR/plugins.txt")
  fi
fi

# 5. Append missing lines from gitignore.append to project .gitignore.
if [ -f "$SEED_DIR/gitignore.append" ]; then
  WORKSPACE_ROOT="$(cd "$SEED_DIR/../.." && pwd)"
  TARGET_GI="$WORKSPACE_ROOT/.gitignore"
  HEADER="# Added by claude-code-sandbox dev container seed"
  to_append=()
  while IFS= read -r raw || [ -n "$raw" ]; do
    line="$(printf '%s' "$raw" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
    [ -z "$line" ] && continue
    case "$line" in \#*) continue ;; esac
    [ -f "$TARGET_GI" ] && grep -qxF "$line" "$TARGET_GI" && continue
    to_append+=("$line")
  done < "$SEED_DIR/gitignore.append"
  if [ "${#to_append[@]}" -gt 0 ]; then
    touch "$TARGET_GI"
    if [ -s "$TARGET_GI" ] && [ -n "$(tail -c1 "$TARGET_GI")" ]; then
      printf '\n' >> "$TARGET_GI"
    fi
    if ! grep -qxF "$HEADER" "$TARGET_GI"; then
      printf '\n%s\n' "$HEADER" >> "$TARGET_GI"
    fi
    printf '%s\n' "${to_append[@]}" >> "$TARGET_GI"
    echo "claude-code seed: appended ${#to_append[@]} line(s) to $TARGET_GI"
  fi
fi

echo "claude-code seed: done"
