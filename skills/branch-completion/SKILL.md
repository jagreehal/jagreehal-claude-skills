---
name: branch-completion
description: "Use when implementation is complete and tests pass. Guides completion by presenting structured options for merge, PR, or cleanup."
version: 1.0.0
---

# Branch Completion

Guide completion of development work by verifying, presenting options, and executing cleanup.

## The Iron Law

```
NO COMPLETION WITHOUT TEST VERIFICATION FIRST
```

Verify tests pass before presenting completion options.

## The Process

### Step 1: Verify Tests

**Before presenting options:**

```bash
npm test  # or cargo test / pytest / go test ./...
```

**If tests fail:**
```
Tests failing (N failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

STOP. Don't proceed to Step 2.

**If tests pass:** Continue.

### Step 2: Present Options

Present exactly these 4 options:

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
# Verify tests on merged result
npm test
git branch -d <feature-branch>
```

Then cleanup worktree (Step 4).

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

Keep worktree for PR iteration.

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

Don't cleanup worktree.

#### Option 4: Discard

**Confirm first:**
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for exact confirmation. If confirmed:
```bash
git checkout <base-branch>
git branch -D <feature-branch>
```

Then cleanup worktree.

### Step 4: Cleanup Worktree

**For Options 1, 2, 4 only:**

```bash
git worktree remove <worktree-path>
```

**For Option 3:** Keep worktree.

## MUST/SHOULD/NEVER Rules

### MUST

- MUST: Verify tests before presenting options
- MUST: Present exactly 4 structured options
- MUST: Get typed confirmation for discard
- MUST: Verify tests again after merge (Option 1)

### SHOULD

- SHOULD: Determine base branch automatically
- SHOULD: Include commit summary in discard confirmation
- SHOULD: Report PR URL after creation

### NEVER

- NEVER: Proceed with failing tests
- NEVER: Present vague "what should I do?" questions
- NEVER: Delete work without typed confirmation
- NEVER: Force-push without explicit request

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | ✓ | - | - | ✓ |
| 2. Create PR | - | ✓ | ✓ | - |
| 3. Keep as-is | - | - | ✓ | - |
| 4. Discard | - | - | - | ✓ (force) |

## Integration

| Skill | Relationship |
|-------|--------------|
| `git-worktrees` | Cleans up worktree created there |
| `verification-before-completion` | Tests must pass first |
| `implementation-planning` | Completes planned work |
