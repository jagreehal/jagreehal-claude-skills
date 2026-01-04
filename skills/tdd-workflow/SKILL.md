---
name: tdd-workflow
description: "Test-driven development with Result types. Red-green-refactor cycles using vitest-mock-extended, explicit deps mocking, and Result assertions."
version: 1.0.0
libraries: ["vitest", "vitest-mock-extended"]
---

# TDD Workflow

Strict red-green-refactor with Result types and dependency injection.

## State Machine

```
USER REQUEST
     │
     ▼
┌─────────┐
│   RED   │ ◄─── Write failing test
└────┬────┘
     │ test fails correctly
     ▼
┌─────────┐
│  GREEN  │ ◄─── Minimum code to pass
└────┬────┘
     │ test passes
     ▼
┌─────────┐
│REFACTOR │ ◄─── Improve design, keep green
└────┬────┘
     │ still passes
     ▼
┌─────────┐
│ VERIFY  │ ◄─── Full suite + lint + build
└─────────┘
```

## State Prefix

Every message announces state:

```
[RED] Writing test for getUser returning NOT_FOUND...
[GREEN] Test passes. Checking if refactor needed...
[REFACTOR] Extracting deps type. Running test...
[VERIFY] Running full suite...
```

## RED: Write Failing Test

### Test Structure for fn(args, deps)

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
});
```

### RED Rules

1. **Test behavior, not implementation** - Assert on Result, not internal calls
2. **Use vitest-mock-extended** - `mock<DepsType>()` for typed mocks
3. **One assertion focus** - Each test proves one behavior
4. **Run test, see it fail** - Verify failure message makes sense

### Meaningful vs Setup Failures

```
MEANINGFUL (proceed to GREEN):
  - "expected err('NOT_FOUND') but got ok(user)"
  - "expected 404 but got 200"

SETUP (fix before proceeding):
  - "Cannot find module './get-user'"
  - "Property 'findUser' does not exist on type"
  - "TypeError: deps.db is undefined"
```

## GREEN: Minimum Implementation

### Implement ONLY What Error Demands

```
Error: expected result.ok to be false, got true

WRONG: Implement full validation, logging, error handling
RIGHT: Return err('NOT_FOUND') when user is null
```

### The Hardcode-Then-Generalize Pattern

```typescript
// First test: expects err('NOT_FOUND')
// Minimum implementation:
if (!user) return err('NOT_FOUND');
return ok(user);

// Second test: expects ok(user) with specific fields
// Generalize only when forced by multiple tests
```

### GREEN Rules

1. **Hardcode if possible** - One test? Return the expected value
2. **No anticipating** - Don't handle errors not yet tested
3. **Keep it ugly** - Clean code comes in REFACTOR
4. **Run test, see it pass** - Must see green before proceeding

## REFACTOR: Improve Design

### Check Against Patterns

| Pattern | Check |
|---------|-------|
| fn(args, deps) | Is deps type explicit and minimal? |
| Result types | Are all error cases typed? |
| Validation | Is Zod at boundary only? |
| Naming | Are names domain-specific, not generic? |

### Refactor Candidates

```typescript
// BEFORE: inline deps type
async function getUser(
  args: { userId: string },
  deps: { db: Database; logger: Logger }
)

// AFTER: extracted type
type GetUserDeps = { db: Database; logger: Logger };

async function getUser(
  args: { userId: string },
  deps: GetUserDeps
)
```

### REFACTOR Rules

1. **Run tests after each change** - Never break green
2. **Small steps** - One refactor at a time
3. **Apply patterns** - fn(args, deps), Result, validation-boundary
4. **No new behavior** - Refactor preserves behavior, doesn't add it

### When to Skip REFACTOR

Skip refactoring when:
- Code is already clean (nothing to improve)
- Exploring/prototyping (will rewrite anyway)
- Single hardcoded value (generalize later when second test forces it)

**Never skip refactor when:**
- Deps type is missing or too broad
- Error types are not explicit in signature
- Code has duplication that obscures intent

## VERIFY: Full Validation

Before completing, run ALL:

```bash
npm test           # Full test suite
npm run lint       # ESLint passes
npm run typecheck  # tsc --noEmit passes
npm run build      # Build succeeds (if applicable)
```

### VERIFY Rules

1. **All tests pass** - Not just the new one
2. **No lint errors** - Including new code
3. **Types check** - No `any` leaks, no `as` casts
4. **Show output** - Copy actual command output

## Result Type Testing Patterns

### Testing ok() path

```typescript
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
```

### Testing err() path

```typescript
it('returns err NOT_FOUND when user missing', async () => {
  const deps = mock<GetUserDeps>();
  deps.db.findUser.mockResolvedValue(null);

  const result = await getUser({ userId: '123' }, deps);

  expect(result.ok).toBe(false);
  if (!result.ok) {
    expect(result.error).toBe('NOT_FOUND');
  }
});
```

### Testing multiple error types

```typescript
it('returns err DB_ERROR on database failure', async () => {
  const deps = mock<GetUserDeps>();
  deps.db.findUser.mockRejectedValue(new Error('Connection failed'));

  const result = await getUser({ userId: '123' }, deps);

  expect(result.ok).toBe(false);
  if (!result.ok) {
    expect(result.error).toBe('DB_ERROR');
  }
});
```

## Violations

### Never Change Test to Pass

```
Test fails? Fix IMPLEMENTATION, not test.

VIOLATION: Changing expect(result.error).toBe('NOT_FOUND')
           to expect(result.error).toBe('ERROR')
           because implementation returns 'ERROR'

CORRECT:   Change implementation to return 'NOT_FOUND'
```

### Never Skip States

```
VIOLATION: Write test → Write full implementation → Skip refactor
CORRECT:   RED → GREEN (minimum) → REFACTOR → VERIFY
```

### Never Use vi.mock() for App Logic

```typescript
// WRONG: vi.mock creates brittle path coupling
vi.mock('../infra/database', () => ({ db: mockDb }));

// CORRECT: Inject deps, mock with vitest-mock-extended
const deps = mock<GetUserDeps>();
deps.db.findUser.mockResolvedValue(mockUser);
```

## Quick Reference

| State | Action | Exit Condition |
|-------|--------|----------------|
| RED | Write failing test | Test fails meaningfully |
| GREEN | Minimum implementation | Test passes |
| REFACTOR | Apply patterns | Tests still pass |
| VERIFY | Full suite + lint + build | All green |
