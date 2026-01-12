---
name: implementation-planning
description: "Use when you have a design or requirements for a multi-step task, before writing code. Creates bite-sized TDD task plans with exact file paths, complete code, and verification steps."
version: 1.0.0
---

# Implementation Planning

Write comprehensive implementation plans assuming the executor has zero context. Document everything: which files to touch, complete code, how to test. Bite-sized tasks. DRY. YAGNI. TDD.

## The Iron Law

```
NO IMPLEMENTATION WITHOUT A PLAN FIRST
```

For multi-step tasks, write the plan before writing code.

## When to Use

- MUST: Before implementing features with 3+ steps
- MUST: Before complex refactoring
- SHOULD: When multiple files need coordinated changes
- MAY: Skip for single-file, single-function changes

## Bite-Sized Task Granularity

Each step is ONE action (2-5 minutes):

```markdown
1. Write the failing test - step
2. Run it to verify it fails - step
3. Implement minimal code to pass - step
4. Run tests to verify they pass - step
5. Commit - step
```

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

## MUST/SHOULD/NEVER Rules

### MUST

- MUST: Include exact file paths (never "in the appropriate file")
- MUST: Include complete code (never "add validation logic")
- MUST: Include exact commands with expected output
- MUST: Follow TDD cycle (test → fail → implement → pass → commit)
- MUST: Save plans to `docs/plans/YYYY-MM-DD-<feature-name>.md`

### SHOULD

- SHOULD: Use fn(args, deps) pattern for new functions
- SHOULD: Use Result types for error handling
- SHOULD: Include type definitions in implementation
- SHOULD: Reference line numbers for modifications

### NEVER

- NEVER: Write vague steps ("add appropriate error handling")
- NEVER: Skip the verification steps
- NEVER: Bundle multiple changes in one step
- NEVER: Assume executor knows the codebase

## Plan Quality Checklist

Before finalizing:

- [ ] Every step is one action (2-5 minutes)
- [ ] All file paths are exact
- [ ] All code is complete and copy-pasteable
- [ ] All commands include expected output
- [ ] TDD cycle is clear for each task
- [ ] Commit messages follow project conventions

## Execution Handoff

After saving the plan:

```
Plan complete and saved to `docs/plans/<filename>.md`.

Ready to execute? I'll follow TDD workflow for each task.
```

## Integration

| Skill | Relationship |
|-------|--------------|
| `design-exploration` | Design must be approved before planning |
| `tdd-workflow` | Tasks follow strict TDD cycle |
| `fn-args-deps` | New functions use fn(args, deps) pattern |
| `result-types` | Error handling uses Result types |
