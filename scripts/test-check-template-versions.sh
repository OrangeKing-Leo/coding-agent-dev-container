#!/usr/bin/env bash
# Tests for scripts/check-template-versions.sh.
# Builds a throwaway git repo in a temp dir that mirrors the templates/
# layout, stages various change shapes, runs the check, and asserts the
# expected exit code and error output.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CHECK="$REPO_ROOT/scripts/check-template-versions.sh"

[ -x "$CHECK" ] || { echo "FAIL: $CHECK is not executable"; exit 1; }

pass=0
fail=0

# ---- helpers ----------------------------------------------------------------

setup_fixture() {
  # Builds a temp git repo with two templates at version 1.0.0 and an
  # initial commit so subsequent edits show up as staged diffs.
  local dir
  dir="$(mktemp -d)"
  (
    cd "$dir"
    git init -q
    git config user.email "test@example.com"
    git config user.name "test"
    mkdir -p templates/src/alpha/.devcontainer/seed
    mkdir -p templates/src/beta/.devcontainer/seed
    cat > templates/src/alpha/devcontainer-template.json <<'JSON'
{
  "id": "alpha",
  "version": "1.0.0",
  "name": "Alpha"
}
JSON
    cat > templates/src/beta/devcontainer-template.json <<'JSON'
{
  "id": "beta",
  "version": "2.3.4",
  "name": "Beta"
}
JSON
    echo "alpha seed v1" > templates/src/alpha/.devcontainer/seed/install.sh
    echo "beta seed v1"  > templates/src/beta/.devcontainer/seed/install.sh
    echo "# alpha"       > templates/src/alpha/README.md
    echo "# beta"        > templates/src/beta/README.md
    git add -A
    git -c commit.gpgsign=false commit -qm "init"
  )
  echo "$dir"
}

# Bumps the "version" field in the given JSON file in-place.
bump_version() {
  local file="$1" new="$2"
  python3 - "$file" "$new" <<'PY'
import json, sys
p, v = sys.argv[1], sys.argv[2]
with open(p) as f:
    data = json.load(f)
data["version"] = v
with open(p, "w") as f:
    json.dump(data, f, indent=2)
PY
}

# Runs $CHECK inside $1, captures exit + stderr, asserts expectations.
# Args: name, expected_exit, [expected_stderr_substring]
assert_check() {
  local dir="$1" name="$2" want="$3" needle="${4:-}"
  local out err rc
  err="$(cd "$dir" && "$CHECK" 2>&1 >/dev/null)" || true
  out="$(cd "$dir" && "$CHECK" 2>/dev/null)" || true
  ( cd "$dir" && "$CHECK" >/dev/null 2>&1 ) && rc=0 || rc=$?

  if [ "$rc" != "$want" ]; then
    echo "FAIL [$name] expected exit=$want got=$rc"
    [ -n "$err" ] && printf '       stderr: %s\n' "$err"
    fail=$((fail+1))
    return
  fi
  if [ -n "$needle" ] && ! printf '%s' "$err" | grep -qF "$needle"; then
    echo "FAIL [$name] expected stderr to contain: $needle"
    printf '       got: %s\n' "$err"
    fail=$((fail+1))
    return
  fi
  echo "PASS [$name]"
  pass=$((pass+1))
}

# ---- cases ------------------------------------------------------------------

# 1. No staged changes → pass.
d=$(setup_fixture)
assert_check "$d" "no-staged-changes" 0
rm -rf "$d"

# 2. README-only change → pass (README is omitted by publish).
d=$(setup_fixture)
(
  cd "$d"
  echo "more docs" >> templates/src/alpha/README.md
  git add templates/src/alpha/README.md
)
assert_check "$d" "readme-only-change" 0
rm -rf "$d"

# 3. NOTES.md-only change → pass.
d=$(setup_fixture)
(
  cd "$d"
  echo "notes" > templates/src/alpha/NOTES.md
  git add templates/src/alpha/NOTES.md
)
assert_check "$d" "notes-only-change" 0
rm -rf "$d"

# 4. Seed change, no version bump → fail with template id in message.
d=$(setup_fixture)
(
  cd "$d"
  echo "alpha seed v2" > templates/src/alpha/.devcontainer/seed/install.sh
  git add templates/src/alpha/.devcontainer/seed/install.sh
)
assert_check "$d" "seed-change-no-bump" 1 "template 'alpha'"
rm -rf "$d"

# 5. Seed change WITH version bump → pass.
d=$(setup_fixture)
(
  cd "$d"
  echo "alpha seed v2" > templates/src/alpha/.devcontainer/seed/install.sh
  bump_version templates/src/alpha/devcontainer-template.json "1.0.1"
  git add templates/src/alpha/.devcontainer/seed/install.sh templates/src/alpha/devcontainer-template.json
)
assert_check "$d" "seed-change-with-bump" 0
rm -rf "$d"

# 6. Two templates, only one needs a bump → fail, names the right one.
d=$(setup_fixture)
(
  cd "$d"
  echo "alpha seed v2" > templates/src/alpha/.devcontainer/seed/install.sh
  echo "beta seed v2"  > templates/src/beta/.devcontainer/seed/install.sh
  bump_version templates/src/alpha/devcontainer-template.json "1.0.1"
  git add templates/src/alpha/.devcontainer/seed/install.sh \
          templates/src/alpha/devcontainer-template.json \
          templates/src/beta/.devcontainer/seed/install.sh
)
err="$(cd "$d" && "$CHECK" 2>&1 >/dev/null)" || true
if printf '%s' "$err" | grep -qF "template 'beta'" \
   && ! printf '%s' "$err" | grep -qF "template 'alpha'"; then
  echo "PASS [partial-bump-flags-only-unbumped]"
  pass=$((pass+1))
else
  echo "FAIL [partial-bump-flags-only-unbumped]"
  printf '       stderr: %s\n' "$err"
  fail=$((fail+1))
fi
rm -rf "$d"

# 7. Editing only the metadata file but NOT the version field → fail.
d=$(setup_fixture)
(
  cd "$d"
  python3 - <<'PY'
import json
p = "templates/src/alpha/devcontainer-template.json"
with open(p) as f: d = json.load(f)
d["name"] = "Alpha Renamed"
with open(p, "w") as f: json.dump(d, f, indent=2)
PY
  git add templates/src/alpha/devcontainer-template.json
)
assert_check "$d" "metadata-change-without-version" 1 "template 'alpha'"
rm -rf "$d"

# 8. New file under a template seed without version bump → fail.
d=$(setup_fixture)
(
  cd "$d"
  echo "new!" > templates/src/alpha/.devcontainer/seed/new.txt
  git add templates/src/alpha/.devcontainer/seed/new.txt
)
assert_check "$d" "new-seed-file-no-bump" 1 "new.txt"
rm -rf "$d"

# ---- summary ----------------------------------------------------------------
echo
echo "results: $pass passed, $fail failed"
[ "$fail" = 0 ]
