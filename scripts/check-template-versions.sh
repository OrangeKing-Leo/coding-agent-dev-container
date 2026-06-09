#!/usr/bin/env bash
# Fail if a template has publishable changes staged but its version
# in devcontainer-template.json wasn't bumped. Without a bump the
# release workflow logs "Version X already exists, skipping ..." and
# the GHCR tarball stays at the old content.
set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

staged="$(git diff --cached --name-only --diff-filter=ACMR)"
[ -z "$staged" ] && exit 0

fail=0
for tdir in templates/src/*/; do
  template_id="$(basename "$tdir")"
  meta="${tdir}devcontainer-template.json"

  # Files in this template that are staged AND are publishable
  # (README.md / NOTES.md are stripped by the publish step, so
  # they don't require a version bump).
  publishable_changes="$(printf '%s\n' "$staged" \
    | grep "^${tdir}" \
    | grep -vE '/(README\.md|NOTES\.md)$' || true)"

  [ -z "$publishable_changes" ] && continue

  # Did the "version": "..." line change in this commit?
  if git diff --cached -- "$meta" 2>/dev/null \
     | grep -qE '^\+[[:space:]]*"version"[[:space:]]*:'; then
    continue
  fi

  current_version="$(grep -E '"version"[[:space:]]*:' "$meta" \
    | head -1 | sed -E 's/.*"version"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
  echo "ERROR: template '$template_id' has staged changes but its version was not bumped." >&2
  echo "       Current version in $meta: $current_version" >&2
  echo "       Bump it (e.g. patch: ${current_version} -> next) so the release workflow republishes the OCI artifact." >&2
  echo "       Files triggering this check:" >&2
  printf '         %s\n' $publishable_changes >&2
  fail=1
done

exit "$fail"
