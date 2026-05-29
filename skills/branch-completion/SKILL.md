---
name: branch-completion
description: Guides completion of development work by verifying tests, presenting structured merge/PR/keep/discard options, and executing the chosen cleanup. Use when implementation is complete and tests pass, when wrapping up a feature branch, or when deciding how to land or discard work.
version: 1.1.0
---

# Branch Completion

## Overview

Close out finished work cleanly: verify tests, present a fixed set of options, execute the choice, and clean up. The core principle is one rule: **no completion without test verification first.** Tests are the gate: never present completion options or merge anything while tests are failing.

Structured options matter because "what should I do now?" is a vague prompt that invites mistakes. Four explicit choices (merge locally, open a PR, keep as-is, or discard) make the decision concrete and reversible, and tie each to a known cleanup path.

## When to Use

- Implementation is complete and you believe tests pass
- Wrapping up a feature branch or worktree
- Deciding whether to merge locally, open a PR, keep, or discard work

**When NOT to use:** Mid-implementation, or when tests have not yet been written or run. Finish and verify the work first.

**Related:** [verification-before-completion](../verification-before-completion/SKILL.md) (tests must pass before this skill runs), [git-worktrees](../git-worktrees/SKILL.md) (cleans up the worktree created there), [implementation-planning](../implementation-planning/SKILL.md) (completes the planned work).

## The Process

### Step 1: Verify Tests

Before presenting any options:

```bash
npm test  # or cargo test / pytest / go test ./...
```

**If tests fail**, stop here:

```
Tests failing (N failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Do not proceed to Step 2.

**If tests pass:** continue.

### Step 2: Present Options

Present exactly these four options:

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (handle later)
4. Discard this work

Which option?
```

### Step 3: Execute Choice

#### Option 1: Merge Locally

```bash
git checkout <base-branch>
git pull
git merge <feature-branch>
npm test   # verify tests on the merged result
git branch -d <feature-branch>
```

Then clean up the worktree (Step 4).

#### Option 2: Push and Create PR

```bash
git push -u origin <feature-branch>
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
- [Changes]

## Test Plan
- [ ] [Verification steps]
EOF
)"
```

Keep the worktree for PR iteration. Report the PR URL.

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>." Do not clean up the worktree.

#### Option 4: Discard

Confirm first:

```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for the exact word. If confirmed:

```bash
git checkout <base-branch>
git branch -D <feature-branch>
```

Then clean up the worktree.

### Step 4: Cleanup Worktree

For Options 1, 2, and 4:

```bash
git worktree remove <worktree-path>
```

For Option 3: keep the worktree.

## Option Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | ✓ | — | — | ✓ |
| 2. Create PR | — | ✓ | ✓ | — |
| 3. Keep as-is | — | — | ✓ | — |
| 4. Discard | — | — | — | ✓ (force) |

## Red Flags

- Presenting options while tests are failing
- Asking a vague "what should I do?" instead of the four structured options
- Deleting work without exact typed confirmation
- Force-pushing without an explicit request
- Skipping the post-merge test run on Option 1
- Removing a worktree on Option 3

## Verification

Before presenting options:

- [ ] Test suite has been run and passes

After executing the choice:

- [ ] Option 1: merged result re-tested, feature branch and worktree removed
- [ ] Option 2: branch pushed, PR created, PR URL reported, worktree kept
- [ ] Option 3: branch and worktree preserved, location reported
- [ ] Option 4: exact confirmation received before any deletion, worktree removed
