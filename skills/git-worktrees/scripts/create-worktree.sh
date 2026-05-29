#!/usr/bin/env bash
#
# create-worktree.sh — create an isolated git worktree following the
# git-worktrees skill procedure: directory selection, gitignore safety,
# branch creation, project setup, and baseline test verification.
#
# Usage:
#   scripts/create-worktree.sh <branch-name> [base-dir]
#
#   <branch-name>  Feature branch to create in the new worktree (required).
#   [base-dir]     Worktree parent directory. If omitted, resolves by priority:
#                  existing .worktrees/ > existing worktrees/ > $WORKTREE_DIR env.
#                  If none resolves, the script stops and asks you to pass one.
#
# Exit codes: 0 ok · 1 usage/precondition · 2 not git-ignored · 3 baseline tests failed
set -euo pipefail

die() { printf 'error: %s\n' "$1" >&2; exit "${2:-1}"; }

BRANCH="${1:-}"
[ -n "$BRANCH" ] || die "branch name required — usage: create-worktree.sh <branch-name> [base-dir]"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "not inside a git repository"
ROOT="$(git rev-parse --show-toplevel)"
PROJECT="$(basename "$ROOT")"
cd "$ROOT"

# 1. Directory selection priority: arg > existing .worktrees > existing worktrees > $WORKTREE_DIR
BASE="${2:-}"
if [ -z "$BASE" ]; then
  if   [ -d "$ROOT/.worktrees" ]; then BASE="$ROOT/.worktrees"
  elif [ -d "$ROOT/worktrees"  ]; then BASE="$ROOT/worktrees"
  elif [ -n "${WORKTREE_DIR:-}" ]; then BASE="$WORKTREE_DIR/$PROJECT"
  else die "no worktree directory found — pass one explicitly, e.g. create-worktree.sh $BRANCH .worktrees"
  fi
fi

# 2. Safety: project-local worktree dirs must be git-ignored before use.
case "$BASE" in
  "$ROOT"/*)
    rel="${BASE#"$ROOT"/}"
    if ! git check-ignore -q "$rel" 2>/dev/null; then
      die "'$rel' is not git-ignored — add it to .gitignore and commit before creating worktrees inside the repo" 2
    fi
    ;;
esac

mkdir -p "$BASE"
PATH_TO_WT="$BASE/$BRANCH"
[ -e "$PATH_TO_WT" ] && die "worktree path already exists: $PATH_TO_WT"

# 3. Create the worktree with a new branch.
git worktree add "$PATH_TO_WT" -b "$BRANCH"
cd "$PATH_TO_WT"

# 4. Auto-detect and run project setup.
if   [ -f package.json ];     then npm install
elif [ -f Cargo.toml ];       then cargo build
elif [ -f requirements.txt ]; then pip install -r requirements.txt
elif [ -f go.mod ];           then go mod download
fi

# 5. Verify a clean baseline. Non-zero exit reports failure (exit 3) so the
#    caller can decide whether to proceed — the script never proceeds silently.
baseline_status=0
if   [ -f package.json ];  then npm test            || baseline_status=$?
elif [ -f Cargo.toml ];    then cargo test          || baseline_status=$?
elif [ -f requirements.txt ]; then pytest           || baseline_status=$?
elif [ -f go.mod ];        then go test ./...        || baseline_status=$?
fi

# 6. Report.
printf '\nWorktree ready at %s\n' "$PATH_TO_WT"
if [ "$baseline_status" -eq 0 ]; then
  printf 'Baseline tests passing. Ready to implement %s\n' "$BRANCH"
else
  printf 'WARNING: baseline tests failed (exit %s). Review before starting work on %s\n' "$baseline_status" "$BRANCH" >&2
  exit 3
fi
