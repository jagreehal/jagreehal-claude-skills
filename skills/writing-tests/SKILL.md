---
name: writing-tests
description: "Principles for writing effective, maintainable tests. Covers naming conventions, assertion best practices, and comprehensive edge case checklists. Based on BugMagnet by Gojko Adzic."
version: 1.0.0
libraries: ["vitest", "vitest-mock-extended"]
---

# Writing Tests

How to write tests that catch bugs, document behavior, and remain maintainable.

> Based on [BugMagnet](https://github.com/gojko/bugmagnet-ai-assistant) by Gojko Adzic. Adapted with attribution and aligned with fn(args, deps) and Result type patterns.

## Core Principle

Test names describe outcomes, not actions. Assertions match test titles. Specific assertions catch specific bugs. One concept per test.

## Critical Rules

🚨 **Test names describe outcomes, not actions.** "returns empty array when input is null" not "test null input". The name IS the specification.

🚨 **Assertions must match test titles.** If the test claims to verify "different IDs", assert on the actual ID values—not just count or existence.

🚨 **Assert specific values, not types.** `expect(result.value).toEqual(['First.', ' Second.'])` not `expect(result).toBeDefined()`. Specific assertions catch specific bugs.

🚨 **One concept per test.** Each test verifies one behavior. If you need "and" in your test name, split it.

🚨 **Bugs cluster together.** When you find one bug, test related scenarios. The same misunderstanding often causes multiple failures.

## When This Applies

- Writing new tests (especially during TDD RED phase)
- Reviewing test quality
- Expanding test coverage
- Investigating discovered bugs
- Refactoring tests to be more maintainable

## Test Naming

**Pattern:** `[outcome] when [condition]`

### Good Names (Describe Outcomes)

```typescript
// ✅ GOOD: Describes what happens
it('returns empty array when input is null', () => {});
it('returns err NOT_FOUND when user does not exist', () => {});
it('calculates tax correctly for tax-exempt items', () => {});
it('preserves original order when duplicates removed', () => {});
it('returns ok with user when found in database', () => {});
```

### Bad Names (Describe Actions)

```typescript
// ❌ BAD: Describes what you're doing, not what happens
it('test null input', () => {});           // What about null input?
it('should work', () => {});                // What does "work" mean?
it('handles edge cases', () => {});         // Which edge cases?
it('email validation test', () => {});      // What's being validated?
it('test getUser', () => {});               // What does getUser do?
```

### The Specification Test

Your test name should read like a specification. If someone reads ONLY the test names, they should understand the complete behavior of the system.

```typescript
describe('getUser', () => {
  it('returns ok with user when found in database', () => {});
  it('returns err NOT_FOUND when user does not exist', () => {});
  it('returns err DB_ERROR when database connection fails', () => {});
  it('returns err VALIDATION_ERROR when userId is empty string', () => {});
});

// Reading just these names tells you everything getUser does.
```

## Assertion Best Practices

### Assert Specific Values

```typescript
// ❌ WEAK - passes even if completely wrong data
it('returns user when found', async () => {
  const result = await getUser({ userId: '123' }, deps);
  expect(result).toBeDefined();
  expect(result.ok).toBeTruthy();
  if (result.ok) {
    expect(result.value).toBeTruthy();
  }
});

// ✅ STRONG - catches actual bugs
it('returns ok with user when found in database', async () => {
  const mockUser = { id: '123', name: 'Alice', email: 'alice@test.com' };
  const deps = mock<GetUserDeps>();
  deps.db.findUser.mockResolvedValue(mockUser);

  const result = await getUser({ userId: '123' }, deps);

  expect(result.ok).toBe(true);
  if (result.ok) {
    expect(result.value).toEqual(mockUser);
    expect(result.value.email).toBe('alice@test.com');
  }
});
```

### Match Assertions to Test Title

```typescript
// ❌ TEST SAYS "different IDs" BUT ASSERTS COUNT
it('generates different IDs for each call', () => {
  const id1 = generateId();
  const id2 = generateId();
  expect([id1, id2]).toHaveLength(2);  // WRONG: doesn't check they're different!
});

// ✅ ACTUALLY VERIFIES DIFFERENT IDs
it('generates different IDs for each call', () => {
  const id1 = generateId();
  const id2 = generateId();
  expect(id1).not.toBe(id2);  // RIGHT: verifies the claim
  expect(id1).toMatch(/^[a-z0-9-]+$/);  // Also verify format
  expect(id2).toMatch(/^[a-z0-9-]+$/);
});
```

### Testing Result Types

When testing functions that return `Result<T, E>`, assert on the specific error type and value:

```typescript
// ❌ WEAK - doesn't verify error type
it('handles missing user', async () => {
  const result = await getUser({ userId: 'missing' }, deps);
  expect(result.ok).toBe(false);
});

// ✅ STRONG - verifies exact error
it('returns err NOT_FOUND when user does not exist', async () => {
  const deps = mock<GetUserDeps>();
  deps.db.findUser.mockResolvedValue(null);

  const result = await getUser({ userId: 'missing' }, deps);

  expect(result.ok).toBe(false);
  if (!result.ok) {
    expect(result.error).toBe('NOT_FOUND');
  }
});
```

### Avoid Implementation Coupling

```typescript
// ❌ BRITTLE - tests implementation details
it('queries database with correct SQL', async () => {
  const deps = mock<GetUserDeps>();
  await getUser({ userId: '123' }, deps);
  expect(deps.db.findUser).toHaveBeenCalledWith('123');
  // What if we change to findUser({ where: { id: '123' } })? Test breaks.
});

// ✅ FLEXIBLE - tests behavior
it('returns ok with user when found in database', async () => {
  const mockUser = { id: '123', name: 'Alice' };
  const deps = mock<GetUserDeps>();
  deps.db.findUser.mockResolvedValue(mockUser);

  const result = await getUser({ userId: '123' }, deps);

  expect(result.ok).toBe(true);
  if (result.ok) {
    expect(result.value).toEqual(mockUser);
  }
  // Implementation can change (SQL, ORM, etc.) and test still passes
});
```

## Test Structure

### Arrange-Act-Assert

```typescript
it('calculates total with tax for non-exempt items', () => {
  // Arrange: Set up test data and mocks
  const item = { price: 100, taxExempt: false };
  const taxRate = 0.1;
  const deps = mock<CalculateTotalDeps>();
  deps.config.getTaxRate.mockReturnValue(taxRate);

  // Act: Execute the behavior
  const result = calculateTotal({ item }, deps);

  // Assert: Verify the outcome
  expect(result.ok).toBe(true);
  if (result.ok) {
    expect(result.value).toBe(110);
  }
});
```

### One Concept Per Test

```typescript
// ❌ MULTIPLE CONCEPTS - hard to diagnose failures
it('validates and processes order', () => {
  expect(validate(order)).toBe(true);
  expect(process(order).ok).toBe(true);
  if (process(order).ok) {
    expect(sendEmail).toHaveBeenCalled();
  }
});

// ✅ SINGLE CONCEPT - clear failures
it('accepts valid orders', () => {
  const result = validate(validOrder);
  expect(result).toBe(true);
});

it('rejects orders with negative quantities', () => {
  const result = validate(negativeQuantityOrder);
  expect(result).toBe(false);
});

it('sends confirmation email after processing', async () => {
  const deps = mock<ProcessOrderDeps>();
  deps.mailer.send.mockResolvedValue(undefined);
  
  const result = await processOrder(validOrder, deps);
  
  expect(result.ok).toBe(true);
  expect(deps.mailer.send).toHaveBeenCalledWith(validOrder.customerEmail);
});
```

## Edge Case Checklists

When testing a function, systematically consider these edge cases based on input types.

### Numbers

- [ ] Zero
- [ ] Negative numbers
- [ ] Very large numbers (near MAX_SAFE_INTEGER)
- [ ] Very small numbers (near MIN_SAFE_INTEGER)
- [ ] Decimal precision (0.1 + 0.2)
- [ ] NaN
- [ ] Infinity / -Infinity
- [ ] Boundary values (off-by-one at limits)

```typescript
describe('calculateTotal', () => {
  it('returns err INVALID when price is negative', () => {});
  it('returns err INVALID when price is zero', () => {});
  it('returns err INVALID when price is NaN', () => {});
  it('handles very large prices near MAX_SAFE_INTEGER', () => {});
  it('handles decimal precision correctly', () => {
    // 0.1 + 0.2 = 0.30000000000000004
  });
});
```

### Strings

- [ ] Empty string `""`
- [ ] Whitespace only `"   "`
- [ ] Very long strings (10K+ characters)
- [ ] Unicode: emojis 👨‍👩‍👧‍👦, RTL text, combining characters
- [ ] Special characters: quotes, backslashes, null bytes
- [ ] SQL/HTML/script injection patterns
- [ ] Leading/trailing whitespace
- [ ] Mixed case sensitivity

```typescript
describe('validateEmail', () => {
  it('returns err INVALID when email is empty string', () => {});
  it('returns err INVALID when email is whitespace only', () => {});
  it('handles unicode characters in email', () => {});
  it('handles plus signs in email addresses', () => {
    // user+tag@example.com
  });
});
```

### Collections (Arrays, Objects, Maps)

- [ ] Empty collection `[]`, `{}`
- [ ] Single element
- [ ] Duplicates
- [ ] Nested structures
- [ ] Circular references
- [ ] Very large collections (performance)
- [ ] Sparse arrays
- [ ] Mixed types in arrays

```typescript
describe('removeDuplicates', () => {
  it('returns empty array when input is empty', () => {});
  it('returns same array when input has one element', () => {});
  it('removes duplicate values', () => {});
  it('preserves order of first occurrence', () => {});
  it('handles nested arrays correctly', () => {});
});
```

### Dates and Times

- [ ] Leap years (Feb 29)
- [ ] Daylight saving transitions
- [ ] Timezone boundaries
- [ ] Midnight (00:00:00)
- [ ] End of day (23:59:59)
- [ ] Year boundaries (Dec 31 → Jan 1)
- [ ] Invalid dates (Feb 30, Month 13)
- [ ] Unix epoch edge cases
- [ ] Far future/past dates

```typescript
describe('calculateAge', () => {
  it('handles leap year birthdays correctly', () => {});
  it('handles birthday on Feb 29 in non-leap years', () => {});
  it('handles timezone boundaries correctly', () => {});
  it('returns err INVALID when date is in the future', () => {});
});
```

### Null and Undefined

- [ ] `null` input
- [ ] `undefined` input
- [ ] Missing optional properties
- [ ] Explicit `undefined` vs missing key

```typescript
describe('getUser', () => {
  it('returns err NOT_FOUND when user is null', () => {});
  it('returns err VALIDATION_ERROR when userId is undefined', () => {});
  it('handles missing optional properties gracefully', () => {});
});
```

### Domain-Specific

- [ ] Email: valid formats, edge cases (plus signs, subdomains)
- [ ] URLs: protocols, ports, special characters, relative paths
- [ ] Phone numbers: international formats, extensions
- [ ] Addresses: Unicode, multi-line, missing components
- [ ] Currency: rounding, different currencies, zero amounts
- [ ] Percentages: 0%, 100%, over 100%

```typescript
describe('validateEmail', () => {
  it('accepts emails with plus signs', () => {});
  it('accepts emails with subdomains', () => {});
  it('rejects emails without @ symbol', () => {});
  it('rejects emails with invalid TLD', () => {});
});
```

### Violated Domain Constraints

These test implicit assumptions in your domain:

- [ ] Uniqueness violations (duplicate IDs, emails)
- [ ] Missing required relationships (orphaned records)
- [ ] Ordering violations (events out of sequence)
- [ ] Range breaches (age -1, quantity 1000000)
- [ ] State inconsistencies (shipped but not paid)
- [ ] Format mismatches (expected JSON, got XML)
- [ ] Temporal ordering (end before start)

```typescript
describe('createOrder', () => {
  it('returns err DUPLICATE when order ID already exists', () => {});
  it('returns err INVALID when customer does not exist', () => {});
  it('returns err INVALID when quantity exceeds maximum', () => {});
  it('returns err INVALID when order date is after ship date', () => {});
});
```

## Bug Clustering

When you discover a bug, don't stop—explore related scenarios:

1. **Same function, similar inputs** - If null fails, test undefined, empty string
2. **Same pattern, different locations** - If one endpoint mishandles auth, check others
3. **Same developer assumption** - If off-by-one here, check other boundaries
4. **Same data type** - If dates fail at DST, check other time edge cases

```typescript
// Found bug: getUser returns wrong error for null
// Don't just fix null, test related scenarios:

it('returns err NOT_FOUND when user is null', () => {});
it('returns err NOT_FOUND when user is undefined', () => {});
it('returns err VALIDATION_ERROR when userId is empty string', () => {});
it('returns err VALIDATION_ERROR when userId is whitespace', () => {});
it('returns err VALIDATION_ERROR when userId is null', () => {});
```

## When Tempted to Cut Corners

- If your test name says "test" or "should work": STOP. What outcome are you actually verifying? Name it specifically.

- If you're asserting `toBeDefined()` or `toBeTruthy()`: STOP. What value do you actually expect? Assert that instead.

- If your assertion doesn't match your test title: STOP. Either fix the assertion or rename the test. They must agree.

- If you're testing multiple concepts in one test: STOP. Split it. Future you debugging a failure will thank you.

- If you found a bug and wrote one test: STOP. Bugs cluster. What related scenarios might have the same problem?

- If you're skipping edge cases because "that won't happen": STOP. It will happen. In production. At 3 AM.

## Integration with Other Skills

**With TDD Workflow:** This skill guides the RED phase—how to write the failing test well. Use outcome-based naming and specific assertions from the start.

**With Testing Strategy:** This skill complements the test pyramid. Unit tests (with mocks) and integration tests (with real DB) both benefit from good naming and edge case coverage.

**With fn(args, deps):** Tests use `mock<DepsType>()` from vitest-mock-extended. No `vi.mock()` for application logic. See `testing-strategy` for details.

**With Result Types:** Tests assert on `result.ok` and specific error types. See `tdd-workflow` for Result type testing patterns.

**With Design Principles:** Testable code follows design principles. Hard-to-test code often has design problems. If you can't write a good test, the function might be doing too much.

## Examples with fn(args, deps) Pattern

### Complete Example: Testing a User Function

```typescript
import { describe, it, expect } from 'vitest';
import { mock } from 'vitest-mock-extended';
import { getUser, type GetUserDeps } from './get-user';

describe('getUser', () => {
  it('returns ok with user when found in database', async () => {
    // Arrange
    const mockUser = { id: '123', name: 'Alice', email: 'alice@test.com' };
    const deps = mock<GetUserDeps>();
    deps.db.findUser.mockResolvedValue(mockUser);

    // Act
    const result = await getUser({ userId: '123' }, deps);

    // Assert
    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.value).toEqual(mockUser);
      expect(result.value.email).toBe('alice@test.com');
    }
  });

  it('returns err NOT_FOUND when user does not exist', async () => {
    // Arrange
    const deps = mock<GetUserDeps>();
    deps.db.findUser.mockResolvedValue(null);

    // Act
    const result = await getUser({ userId: 'missing' }, deps);

    // Assert
    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.error).toBe('NOT_FOUND');
    }
  });

  it('returns err VALIDATION_ERROR when userId is empty string', async () => {
    // Arrange
    const deps = mock<GetUserDeps>();

    // Act
    const result = await getUser({ userId: '' }, deps);

    // Assert
    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.error).toBe('VALIDATION_ERROR');
    }
  });

  it('returns err DB_ERROR when database connection fails', async () => {
    // Arrange
    const deps = mock<GetUserDeps>();
    deps.db.findUser.mockRejectedValue(new Error('Connection failed'));

    // Act
    const result = await getUser({ userId: '123' }, deps);

    // Assert
    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.error).toBe('DB_ERROR');
    }
  });
});
```

## The Rules

1. **Test names describe outcomes** - "returns X when Y" not "test Y"
2. **Assertions match test titles** - If title says "different IDs", assert they're different
3. **Assert specific values** - `toEqual(expected)` not `toBeDefined()`
4. **One concept per test** - Split tests that need "and" in the name
5. **Bugs cluster together** - When you find one, test related scenarios
6. **Use edge case checklists** - Systematically cover numbers, strings, dates, null, domain constraints
7. **Test behavior, not implementation** - Assert on Result types, not internal calls
8. **Use Arrange-Act-Assert** - Clear structure makes tests readable
9. **No vi.mock() for app logic** - Use `mock<DepsType>()` from vitest-mock-extended
10. **Test Result types explicitly** - Assert on `result.ok` and specific error types
