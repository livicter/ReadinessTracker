#!/usr/bin/env bash
# Fail the tree if compile products, secrets, or product bans leak into git.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

fail() {
  printf 'ci-guard-tree: %s\n' "$*" >&2
  exit 1
}

if hits="$(git ls-files | grep -E '^(build/|build-DD/|DerivedData/)' || true)" && [[ -n "$hits" ]]; then
  printf '%s\n' "$hits" >&2
  fail "tracked build or DerivedData paths"
fi

if hits="$(git ls-files | grep -E '\.app/|\.ipa$|\.dSYM/|\.xcarchive$|\.o$' || true)" && [[ -n "$hits" ]]; then
  printf '%s\n' "$hits" >&2
  fail "tracked compiled product"
fi

if hits="$(git ls-files | grep -E '(^|/)Secrets\.xcconfig$' || true)" && [[ -n "$hits" ]]; then
  printf '%s\n' "$hits" >&2
  fail "Secrets.xcconfig must stay gitignored"
fi

if hits="$(git ls-files | grep -E 'xcuserdata/' || true)" && [[ -n "$hits" ]]; then
  printf '%s\n' "$hits" >&2
  fail "tracked xcuserdata"
fi

if git grep -n 'Heart Points' -- '*.swift' '*.m' '*.h'; then
  fail "Heart Points must not appear in product source"
fi

if git grep -nE 'FITBIT_CLIENT_SECRET[[:space:]]*=[[:space:]]*[^[:space:]/$]' -- ':!*.example' ':!*.md'; then
  fail "Fitbit client secret looks committed"
fi

for f in verify-dashboard.png verify-whoop-stack.png verify-body-activity.png verify-settings-sources.png verify-rings.png; do
  [[ -s ".audit/$f" ]] || fail "missing .audit/$f"
done

echo "==> TREE GUARD OK"
