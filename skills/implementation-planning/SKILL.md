---
name: implementation-planning
description: Creates bite-sized, TDD-ordered implementation plans with exact file paths, complete copy-pasteable code, and explicit verification steps, written for an executor with zero prior context. Use when you have an approved design or clear requirements for a multi-step task and are about to write code. Use before features with 3+ steps, complex refactoring, or any change that coordinates edits across multiple files.
version: 1.1.0
---

# Implementation Planning

## Overview

Write a comprehensive implementation plan that assumes the executor has zero context about the codebase. Document everything: which files to touch, the complete code to write, and how to verify each step. Tasks are bite-sized, the plan is DRY, scope is YAGNI, and every task follows TDD. A good plan is the difference between an agent that completes work reliably and one that produces a tangled mess that needs reworking.

The core principle is an iron law:

```
NO IMPLEMENTATION WITHOUT A PLAN FIRST
```

For any multi-step task, write the plan before writing code. Implementation without a plan is just typing.

## When to Use

- Before implementing a feature with 3+ steps
- Before complex refactoring
- When multiple files need coordinated changes
- When the implementation order isn't obvious

**When NOT to use:** Single-file, single-function changes where the scope is obvious. A two-step change does not need a plan document.

**Related:** The design must be approved via [design-exploration](../design-exploration/SKILL.md) before planning. Tasks follow the strict red-green-refactor loop in [tdd-workflow](../tdd-workflow/SKILL.md). Execute the plan inside an isolated [git-worktrees](../git-worktrees/SKILL.md) workspace, and split independent tasks across [parallel-agent-dispatch](../parallel-agent-dispatch/SKILL.md) when work can be parallelized.

## Bite-Sized Task Granularity

Each step is ONE action, roughly 2-5 minutes of work:

```markdown
1. Write the failing test
2. Run it to verify it fails
3. Implement minimal code to pass
4. Run tests to verify they pass
5. Commit
```

If a step contains the word "and", it is probably two steps.

## Plan Structure

### Header (Required)

```markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

### Task Structure

```markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.ts`
- Modify: `exact/path/to/existing.ts:123-145`
- Test: `tests/exact/path/to/test.ts`

**Step 1: Write the failing test**

\`\`\`typescript
import { describe, it, expect } from 'vitest';
import { mock } from 'vitest-mock-extended';
import { getUser, type GetUserDeps } from './get-user';

describe('getUser', () => {
  it('returns NOT_FOUND when user does not exist', async () => {
    const deps = mock<GetUserDeps>();
    deps.db.findUser.mockResolvedValue(null);

    const result = await getUser({ userId: '123' }, deps);

    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.error).toBe('NOT_FOUND');
    }
  });
});
\`\`\`

**Step 2: Run test to verify it fails**

Run: `npm test src/domain/get-user.test.ts`
Expected: FAIL with "Cannot find module './get-user'"

**Step 3: Write minimal implementation**

\`\`\`typescript
import { err, type Result } from '@/result';

export type GetUserDeps = {
  db: { findUser: (id: string) => Promise<User | null> };
};

export async function getUser(
  args: { userId: string },
  deps: GetUserDeps
): Promise<Result<User, 'NOT_FOUND'>> {
  return err('NOT_FOUND');
}
\`\`\`

**Step 4: Run test to verify it passes**

Run: `npm test src/domain/get-user.test.ts`
Expected: PASS

**Step 5: Commit**

\`\`\`bash
git add src/domain/get-user.ts src/domain/get-user.test.ts
git commit -m "feat(user): add getUser with NOT_FOUND handling"
\`\`\`
```

## Rules

| Rule | Detail |
|------|--------|
| Exact file paths | Never "in the appropriate file"; always the full path |
| Complete code | Never "add validation logic"; write the actual code |
| Exact commands | Always include the command and its expected output |
| TDD cycle | test → fail → implement → pass → commit, every task |
| Save the plan | Write to `docs/plans/YYYY-MM-DD-<feature-name>.md` |
| fn(args, deps) | New functions use the `fn(args, deps)` pattern |
| Result types | Error handling uses Result types |
| Reference lines | Cite line numbers for modifications |

**Never** write vague steps, skip verification, bundle multiple changes into one step, or assume the executor knows the codebase.

## Plan Quality Checklist

Before finalizing:

- [ ] Every step is one action (2-5 minutes)
- [ ] All file paths are exact
- [ ] All code is complete and copy-pasteable
- [ ] All commands include expected output
- [ ] The TDD cycle is clear for each task
- [ ] Commit messages follow project conventions

## Execution Handoff

After saving the plan:

```
Plan complete and saved to `docs/plans/<filename>.md`.

Ready to execute? I'll follow the TDD workflow for each task.
```

## Red Flags

- Starting implementation without a written task list
- Steps that say "implement the feature" with no concrete code
- No verification step in a task
- A single step that touches many files or bundles several changes
- The plan assumes the executor already knows the codebase
- Commit messages omitted from tasks

## Verification

Before handing off for execution, confirm:

- [ ] The plan has a header with goal, architecture, and tech stack
- [ ] Every task follows the test → fail → implement → pass → commit cycle
- [ ] Every file path is exact and every command states its expected output
- [ ] No step bundles multiple changes
- [ ] The plan is saved to `docs/plans/` and ready for handoff
