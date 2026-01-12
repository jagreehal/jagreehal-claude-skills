---
name: git-worktrees
description: "Use when starting feature work that needs isolation from current workspace. Creates isolated git worktrees with directory selection, safety verification, and baseline testing."
version: 1.0.0
---

# Git Worktrees

Git worktrees create isolated workspaces sharing the same repository, allowing work on multiple branches simultaneously.

## When to Use

- MUST: When implementing features that need isolation
- MUST: Before executing multi-task implementation plans
- SHOULD: When parallel development on different features needed
- MAY: For experimental work that might be discarded

## Directory Selection Priority

### 1. Check Existing Directories

```bash
ls -d .worktrees 2>/dev/null     # Preferred (hidden)
ls -d worktrees 2>/dev/null      # Alternative
```

**If found:** Use that directory. If both exist, `.worktrees` wins.

### 2. Check CLAUDE.md

```bash
grep -i "worktree.*director" CLAUDE.md 2>/dev/null
```

**If preference specified:** Use it.

### 3. Ask User

```
No worktree directory found. Where should I create worktrees?

1. .worktrees/ (project-local, hidden)
2. ~/worktrees/<project-name>/ (global location)

Which would you prefer?
```

## Safety Verification

### MUST: Verify Directory is Ignored

For project-local directories:

```bash
git check-ignore -q .worktrees 2>/dev/null
```

**If NOT ignored:**
1. Add to .gitignore
2. Commit the change
3. Then proceed

**Why:** Prevents accidentally committing worktree contents.

## Creation Steps

### Step 1: Detect Project Name

```bash
project=$(basename "$(git rev-parse --show-toplevel)")
```

### Step 2: Create Worktree

```bash
# Create worktree with new branch
git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

### Step 3: Run Project Setup

```bash
# Auto-detect and run
[ -f package.json ] && npm install
[ -f Cargo.toml ] && cargo build
[ -f requirements.txt ] && pip install -r requirements.txt
[ -f go.mod ] && go mod download
```

### Step 4: Verify Clean Baseline

```bash
npm test  # or cargo test / pytest / go test ./...
```

**If tests fail:** Report failures, ask whether to proceed.
**If tests pass:** Report ready.

### Step 5: Report Location

```
Worktree ready at /path/to/worktree
Tests passing (47 tests, 0 failures)
Ready to implement <feature-name>
```

## MUST/SHOULD/NEVER Rules

### MUST

- MUST: Follow directory priority (existing > CLAUDE.md > ask)
- MUST: Verify directory is ignored for project-local worktrees
- MUST: Run baseline tests before starting work
- MUST: Report worktree location when done

### SHOULD

- SHOULD: Auto-detect and run project setup
- SHOULD: Create feature branch with descriptive name
- SHOULD: Use `.worktrees/` over `worktrees/`

### NEVER

- NEVER: Create worktree without verifying it's ignored
- NEVER: Skip baseline test verification
- NEVER: Proceed with failing tests without asking
- NEVER: Assume directory location when ambiguous

## Quick Reference

| Situation | Action |
|-----------|--------|
| `.worktrees/` exists | Use it (verify ignored) |
| `worktrees/` exists | Use it (verify ignored) |
| Both exist | Use `.worktrees/` |
| Neither exists | Check CLAUDE.md → Ask user |
| Directory not ignored | Add to .gitignore + commit |
| Baseline tests fail | Report failures + ask |

## Cleanup

When work is complete, remove worktree:

```bash
# From main repository
git worktree remove <worktree-path>
git branch -d <feature-branch>  # if merged
```

## Integration

| Skill | Relationship |
|-------|--------------|
| `design-exploration` | May trigger worktree creation |
| `implementation-planning` | Plans execute in worktree |
| `branch-completion` | Handles worktree cleanup |
