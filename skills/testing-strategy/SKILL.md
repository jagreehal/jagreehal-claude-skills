---
name: testing-strategy
description: Structures a test suite as a pyramid of unit, integration, load, and chaos tests where dependency injection enables typed mocking without module interception. Use when deciding what kind of test to write, setting up vitest with typed mocks, naming test files by type, or wiring database guardrails and Faker test data.
version: 1.1.0
libraries: ["vitest", "vitest-mock-extended", "@faker-js/faker", "k6"]
---

# Testing Strategy

## Overview

A test suite is a pyramid: many fast unit tests at the base, fewer integration tests above, and a thin top of load and chaos tests. Each layer answers a different question and catches a different class of bug.

**Why this matters:** Testability drives design. The `fn(args, deps)` pattern makes functions testable: you mock only the dependencies a function uses, with `vitest-mock-extended`, and never reach for `vi.mock` or module interception. When code is hard to test, that is a design signal, not a testing problem. Investing effort according to the pyramid keeps the suite fast and reliable: most failures should surface in milliseconds at the unit layer, not minutes later in a flaky end-to-end run.

```
       △  Chaos Tests ("Does it survive failures?")
      /|\
     / | \  Load Tests ("Does it scale?")
    /--+--\
   /   |   \ Integration Tests ("Does the stack work?")
  /----+----\
       |     Unit Tests ("Does the logic work?")
```

## When to Use

- Deciding which kind of test a given behavior needs
- Setting up vitest with typed mocks and database guardrails
- Naming and organizing test files by type
- Generating realistic test data with Faker
- Mocking Prisma or other fluent clients in unit tests

**When NOT to use:** Writing the assertions inside an individual test (see [writing-tests](../writing-tests/SKILL.md)); driving the red-green-refactor loop (see [tdd-workflow](../tdd-workflow/SKILL.md)); building load profiles in depth (see [performance-testing](../performance-testing/SKILL.md)).

**Related:** [tdd-workflow](../tdd-workflow/SKILL.md) drives test-first development; [writing-tests](../writing-tests/SKILL.md) covers naming and assertions; [performance-testing](../performance-testing/SKILL.md) expands the load and chaos layers; [fn-args-deps](../fn-args-deps/SKILL.md) is the pattern that makes mocking trivial; [result-types](../result-types/SKILL.md) defines the error shapes these tests assert on.

## Choosing a Test Layer

| Question to answer | Layer | What it touches | Speed |
|--------------------|-------|-----------------|-------|
| Does the logic work? | Unit | Mocked deps, no I/O | Milliseconds |
| Does the stack work? | Integration | Real localhost database | Seconds |
| Does it scale? | Load | Running service under k6 | Minutes |
| Does it survive failures? | Chaos | Injected latency/failures | Minutes |

```
Is it pure logic or a function with injectable deps?
  → Unit test (mock deps)
Does it cross a real boundary (DB, file system)?
  → Integration test (.test.int.ts, localhost only)
Does it need to hold up under concurrent traffic?
  → Load test (k6) — see performance-testing
Does it need to survive dependency failures?
  → Chaos test — see performance-testing
```

## Required Behaviors

### 1. Unit Tests with Explicit Deps

Use `vitest-mock-extended` for typed mocks:

```typescript
import { describe, it, expect } from 'vitest';
import { mock } from 'vitest-mock-extended';
import { getUser, type GetUserDeps } from './get-user';

it('returns user when found', async () => {
  const mockUser = { id: '123', name: 'Alice', email: 'alice@test.com' };

  // Create typed mock from deps interface
  const deps = mock<GetUserDeps>();
  deps.db.findUser.mockResolvedValue(mockUser);

  const result = await getUser({ userId: '123' }, deps);

  expect(result.ok).toBe(true);
  if (result.ok) {
    expect(result.value).toEqual(mockUser);
  }
});
```

### 2. Integration Tests with Real Database

Use `.test.int.ts` suffix for integration tests:

```typescript
// user.test.int.ts
import { describe, it, expect, beforeAll } from 'vitest';
import { createTestDb } from '../test-utils/db';
import { getUser } from './get-user';

describe('getUser integration', () => {
  let db: Database;

  beforeAll(async () => {
    db = await createTestDb();
  });

  it('returns user from real database', async () => {
    await db.saveUser({ id: '123', name: 'Alice' });

    const result = await getUser({ userId: '123' }, { db });

    expect(result.ok).toBe(true);
  });
});
```

### 3. Database Guardrails

Prevent tests from hitting non-localhost databases:

```typescript
// vitest.setup.ts
const DB_URL = process.env.DATABASE_URL || '';

if (!DB_URL.includes('localhost') && !DB_URL.includes('127.0.0.1')) {
  throw new Error(
    'Integration tests must use localhost database. ' +
    `Current DATABASE_URL: ${DB_URL}`
  );
}
```

### 4. Load Tests with k6

```javascript
// load/smoke.js - Quick validation
import http from 'k6/http';
import { check } from 'k6';

export const options = {
  vus: 1,
  duration: '30s',
  thresholds: {
    http_req_duration: ['p(95)<500'],
  },
};

export default function () {
  const res = http.get('http://localhost:3000/api/users/1');
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
  });
}
```

```javascript
// load/stress.js - Find breaking point
export const options = {
  stages: [
    { duration: '2m', target: 100 },
    { duration: '5m', target: 100 },
    { duration: '2m', target: 200 },
    { duration: '5m', target: 200 },
    { duration: '2m', target: 0 },
  ],
};
```

## Test File Naming

| File Pattern | Type | Purpose |
|-------------|------|---------|
| `*.test.ts` | Unit | Mock deps, fast, isolated |
| `*.test.int.ts` | Integration | Real database, slower |
| `load/*.js` | Load | k6 scripts |
| `chaos/*.ts` | Chaos | Inject failures |

## Why fn(args, deps) Enables Testing

With classes, you must satisfy the entire constructor:

```typescript
// Class: must mock everything
new UserService(db, logger, mailer, cache, metrics);

// Even if getUser only needs db and logger
```

With fn(args, deps), you only mock what the function uses:

```typescript
// Function: mock only what you need
const deps = mock<GetUserDeps>();  // Just { db, logger }
await getUser({ userId }, deps);
```

## Testing Result Types

```typescript
it('handles not found error', async () => {
  const deps = mock<GetUserDeps>();
  deps.db.findUser.mockResolvedValue(null);

  const result = await getUser({ userId: '123' }, deps);

  expect(result.ok).toBe(false);
  if (!result.ok) {
    expect(result.error).toBe('NOT_FOUND');
  }
});
```

## Prisma Mocking with mockDeep

For Prisma clients, use `mockDeep` for nested method access. Create a helper function:

```typescript
// src/test-utils/prisma-mock.ts
import { PrismaClient } from '@prisma/client';
import { mockDeep } from 'vitest-mock-extended';

export function createMockPrisma() {
  // mockDeep is essential for Prisma's nested fluent API
  // (e.g., db.order.findUnique) - it mocks all nested properties automatically
  const mockPrisma = mockDeep<PrismaClient>();

  // Handle $transaction by executing the callback with the mock
  mockPrisma.$transaction.mockImplementation(async (callback) => {
    return callback(mockPrisma);
  });

  return mockPrisma;
}
```

Now in your unit tests:

```typescript
import { createMockPrisma } from '../test-utils/prisma-mock';

it('creates user in database', async () => {
  const prisma = createMockPrisma();
  prisma.user.create.mockResolvedValue({ id: '1', name: 'Alice', email: 'alice@test.com' });

  const deps = { db: prisma, logger: mock<Logger>() };
  const result = await createUser({ name: 'Alice', email: 'alice@test.com' }, deps);

  expect(result.ok).toBe(true);
  expect(prisma.user.create).toHaveBeenCalledWith({
    data: { name: 'Alice', email: 'alice@test.com' },
  });
});
```

## Test Data with Faker

Use Faker for realistic test data. Create helper functions for integration tests:

```typescript
// src/test-utils/stubs.ts
import { faker } from '@faker-js/faker';
import prisma from '../db';

/**
 * Creates a customer with realistic fake data.
 * Use in integration tests that need a real database record.
 */
export async function createTestCustomer(overrides: {
  email?: string;
  name?: string;
} = {}) {
  return prisma.customer.create({
    data: {
      email: overrides.email ?? faker.internet.email(),
      name: overrides.name ?? faker.person.fullName(),
      phone: faker.phone.number(),
      createdAt: faker.date.past(),
    },
  });
}

/**
 * Creates a customer with associated orders for integration testing.
 */
export async function createTestCustomerWithOrders(overrides: {
  orderCount?: number;
  orderStatus?: 'pending' | 'shipped' | 'delivered';
} = {}) {
  const customer = await createTestCustomer();

  const orders = await Promise.all(
    Array.from({ length: overrides.orderCount ?? 1 }).map(() =>
      prisma.order.create({
        data: {
          customerId: customer.id,
          status: overrides.orderStatus ?? 'pending',
          total: faker.number.int({ min: 1000, max: 100000 }),
          shippingAddress: faker.location.streetAddress(),
        },
      })
    )
  );

  return { customer, orders };
}
```

**Why no cleanup?** Each test uses `faker.string.uuid()` for IDs and `faker.internet.email()` for emails. Tests create their own unique data and query only that data. No shared state means no cleanup needed, and tests can run in parallel.

For unit tests, create stub objects (no database):

```typescript
// src/test-utils/stubs.ts (continued)

/**
 * Creates realistic stub data for unit tests (no database).
 * Use when you need typed test data but don't want database overhead.
 */
export const stubs = {
  customer: (overrides: Partial<Customer> = {}): Customer => ({
    id: faker.string.uuid(),
    email: faker.internet.email(),
    name: faker.person.fullName(),
    phone: faker.phone.number(),
    createdAt: faker.date.past(),
    ...overrides,
  }),

  order: (overrides: Partial<Order> = {}): Order => ({
    id: faker.string.uuid(),
    customerId: faker.string.uuid(),
    status: 'pending',
    total: faker.number.int({ min: 1000, max: 100000 }),
    shippingAddress: faker.location.streetAddress(),
    createdAt: faker.date.past(),
    ...overrides,
  }),
};

// Usage in unit tests:
const order = stubs.order({ status: 'shipped' });
deps.db.findOrder.mockResolvedValue(order);
```

## vitest.setup.ts Configuration

```typescript
// vitest.setup.ts
import { beforeAll, afterAll, afterEach } from 'vitest';

// Database guardrails
const DB_URL = process.env.DATABASE_URL || '';
if (!DB_URL.includes('localhost') && !DB_URL.includes('127.0.0.1')) {
  throw new Error(
    'Integration tests must use localhost database. ' +
    `Current DATABASE_URL: ${DB_URL}`
  );
}

// Global test timeout
beforeAll(() => {
  vi.setConfig({ testTimeout: 10000 });
});

// Reset mocks between tests
afterEach(() => {
  vi.clearAllMocks();
});

// Cleanup
afterAll(async () => {
  // Close database connections, etc.
});
```

Add to `vitest.config.ts`:

```typescript
export default defineConfig({
  test: {
    setupFiles: ['./vitest.setup.ts'],
    globals: true,
  },
});
```

## The Rules

1. **Unit tests mock deps explicitly** - No vi.mock or module mocking
2. **Integration tests use real database** - localhost only
3. **Database guardrails prevent accidents** - Fail if not localhost
4. **Load tests validate scalability** - k6 scripts per endpoint
5. **Name files by test type** - `.test.ts`, `.test.int.ts`
6. **Use mockDeep for Prisma** - Handles nested method chains
7. **Use Faker for test data** - Realistic, consistent test fixtures

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'll just mock the whole module with vi.mock" | Module mocks couple tests to import paths and break on refactor. Inject deps and mock the typed interface. |
| "Everything should be an integration test for confidence" | Slow, flaky suites get ignored. Push logic into unit tests; reserve integration tests for real boundaries. |
| "Pointing the test DB at staging is fine" | One bad run mutates shared data. Guardrails must fail unless the URL is localhost. |
| "I'll write a load test for every endpoint" | Load tests belong at the thin top of the pyramid. Cover critical paths, not everything. |
| "I'll hand-write test fixtures" | Hand-written data hides edge cases and drifts from reality. Use Faker for realistic, unique data. |

## Red Flags

- `vi.mock()` used to replace application modules instead of injecting deps
- Integration tests that can reach a non-localhost database
- A suite where most tests are slow integration or end-to-end tests
- Shared mutable fixtures requiring cleanup between tests
- Prisma mocked manually instead of with `mockDeep`
- Test files with no naming convention to distinguish unit from integration

## Verification

- [ ] Each test lives at the right pyramid layer for what it verifies
- [ ] Unit tests use `mock<DepsType>()`, never `vi.mock` for app logic
- [ ] Integration tests use `.test.int.ts` and a localhost-only database
- [ ] Database guardrails throw on any non-localhost URL
- [ ] Prisma clients are mocked with `mockDeep`
- [ ] Test data comes from Faker with unique IDs so tests run in parallel
- [ ] `vitest.setup.ts` resets mocks between tests
