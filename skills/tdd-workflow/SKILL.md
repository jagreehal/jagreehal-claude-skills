---
name: tdd-workflow
description: Drives implementation through a strict TDD state machine that forbids production code without a failing test first. Use when implementing any feature, fixing any bug, or changing behavior with test-first discipline; use when you need enforced red-green-refactor with Result types and dependency injection.
version: 2.2.0
libraries: ["vitest", "vitest-mock-extended"]
---

# TDD Workflow

## Overview

Strict test-driven development governed by a 7-state machine (PLANNING, RED, GREEN, REFACTOR, VERIFY, BLOCKED, VIOLATION). You write a failing test first, watch it fail, implement the minimum to pass, watch it pass, then refactor and verify, announcing your current state on every message.

**Why the state machine:** TDD fails in practice not because the loop is hard, but because it is easy to skip a step under pressure ("I'll add the test after"). Code written before its test is biased by the implementation: the test then verifies what the code does instead of what it should do. Announcing state on every message makes skips visible and self-correcting. This skill integrates with `fn(args, deps)`, `vitest-mock-extended` typed mocks, and typed Result error handling.

## When to Use

- Implementing any new feature, function, or behavior
- Fixing any bug (write the reproduction test first)
- Changing or extending existing behavior
- Any work where tests must drive the design

**When NOT to use:** Pure configuration, documentation, or static-content changes with no behavioral impact; throwaway exploration you intend to delete (then restart with TDD).

**Related:** [writing-tests](../writing-tests/SKILL.md) governs the RED phase (outcome-based names, specific assertions). [testing-strategy](../testing-strategy/SKILL.md) places these tests in the pyramid. [fn-args-deps](../fn-args-deps/SKILL.md) and [result-types](../result-types/SKILL.md) shape the code under test. [debugging-methodology](../debugging-methodology/SKILL.md) covers bug reproduction before the RED phase.

## The Iron Law

```
NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST
```

Write code before the test? **Delete it. Start over.**

**No exceptions:**
- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Don't look at it
- Delete means delete

Implement fresh from tests. Period.

**Rationale:** Code written before tests is biased by implementation. TDD requires tests to drive design, not verify existing code.

## CRITICAL: STATE MACHINE GOVERNANCE

**EVERY SINGLE MESSAGE MUST START WITH YOUR CURRENT TDD STATE**

Format:
```
⚪ TDD: PLANNING
🔴 TDD: RED
🟢 TDD: GREEN
🔵 TDD: REFACTOR
🟡 TDD: VERIFY
⚠️ TDD: BLOCKED
🔥 TDD: VIOLATION
```

**NOT JUST THE FIRST MESSAGE. EVERY. SINGLE. MESSAGE.**

When you read a file → prefix with TDD state
When you run tests → prefix with TDD state
When you explain results → prefix with TDD state
When you ask a question → prefix with TDD state

Example:
```
⚪ TDD: PLANNING
Writing test for getUser returning NOT_FOUND...

⚪ TDD: PLANNING
Running npm test to see it fail...

🔴 TDD: RED
Test fails correctly. Implementing minimum solution...

🟢 TDD: GREEN
Test passes. Checking if refactor needed...
```

## State Machine Diagram

```
                  user request
                       ↓
                 ┌──────────┐
            ┌────│ PLANNING │────┐
            │    └─────┬────┘    │
            │          │         │
            │  test fails        │
            │  correctly         │
  unclear   │          ↓         │ blocker
            │    ┌──────────┐    │
            └────│   RED    │    │
                 │          │    │
                 │ Test IS  │    │
                 │ failing  │    │
                 └────┬─────┘    │
                      │          │
              test    │          │
              passes  │          │
                      ↓          │
                 ┌──────────┐    │
                 │  GREEN   │    │
                 │          │    │
                 │ Test IS  │    │
                 │ passing  │    │
                 └────┬─────┘────┘
                      │
          refactoring │
          needed      │
                      ↓
                 ┌──────────┐
            ┌────│ REFACTOR │
            │    │          │
            │    │ Improve  │
            │    │ design   │
            │    └────┬─────┘
            │         │
            │    done │
            │         │
            │         ↓
            │    ┌──────────┐
            │    │  VERIFY  │
            │    │          │
            │    │ Run full │
  fail      │    │ suite +  │
            │    │ lint +   │
            └────│ build    │
                 └────┬─────┘
                      │
                 pass │
                      │
                      ↓
                 [COMPLETE]
```

## State: PLANNING

**Prefix:** `⚪ TDD: PLANNING`

**Purpose:** Write a failing test that proves the requirement.

### Pre-Conditions
- User has provided a task/requirement/bug report
- No other TDD cycle in progress

### The Delete Rule

If production code exists before the test:
1. **Delete it immediately**
2. Do not keep as "reference"
3. Do not "adapt" it
4. Start fresh from the test

**Rationale:** Code written before tests is biased by implementation. TDD requires tests to drive design, not verify existing code.

### Actions
1. Analyze requirement - what behavior needs testing?
2. Identify edge cases
3. Write test using fn(args, deps) pattern
4. Use vitest-mock-extended: `const deps = mock<GetUserDeps>()`
5. Run test (use Bash tool)
6. **VERIFY test fails correctly** (MANDATORY - see Verify RED below)
7. Show exact failure message verbatim
8. Justify why failure proves test is correct

### Verify RED - Watch It Fail

**MANDATORY. Never skip.**

```bash
npm test path/to/test.test.ts
```

Confirm:
- Test fails (not errors)
- Failure message is expected
- Fails because feature missing (not typos)

**Test passes?** You're testing existing behavior. Fix test.
**Test errors?** Fix error, re-run until it fails correctly.

### Post-Conditions (ALL required before transition)
- [ ] Test written with proper deps mocking
- [ ] Test executed
- [ ] Test FAILED correctly (not setup error) - **VERIFIED by watching it fail**
- [ ] Failure message shown verbatim
- [ ] Failure is "meaningful" (assertion failure, not import error)

### Validation Before Transition
```
Pre-transition validation:
✓ Test written: [yes/no]
✓ Test executed: [yes/no]
✓ Test failed correctly: [yes - output above]
✓ Meaningful failure: [yes - justification]

Transitioning to RED.
```

### Transitions
- PLANNING → RED (test fails correctly)
- PLANNING → BLOCKED (cannot write valid test)

## State: RED

**Prefix:** `🔴 TDD: RED`

**Purpose:** Test IS failing. Implement ONLY what the error message demands.

### Pre-Conditions
- Test written and executed
- Test IS FAILING correctly
- Failure is meaningful (not setup/syntax error)

### The Hardcode Rule

Before implementing, announce:
```
Minimal implementation check:
- Error demands: [what the error literally says]
- Could hardcoded value work? [yes/no]
- If yes: [what hardcoded value]
- If no: [why real logic is required]
```

| Error Says | Do This |
|-----------|---------|
| `expected err('NOT_FOUND')` | `return err('NOT_FOUND')` |
| `expected ok(user)` | `return ok(mockUser)` |
| `expected count: 0` | `return { count: 0 }` |

Only add logic when tests FORCE you to.

### Actions
1. Read error message - what does it literally ask for?
2. Announce minimal implementation check
3. Implement ONLY what error demands (hardcode if possible)
4. Run test
5. **VERIFY test PASSES** (MANDATORY - see Verify GREEN below)
6. Run typecheck (`npm run typecheck`)
7. Run lint (`npm run lint`)
8. Show all output verbatim
9. Transition to GREEN

### Verify GREEN - Watch It Pass

**MANDATORY. Never skip.**

```bash
npm test path/to/test.test.ts
```

Confirm:
- Test passes
- Other tests still pass
- Output pristine (no errors, warnings)

**Test fails?** Fix code, not test.
**Other tests fail?** Fix now.

### Post-Conditions (ALL required)
- [ ] Implemented ONLY what error demanded
- [ ] Test executed and PASSES
- [ ] Code compiles (no TypeScript errors)
- [ ] Code lints (no ESLint errors)
- [ ] All output shown verbatim

### Validation Before Transition
```
Post-condition validation:
✓ Test PASSES: [yes - output above]
✓ Code compiles: [yes - output above]
✓ Code lints: [yes - output above]
✓ Implementation minimal: [justification]

Transitioning to GREEN.
```

### Critical Rules
- NEVER transition to GREEN without test PASS + compile + lint
- NEVER anticipate future errors - address THIS error only
- NEVER change test to match implementation - fix the code

### Transitions
- RED → GREEN (test passes, code compiles, code lints)
- RED → BLOCKED (cannot make test pass)
- RED → PLANNING (test failure reveals misunderstood requirement)

## State: GREEN

**Prefix:** `🟢 TDD: GREEN`

**Purpose:** Test IS passing. Assess code quality and decide next step.

### Pre-Conditions
- Test exists and PASSES
- Code compiles and lints
- Implementation is minimal

### Actions
1. Review implementation against patterns:

| Pattern | Check |
|---------|-------|
| fn(args, deps) | Is deps type explicit and minimal? |
| Result types | Are all error cases typed? |
| Validation | Is Zod at boundary only? |
| Naming | Domain-specific, not generic? |

2. Decide: Does code need refactoring?
3. If YES → REFACTOR
4. If NO → VERIFY

### Post-Conditions
- [ ] Test IS PASSING
- [ ] Code quality assessed
- [ ] Decision made: refactor or verify

### Transitions
- GREEN → REFACTOR (improvements needed)
- GREEN → VERIFY (code is clean)
- GREEN → RED (test starts failing - regression)

## State: REFACTOR

**Prefix:** `🔵 TDD: REFACTOR`

**Purpose:** Tests ARE passing. Improve design while keeping green.

### Pre-Conditions
- Tests ARE PASSING
- Refactoring needs identified

### Refactor Checklist

```typescript
// 1. Extract deps type
// BEFORE
async function getUser(
  args: { userId: string },
  deps: { db: Database; logger: Logger }
)

// AFTER
type GetUserDeps = { db: Database; logger: Logger };
async function getUser(args: { userId: string }, deps: GetUserDeps)

// 2. Type all errors
// BEFORE
return err('error')

// AFTER
type GetUserError = 'NOT_FOUND' | 'DB_ERROR';
return err<GetUserError>('NOT_FOUND')

// 3. Use domain names
// BEFORE
const data = await deps.db.get(id);

// AFTER
const user = await deps.db.findUser(userId);
```

### Actions
1. Apply ONE refactoring
2. Run tests - verify still pass
3. Repeat until no more improvements
4. Transition to VERIFY

### Post-Conditions
- [ ] Deps type is explicit and exported
- [ ] All error types are explicit in signature
- [ ] Names are domain-specific
- [ ] Tests still pass after each refactor

### When to Skip REFACTOR
- Code is already clean
- Single hardcoded value (generalize when second test forces it)

**Never skip when:**
- Deps type missing or inline
- Error types not explicit
- Generic names (data, util, result)

### Transitions
- REFACTOR → VERIFY (code quality satisfactory)
- REFACTOR → RED (refactor broke test)
- REFACTOR → BLOCKED (cannot refactor due to constraints)

## State: VERIFY

**Prefix:** `🟡 TDD: VERIFY`

**Purpose:** Run full test suite + lint + build before claiming complete.

### Actions
1. Run full test suite: `npm test`
2. Run lint: `npm run lint`
3. Run typecheck: `npm run typecheck`
4. Run build: `npm run build` (if applicable)
5. Show ALL output verbatim
6. If ALL pass → COMPLETE
7. If ANY fail → route appropriately

### Post-Conditions (ALL required)
- [ ] Full test suite executed - ALL pass
- [ ] Lint executed - passes
- [ ] Typecheck executed - passes
- [ ] Build executed - succeeds
- [ ] All output shown

### Validation Before Completion
```
Final validation:
✓ Full test suite: [X/X tests passed - output shown]
✓ Lint: [passed - output shown]
✓ Typecheck: [passed - output shown]
✓ Build: [succeeded - output shown]

TDD cycle COMPLETE.

Summary:
- Tests written: [count]
- Refactorings: [count]
```

### Transitions
- VERIFY → COMPLETE (all checks pass)
- VERIFY → RED (tests fail - regression)
- VERIFY → REFACTOR (lint fails - code quality)
- VERIFY → BLOCKED (build fails - structural issue)

## State: BLOCKED

**Prefix:** `⚠️ TDD: BLOCKED`

**Purpose:** Handle situations where progress cannot continue.

### Actions
1. Clearly explain blocking issue
2. Explain which state you were in
3. Explain what you were trying to do
4. Suggest possible resolutions
5. **STOP and wait for user guidance**

### Critical Rules
- NEVER improvise workarounds
- NEVER skip steps to "unblock" yourself
- ALWAYS stop and wait for user

### Transitions
- BLOCKED → [any state] (based on user guidance)

## State: VIOLATION

**Prefix:** `🔥 TDD: VIOLATION`

**Purpose:** Handle state machine violations.

### Triggers
- Forgot state announcement
- Skipped state
- Failed to validate post-conditions
- Claimed complete without evidence
- Changed test assertion to match implementation
- Implemented full solution when hardcode would work

### Actions
1. IMMEDIATELY announce: `🔥 TDD: VIOLATION`
2. Explain which rule was violated
3. Explain what you did wrong
4. Announce correct current state
5. Ask user permission to recover

### Example
```
🔥 TDD: VIOLATION

Violation: Implemented full user lookup logic when hardcoded
value would satisfy the single test case.

Correct action: Return hardcoded { id: '123', name: 'Alice' }

Recovering to RED to fix implementation...
```

## Test Structure for fn(args, deps)

```typescript
import { describe, it, expect } from 'vitest';
import { mock } from 'vitest-mock-extended';
import { getUser, type GetUserDeps } from './get-user';

describe('getUser', () => {
  it('returns err NOT_FOUND when user does not exist', async () => {
    // Arrange: mock deps
    const deps = mock<GetUserDeps>();
    deps.db.findUser.mockResolvedValue(null);

    // Act
    const result = await getUser({ userId: '123' }, deps);

    // Assert Result type
    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.error).toBe('NOT_FOUND');
    }
  });

  it('returns ok with user when found', async () => {
    const mockUser = { id: '123', name: 'Alice' };
    const deps = mock<GetUserDeps>();
    deps.db.findUser.mockResolvedValue(mockUser);

    const result = await getUser({ userId: '123' }, deps);

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.value).toEqual(mockUser);
    }
  });
});
```

## Meaningful vs Setup Failures

| Type | Example | Action |
|------|---------|--------|
| **Meaningful** | "expected err('NOT_FOUND') but got ok(user)" | Proceed to RED |
| **Meaningful** | "expected false, received true" | Proceed to RED |
| **Setup** | "Cannot find module './get-user'" | Fix import, stay in PLANNING |
| **Setup** | "Property 'findUser' does not exist" | Fix mock, stay in PLANNING |
| **Setup** | "TypeError: deps.db is undefined" | Fix setup, stay in PLANNING |

## Red Flags - STOP and Start Over

If you encounter any of these, **delete code and start over with TDD:**

- Code before test
- Test after implementation
- Test passes immediately (didn't watch it fail)
- Can't explain why test failed
- Tests added "later"
- Rationalizing "just this once"
- "I already manually tested it"
- "Keep as reference" or "adapt existing code"
- "Already spent X hours, deleting is wasteful"
- "TDD is dogmatic, I'm being pragmatic"
- "This is different because..."

**All of these mean: Delete code. Start over with TDD.**

## Common Rationalizations

| Excuse | Reality |
|--------|--------|
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after" | Tests passing immediately prove nothing. |
| "Tests after achieve same goals" | Tests-after = "what does this do?" Tests-first = "what should this do?" |
| "Already manually tested" | Ad-hoc ≠ systematic. No record, can't re-run. |
| "Deleting X hours is wasteful" | Sunk cost fallacy. Keeping unverified code is technical debt. |
| "Keep as reference, write tests first" | You'll adapt it. That's testing after. Delete means delete. |
| "Need to explore first" | Fine. Throw away exploration, start with TDD. |
| "Test hard = design unclear" | Listen to test. Hard to test = hard to use. |
| "TDD will slow me down" | TDD faster than debugging. Pragmatic = test-first. |
| "Manual test faster" | Manual doesn't prove edge cases. You'll re-test every change. |

**Thinking "skip TDD just this once"? Stop. That's rationalization.**

## Critical Rules Summary

| Rule | Enforcement |
|------|-------------|
| Iron Law | NO production code without failing test first |
| Delete code rule | If code exists before test, delete it |
| State announcement | EVERY message starts with state |
| Verify RED | MANDATORY - watch test fail |
| Verify GREEN | MANDATORY - watch test pass |
| No green without proof | Must see test pass output |
| Error message driven | Implement ONLY what error demands |
| Hardcode first | One test? Return expected value |
| Never change test | Fix implementation, not assertion |
| Validate before transition | Check all post-conditions |

## Never Use vi.mock() for App Logic

```typescript
// WRONG: vi.mock creates brittle path coupling
vi.mock('../infra/database', () => ({ db: mockDb }));

// CORRECT: Inject deps, mock with vitest-mock-extended
const deps = mock<GetUserDeps>();
deps.db.findUser.mockResolvedValue(mockUser);
```

## Quick Reference

| State | Prefix | Action | Exit Condition |
|-------|--------|--------|----------------|
| PLANNING | ⚪ | Write failing test | Test fails meaningfully |
| RED | 🔴 | Minimum implementation | Test passes + compile + lint |
| GREEN | 🟢 | Assess quality | Decision: refactor or verify |
| REFACTOR | 🔵 | Improve design | Tests still pass, code clean |
| VERIFY | 🟡 | Full suite + lint + build | All green |
| BLOCKED | ⚠️ | Explain blocker, wait | User guidance |
| VIOLATION | 🔥 | Acknowledge, recover | Permission to continue |
