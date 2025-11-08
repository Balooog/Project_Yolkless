#!/usr/bin/env bash
set -euo pipefail
DOC_PATHS=("docs")
BRANCH="docs"
git rev-parse --is-inside-work-tree >/dev/null
mkdir -p .git/worktrees/.docs || true
git show-ref --verify --quiet refs/heads/$BRANCH || git branch $BRANCH
git worktree add -B $BRANCH .git/worktrees/.docs $BRANCH 2>/dev/null || true
rsync -a --delete ${DOC_PATHS[@]} .git/worktrees/.docs/
pushd .git/worktrees/.docs >/dev/null
git add -A
git diff --cached --quiet || (git commit -m "docs: sync $(date -u +%FT%TZ)" && git push -u origin $BRANCH)
popd >/dev/null
echo "[sync] docs branch updated"
