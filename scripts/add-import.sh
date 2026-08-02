#!/usr/bin/env bash
# Create imports/<name>/qlfile for a GitHub (or git) source pin.
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: add-import.sh <owner/repo|git-url> [ref] [import-name]

  owner/repo   → github line (default)
  https://…    → git line
  ref          tag/branch/sha (optional but recommended)
  import-name  directory under imports/ (default: repo basename)

Examples:
  ./scripts/add-import.sh alexandria/alexandria v1.4
  ./scripts/add-import.sh fukamachi/sxql v1.3.0 sxql
  ./scripts/add-import.sh https://github.com/edicl/cl-ppcre.git v2.1.1
EOF
}

die() { echo "add-import.sh: $*" >&2; exit 1; }

[[ $# -ge 1 ]] || { usage; exit 1; }
[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { usage; exit 0; }

SPEC="$1"
REF="${2:-}"
NAME="${3:-}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "$SPEC" == http://* || "$SPEC" == https://* || "$SPEC" == git@* ]]; then
  KIND="git"
  TARGET="$SPEC"
  if [[ -z "$NAME" ]]; then
    base="${SPEC%.git}"
    NAME="$(basename "$base")"
  fi
else
  KIND="github"
  TARGET="$SPEC"
  if [[ "$SPEC" != */* || "$SPEC" == */*/* ]]; then
    die "expected owner/repo, got: $SPEC"
  fi
  if [[ -z "$NAME" ]]; then
    NAME="${SPEC#*/}"
  fi
fi

NAME="$(echo "$NAME" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9._-' '-')"
[[ -n "$NAME" ]] || die "empty import name"

DIR="$ROOT/imports/$NAME"
QLFILE="$DIR/qlfile"

if [[ -e "$QLFILE" ]]; then
  die "already exists: $QLFILE"
fi

mkdir -p "$DIR"
if [[ -n "$REF" ]]; then
  printf '%s %s %s\n' "$KIND" "$TARGET" "$REF" >"$QLFILE"
else
  printf '%s %s\n' "$KIND" "$TARGET" >"$QLFILE"
fi

echo "Wrote $QLFILE"
cat "$QLFILE"
