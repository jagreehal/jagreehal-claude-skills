---
name: git-worktrees
description: Isolates feature work in a dedicated git worktree that shares the repository but lives in its own directory, with directory selection, gitignore safety checks, project setup, and baseline test verification. Use when starting feature work that needs isolation from the current workspace, before executing a multi-task implementation plan, when running parallel work on different branches, or for experimental work that might be discarded.
version: 1.1.0
---

# Git Worktrees

## Overview

Git worktrees create isolated workspaces that share the same repository while living in separate directories, letting you work on multiple branches simultaneously without switching or stashing. Each worktree has its own working directory and branch, so an agent can implement a feature, run an experiment, or execute a plan without disturbing the main checkout. If an experiment fails, delete the worktree. Nothing in the main workspace is touched, and nothing is lost until you explicitly merge the changes.

This isolation is what makes safe parallel agent work possible: independent features run in independent directories with no risk of colliding edits.

## When to Use

- Implementing a feature that needs isolation from the current workspace
- Before executing a multi-task implementation plan
- Running parallel development on different features at once
- Experimental work that might be discarded

**When NOT to use:** Quick edits on the current branch, or when the change is trivial enough that branch switching costs nothing. Don't add worktree overhead to a one-line fix.

**Related:** A worktree is often spun up off a validated [design-exploration](../design-exploration/SKILL.md) design, and is the workspace where an [implementation-planning](../implementation-planning/SKILL.md) plan executes. Multiple worktrees enable [parallel-agent-dispatch](../parallel-agent-dispatch/SKILL.md); cleanup is handled by [branch-completion](../branch-completion/SKILL.md).

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

**If a preference is specified:** Use it.

### 3. Ask User

```
No worktree directory found. Where should I create worktrees?

1. .worktrees/ (project-local, hidden)
2. ~/worktrees/<project-name>/ (global location)

Which would you prefer?
```

## Safety Verification

For project-local directories, verify the directory is git-ignored before creating anything inside it:

```bash
git check-ignore -q .worktrees 2>/dev/null
```

**If NOT ignored:**
1. Add it to `.gitignore`
2. Commit the change
3. Then proceed

This prevents accidentally committing worktree contents into the repository.

## Creation Steps

The whole procedure below (directory selection, gitignore safety, branch creation, setup, and baseline tests) is bundled as a deterministic script. Prefer it over reissuing the commands by hand:

```bash
scripts/create-worktree.sh <branch-name> [base-dir]
```

It exits non-zero if the target directory isn't git-ignored (exit 2) or baseline tests fail (exit 3), so it never proceeds past a broken baseline silently. Run the steps manually only when you need to deviate from the standard flow.

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

**If tests fail:** Report the failures and ask whether to proceed.
**If tests pass:** Report ready.

### Step 5: Report Location

```
Worktree ready at /path/to/worktree
Tests passing (47 tests, 0 failures)
Ready to implement <feature-name>
```

## Rules

| Rule | Detail |
|------|--------|
| Directory priority | existing `.worktrees/` > `worktrees/` > CLAUDE.md > ask |
| Verify ignored | Project-local worktree dirs must be git-ignored first |
| Baseline tests | Run them before starting work |
| Report location | Always report the worktree path when done |
| Setup | Auto-detect and run project setup |
| Branch naming | Create the feature branch with a descriptive name |

**Never** create a worktree without verifying it's ignored, skip baseline test verification, proceed past failing tests without asking, or assume a directory location when it's ambiguous.

## Quick Reference

| Situation | Action |
|-----------|--------|
| `.worktrees/` exists | Use it (verify ignored) |
| `worktrees/` exists | Use it (verify ignored) |
| Both exist | Use `.worktrees/` |
| Neither exists | Check CLAUDE.md → ask user |
| Directory not ignored | Add to `.gitignore` + commit |
| Baseline tests fail | Report failures + ask |

## Cleanup

When work is complete, remove the worktree from the main repository:

```bash
# From main repository
git worktree remove <worktree-path>
git branch -d <feature-branch>  # if merged
```

## Red Flags

- Creating a worktree inside a directory that isn't git-ignored
- Starting work without running baseline tests
- Proceeding past failing baseline tests without asking
- Guessing the worktree location instead of following the priority order
- Leaving stale worktrees and branches around after merge

## Verification

Before starting work in a new worktree, confirm:

- [ ] The directory was chosen by the priority order (existing > CLAUDE.md > ask)
- [ ] Project-local worktree directories are git-ignored
- [ ] Project setup ran successfully
- [ ] Baseline tests pass (or failures were reported and the human approved proceeding)
- [ ] The worktree location was reported back
