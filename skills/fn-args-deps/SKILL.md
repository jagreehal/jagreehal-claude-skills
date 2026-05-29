---
name: fn-args-deps
description: Enforces the fn(args, deps) pattern, business logic as functions with explicit dependency injection instead of classes. Use when writing or refactoring TypeScript business logic, replacing service classes, deciding how to structure dependencies, setting up a composition root, or making functions testable with mocked collaborators.
version: 1.1.0
libraries: ["vitest-mock-extended"]
---

# Functions Over Classes: fn(args, deps)

## Overview

All business logic is written as plain functions with the signature `fn(args, deps)`, never as service classes:

- **args**: per-call input data (varies on every invocation)
- **deps**: long-lived collaborators (injected infrastructure: db, logger, mailer)

The two parameters are kept separate because they have **different lifetimes**. `args` change every call; `deps` are wired once and reused. Splitting them makes dependency bloat visible at the type level (a function whose `deps` keeps growing is doing too much), keeps composition trivial, and makes every function testable by passing a mock `deps`: no class instantiation, no `beforeEach` wiring, no hidden `this`.

This pattern is the foundation the rest of the architecture builds on: `result-types` defines what these functions return, `validation-boundary` defines what their `args` are trusted to contain, and `testing-strategy` relies on the injected `deps` to mock collaborators.

## When to Use

- Writing any new business-logic function
- Refactoring a service class into composable functions
- Deciding whether a dependency should be injected or imported
- Setting up a composition root to wire dependencies once
- Making code testable without instantiating heavy objects

**When NOT to use:** Framework-mandated classes (NestJS providers, Express error middleware), stateful resources with a lifecycle (connection pools, caches), and fluent builders. In those cases use a thin class wrapper that delegates to pure `fn(args, deps)` functions. See [When Classes ARE Acceptable](#when-classes-are-acceptable).

**Related:** `result-types` (what the function returns), `validation-boundary` (what `args` are trusted to contain), `testing-strategy` and `writing-tests` (mocking `deps`), `observability` (wrapping these functions), `strict-typescript` (the compiler flags that enforce this).

For how this layer fits the whole system, see [`references/architecture.md`](../../references/architecture.md).

## Required Behaviors

### 1. Per-Function Dependency Types

ALWAYS declare explicit deps types for each function:

```typescript
// CORRECT
type GetUserDeps = {
  db: Database;
  logger: Logger;
};

async function getUser(
  args: { userId: string },
  deps: GetUserDeps
): Promise<User | null> {
  deps.logger.info(`Getting user ${args.userId}`);
  return deps.db.findUser(args.userId);
}
```

```typescript
// WRONG - God object with all deps
async function getUser(
  args: { userId: string },
  deps: AllServiceDeps  // Contains mailer, cache, metrics that getUser doesn't use
): Promise<User | null>
```

### 2. No Classes for Business Logic

Classes become problematic when:
- 10+ methods accumulate over time
- Private helpers create implicit coupling via `this`
- Constructor grows to satisfy every method's needs

```typescript
// WRONG
class UserService {
  constructor(
    private db: Database,
    private logger: Logger,
    private mailer: Mailer,  // only createUser needs this
    private cache: Cache,     // only someOtherMethod needs this
  ) {}
}

// CORRECT
type GetUserDeps = { db: Database; logger: Logger };
type CreateUserDeps = { db: Database; logger: Logger; mailer: Mailer };
```

### 3. Factory at the Boundary (Composition Root)

Wire deps ONCE at the boundary, not at every call site:

```typescript
// user-service/index.ts
export function createUserService({ deps }: { deps: UserServiceDeps }) {
  return {
    getUser: ({ userId }: { userId: string }) =>
      getUser({ userId }, deps),
    createUser: ({ name, email }: { name: string; email: string }) =>
      createUser({ name, email }, deps),
  };
}

// main.ts (Composition Root)
const deps = { db, logger, mailer };
const userService = createUserService({ deps });

// Handlers stay clean
await userService.getUser({ userId: '123' });
```

### 4. Grouping Related Functions

When you have many related functions (5+), choose one approach per module:

**Approach 1: Inject Individually (default)**

Use when most consumers only need 1–2 functions:

```typescript
// user-functions.ts
export async function getUser(args: { userId: string }, deps: GetUserDeps) { ... }
export async function createUser(args: { name: string; email: string }, deps: CreateUserDeps) { ... }

export type GetUserFn = typeof getUser;
export type CreateUserFn = typeof createUser;

// notification-handler.ts — only needs sendWelcomeEmail
export type NotificationHandlerDeps = {
  sendWelcomeEmail: SendWelcomeEmailFn;
  // doesn't need getUser or createUser
};
```

**Approach 2: Inject as Grouped Object (when they travel together)**

Use when functions form a cohesive module and consumers inject the same set:

```typescript
// user-functions.ts
export const userFns = {
  getUser,
  createUser,
  updateUser,
  deleteUser,
  sendWelcomeEmail,
} as const;

export type UserFns = typeof userFns;

// user-router.ts — needs most user functions
export type UserRouterDeps = {
  userFns: UserFns;
};
```

**Rule of thumb:** Default to injecting individually. Group only when functions travel together. If grouping feels like a "god object", split it.

### 5. Inject Only What You'll Mock

Only inject things that hit network, disk, or clock. Import pure utilities directly:

```typescript
// WRONG - Over-injecting
function createUser(args, deps: { db, logger, slugify, randomUUID }) { }

// CORRECT - Only inject what you'll mock
import { slugify } from 'slugify';
import { randomUUID } from 'crypto';
function createUser(args, deps: { db, logger }) { }
```

### 6. Type-Only Imports for Interfaces

Use `import type` to prevent runtime coupling:

```typescript
// CORRECT
import type { Mailer } from '../infra/mailer';

// WRONG - Runtime import creates coupling
import { mailer } from '../infra/mailer';
```

## Testing Pattern

```typescript
import { describe, it, expect } from 'vitest';
import { mock } from 'vitest-mock-extended';
import { getUser, type GetUserDeps } from './get-user';

it('returns user when found', async () => {
  const mockUser = { id: '123', name: 'Alice', email: 'alice@test.com' };

  const deps = mock<GetUserDeps>();
  deps.db.findUser.mockResolvedValue(mockUser);

  const result = await getUser({ userId: '123' }, deps);
  expect(result).toEqual(mockUser);
});
```

## Migration Strategy (Strangler Fig)

### Phase 1: Add deps with defaults (backward compatible)
```typescript
import { mailer as _mailer, type Mailer } from '../infra/mailer';

const defaultDeps: SendEmailDeps = { mailer: _mailer };

export async function sendEmail(
  recipient: User,
  sender: User,
  deps: SendEmailDeps = defaultDeps  // Default for existing callers
) { ... }
```

### Phase 2: Remove defaults (explicit DI required)
```typescript
import type { Mailer } from '../infra/mailer';

export async function sendEmail(
  recipient: User,
  sender: User,
  deps: SendEmailDeps  // No default - must inject
) { ... }
```

### Phase 3 (Optional): Use object parameters
```typescript
export async function sendEmail(
  args: { recipient: User; sender: User },
  deps: SendEmailDeps
) { ... }
```

## When Classes ARE Acceptable

Classes are fine for:

| Use Case | Why It's OK |
|----------|-------------|
| **Framework integration** | NestJS, Express middleware require class syntax |
| **Stateful resources** | Connection pools, caches with lifecycle |
| **Builder patterns** | Fluent APIs where method chaining adds clarity |
| **Thin wrappers** | Delegating to pure functions (see below) |

Classes are NOT OK for:
- Business logic (use functions)
- Anything that will grow beyond 3-4 methods
- When you find yourself adding private helpers

## Framework Integration (NestJS)

Use classes as thin wrappers, keep logic in pure functions:

```typescript
// Pure function - your actual logic
async function createUser(
  args: CreateUserInput,
  deps: { db: Database; logger: Logger }
): Promise<Result<User, 'EMAIL_EXISTS' | 'DB_ERROR'>> {
  // Business logic here
}

// NestJS wrapper - thin delegation layer
@Injectable()
export class UserService {
  constructor(private db: Database, private logger: Logger) {}

  async createUser(args: CreateUserInput) {
    return createUser(args, { db: this.db, logger: this.logger });
  }
}
```

## Performance Considerations

Critics sometimes worry that creating many small objects (`args` objects, `deps` bags, factory functions) increases garbage collection pressure.

Modern V8 engines (Orinoco) use generational garbage collection. Objects that die young, like the temporary objects created during request handling, are reclaimed almost instantly. V8 is efficient at this.

For I/O-bound web applications:

| Operation | Typical Latency |
|-----------|-----------------|
| Database query | 1-50ms |
| HTTP request | 10-500ms |
| Object allocation | 0.0001ms |

The database query is 10,000-500,000x slower than object allocation. The architectural clarity and type safety of the `fn(args, deps)` pattern far outweigh any micro-overhead.

**When to worry about allocation:**
- Tight loops processing millions of items
- Real-time systems with hard latency requirements
- Memory-constrained embedded environments

For typical web services, **don't optimize for GC**. Optimize for correctness, testability, and maintainability.

## Enforcement

Enable in tsconfig.json:
```json
{
  "compilerOptions": {
    "verbatimModuleSyntax": true
  }
}
```

ESLint rule to prevent infra imports:
```javascript
"no-restricted-imports": ["error", {
  patterns: [{
    group: ["**/infra/**"],
    message: "Domain code must not import from infra. Inject dependencies instead."
  }]
}]
```

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "A class groups related methods nicely" | A module of exported functions groups them just as well, without a constructor that must satisfy every method's deps. |
| "I'll just inject all deps as one big object" | A god `deps` object hides which function uses what and makes every test wire dependencies it doesn't need. Declare per-function deps types. |
| "It's easier to `new UserService()` everywhere" | That couples every call site to construction. Wire deps once at the composition root and pass the resulting object around. |
| "I need to inject the slug helper so I can mock it" | If it's pure (no network, disk, or clock) you never need to mock it. Import it directly; only inject things you'll fake. |
| "Importing the mailer directly is simpler" | A runtime import couples your domain to infrastructure and makes it unmockable. Use `import type` and inject the instance. |
| "Allocating all these small objects will hurt GC" | V8's generational GC reclaims short-lived objects almost instantly. A DB query is 10,000x+ slower than an allocation. Optimize for clarity. |

## Red Flags

- A class whose constructor takes dependencies that only some methods use
- A `deps` object passed to a function that uses fewer than half its fields
- `import { mailer } from '../infra/mailer'` (runtime import) inside domain code
- Injecting pure utilities (`slugify`, `randomUUID`) just to mock them
- A factory/composition step running inside a request handler instead of once at startup
- Private helper methods relying on `this` to share state between methods
- A "service" class that has grown past 3-4 methods of pure business logic

## Verification

After writing or refactoring business logic:

- [ ] Every business function has the shape `fn(args, deps)` with a per-function `deps` type
- [ ] No `deps` field is unused by the function it's passed to
- [ ] Dependencies are wired once at a composition root, not at call sites
- [ ] Infrastructure is imported with `import type` only; instances arrive via `deps`
- [ ] Pure utilities are imported directly, not injected
- [ ] Any remaining classes are framework wrappers, stateful resources, or builders, not business logic
- [ ] Tests pass a mocked `deps` (`mock<XDeps>()`) without instantiating a class
