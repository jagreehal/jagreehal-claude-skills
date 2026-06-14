---
name: result-types
description: Models expected failures as values with Result<T, E> instead of throwing, and composes them with railway-oriented workflows. Use when a function can fail in expected ways (not found, validation, conflict, timeout), when designing error types, when chaining fallible operations, when mapping errors to HTTP status codes, or when deciding whether to throw or return a Result.
version: 1.1.0
libraries: ["@jagreehal/workflow"]
---

# Typed Errors: Never Throw

## Overview

Exceptions are invisible (they don't appear in a function's signature, so callers can't see them coming), they bypass composition (a `throw` unwinds the stack past every intermediate step), and they conflate unrelated failures (a `catch` block can't tell a 404 from a database outage). For **expected** failures (not found, validation, conflict, timeout) return a `Result<T, E>` value instead, so the failure is visible in the type, exhaustively handled by the compiler, and composable.

`throw` is reserved for the exceptional: programmer error, invariant violation, corrupted state. Everything a caller might reasonably want to handle is a Result.

This is the third leg of the architecture: [`fn-args-deps`](../fn-args-deps/SKILL.md) functions return Results, [`validation-boundary`](../validation-boundary/SKILL.md) produces the `VALIDATION_FAILED` variant, and [`resilience`](../resilience/SKILL.md) wraps Result-returning steps with retries and timeouts.

## When to Use

- Any function with an expected failure mode (not found, unauthorized, conflict, validation)
- Chaining several fallible operations where one failure should short-circuit the rest
- Designing an error type for a module or domain
- Mapping internal failures to HTTP status codes at the boundary
- Bridging throwing third-party code into a typed pipeline

**When NOT to use:** Don't return a Result for programmer errors or impossible states. Use `throw` (or `asserts`) for those, since no caller can sensibly recover. See [When Throwing Is Still Right](#when-throwing-is-still-right).

**Related:** [`fn-args-deps`](../fn-args-deps/SKILL.md) (the functions that return Results), [`validation-boundary`](../validation-boundary/SKILL.md) (source of validation errors), [`resilience`](../resilience/SKILL.md) (retry/timeout around Result steps), [`api-design`](../api-design/SKILL.md) (the error-envelope shape), [`observability`](../observability/SKILL.md) (logging failures without throwing).

For how this layer fits the whole system, see [`references/architecture.md`](../../references/architecture.md).

## Core Principle

Exceptions are invisible, bypass composition, and conflate different failures. Return `Result<T, E>` instead.

```typescript
// WRONG - Signature lies
async function getUser(args): Promise<User> {
  const user = await deps.db.findUser(args.userId);
  if (!user) throw new Error('User not found');  // Hidden!
  return user;
}

// CORRECT - Signature tells the truth
async function getUser(args, deps): Promise<Result<User, 'NOT_FOUND' | 'DB_ERROR'>> {
  try {
    const user = await deps.db.findUser(args.userId);
    return user ? ok(user) : err('NOT_FOUND');
  } catch {
    return err('DB_ERROR');
  }
}
```

## The Result Type

```typescript
type Result<T, E> =
  | { ok: true; value: T }
  | { ok: false; error: E };

type AsyncResult<T, E> = Promise<Result<T, E>>;

const ok = <T>(value: T): Result<T, never> => ({ ok: true, value });
const err = <E>(error: E): Result<never, E> => ({ ok: false, error });
```

## Required Behaviors

### 1. Business Functions Return Results

```typescript
async function getUser(
  args: { userId: string },
  deps: GetUserDeps
): Promise<Result<User, 'NOT_FOUND' | 'DB_ERROR'>> {
  try {
    const user = await deps.db.findUser(args.userId);
    if (!user) return err('NOT_FOUND');
    return ok(user);
  } catch {
    return err('DB_ERROR');
  }
}
```

### 2. Use createWorkflow() for Composition

Avoid verbose if-checking with railway-oriented programming:

```typescript
import { createWorkflow } from '@jagreehal/workflow';

// Declare dependencies -> error union computed automatically
const loadUserData = createWorkflow({ getUser, getPosts, enrichUser });

const result = await loadUserData(async (step) => {
  const user = await step(() => getUser({ userId }, deps));
  const posts = await step(() => getPosts({ userId: user.id }, deps));
  const enriched = await step(() => enrichUser({ user, posts }, deps));

  return { user: enriched };
});

// result: Result<{ user: EnrichedUser }, 'NOT_FOUND' | 'DB_ERROR' | 'FETCH_ERROR' | ...>
```

The `step()` function:
- Unwraps `ok` results and continues on happy path
- On `err`, immediately short-circuits and skips remaining steps

### 3. Use step.try() for Throwing Code

Bridge between throwing code and Result pipeline:

```typescript
const workflow = createWorkflow({ getUser });

const result = await workflow(async (step) => {
  const user = await step(() => getUser({ userId }, deps));

  // Throwing function: use step.try() with error mapping
  const config = await step.try(
    () => JSON.parse(user.configJson),
    { error: 'INVALID_CONFIG' as const }
  );

  return { user, config };
});
```

- `step()`: For functions that already return Result (your code)
- `step.try()`: For functions that throw (third-party, built-in)
- `step.fromResult()`: For Result-returning functions where you need to map errors

**For Result-returning functions:** Use `step.fromResult()` to preserve typed errors:

```typescript
// callProvider returns Result<Response, ProviderError>
const callProvider = async (input: string): AsyncResult<Response, ProviderError> => { ... };

const response = await step.fromResult(
  () => callProvider(input),
  {
    onError: (e) => ({
      type: 'PROVIDER_FAILED' as const,
      provider: e.provider,  // TypeScript knows e is ProviderError
      code: e.code,
    })
  }
);
```

### 4. Map Results to HTTP at Boundary

```typescript
const errorToStatus: Record<string, number> = {
  NOT_FOUND: 404,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  VALIDATION_FAILED: 400,
  CONFLICT: 409,
};

function resultToResponse<T, E extends string>(
  result: Result<T, E>,
  res: Response
): Response {
  if (result.ok) {
    return res.status(200).json(result.value);
  }

  const status = errorToStatus[result.error] ?? 500;
  return res.status(status).json({
    error: result.error,
    code: result.error,
  });
}

// Handler becomes simple
app.get('/users/:id', async (req, res) => {
  const result = await getUser({ userId: req.params.id }, deps);
  return resultToResponse(result, res);
});
```

### 5. Exhaustive Error Handling

TypeScript enforces handling all error cases:

```typescript
if (!result.ok) {
  switch (result.error) {
    case 'NOT_FOUND':
      return res.status(404).json({ error: 'User not found' });
    case 'DB_ERROR':
    case 'FETCH_ERROR':
      return res.status(500).json({ error: 'Internal error' });
    // TypeScript will error if you miss a case!
  }
}
```

## Error Type Patterns

### String Literals (Simple)

```typescript
type AppError = 'NOT_FOUND' | 'UNAUTHORIZED' | 'DB_ERROR';
```

### Discriminated Unions (Rich)

```typescript
type AppError =
  | { type: 'NOT_FOUND'; resource: string }
  | { type: 'VALIDATION'; field: string; message: string }
  | { type: 'DB_ERROR'; query: string };
```

### Const Objects (Runtime + Type)

```typescript
const Errors = {
  NOT_FOUND: 'NOT_FOUND',
  DB_ERROR: 'DB_ERROR',
} as const;

type AppError = (typeof Errors)[keyof typeof Errors];

return err(Errors.NOT_FOUND);  // Runtime value available
```

## Error Grouping at Scale

As applications grow, error unions become unwieldy:

```typescript
// This becomes a "Type Wall"
type AllErrors =
  | 'NOT_FOUND'
  | 'DB_ERROR'
  | 'DB_CONNECTION_FAILED'
  | 'DB_TIMEOUT'
  | 'FETCH_ERROR'
  | 'HTTP_TIMEOUT'
  | 'RATE_LIMITED'
  | 'CIRCUIT_OPEN'
  | 'VALIDATION_FAILED'
  // ... 20 more errors
```

**Solution:** Group related errors into categories:

```typescript
// Group by domain
type DatabaseError = 'DB_ERROR' | 'DB_CONNECTION_FAILED' | 'DB_TIMEOUT';
type NetworkError = 'FETCH_ERROR' | 'HTTP_TIMEOUT' | 'RATE_LIMITED';
type BusinessError = 'NOT_FOUND' | 'VALIDATION_FAILED' | 'UNAUTHORIZED';

type AppError = DatabaseError | NetworkError | BusinessError;

// Or use discriminated unions for richer context
type AppError =
  | { type: 'DATABASE'; code: 'CONNECTION_FAILED' | 'TIMEOUT' | 'QUERY_FAILED' }
  | { type: 'NETWORK'; code: 'TIMEOUT' | 'RATE_LIMITED' | 'UNREACHABLE' }
  | { type: 'BUSINESS'; code: 'NOT_FOUND' | 'VALIDATION_FAILED' };
```

This keeps error types manageable while preserving type safety.

## When Throwing Is Still Right

Throw only for:
- **Invariant violation** (programmer error, impossible state)
- **Corrupted process state** (can't recover)
- **Truly unrecoverable** situations

```typescript
// Good: throw for impossible states
if (!user) throw new Error('Unreachable: user should exist after insert');
```

### Using `asserts` for Type Narrowing

The `asserts` keyword creates runtime checks that also narrow types:

```typescript
// Assert function: throws if condition fails, narrows type if succeeds
function assertUser(user: User | null): asserts user is User {
  if (!user) throw new Error('Invariant violated: user must exist');
}

function assertDefined<T>(value: T | undefined, name: string): asserts value is T {
  if (value === undefined) throw new Error(`${name} must be defined`);
}

// Usage: TypeScript narrows the type after the assertion
const user = await deps.db.findUser(userId);
assertUser(user);  // Throws if null
// TypeScript now knows `user` is `User`, not `User | null`
console.log(user.name);  // Safe access
```

**When to use `asserts`:**
- After database inserts (record MUST exist)
- After config loading (values MUST be present)
- After state transitions (state MUST be valid)

**Don't use for:** Normal business logic failures (use Result instead)

## Quick Reference

| Situation | Use |
|-----------|-----|
| Domain failure (not found, validation) | Result |
| Infrastructure failure (recoverable) | Result |
| Programmer error | throw |
| Corrupted state | throw |

## Architecture Layer

```
Handlers / Routes
  -> map Result -> HTTP response

Business Logic
  -> createWorkflow({ ... })(async (step) => { ... })

Core Functions
  -> fn(args, deps): Result<T, E>

Infrastructure
  -> catch exceptions, return Results
```

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "Throwing is less boilerplate than wrapping everything in Result" | The boilerplate is the point: it makes failure visible in the signature and forces the caller to handle it. `createWorkflow` removes most of the ceremony anyway. |
| "I'll just throw and catch it at the top" | A top-level catch can't distinguish a 404 from a DB outage and can't recover mid-pipeline. The error union does both at compile time. |
| "Not found isn't really an error, I'll return null" | `null` collapses every failure into one indistinguishable case and silently propagates. Return `err('NOT_FOUND')` so the reason survives. |
| "The error type union is getting huge" | That's a signal to group errors by domain or use discriminated unions (see [Error Grouping at Scale](#error-grouping-at-scale)). It's still better than untyped throws. |
| "This third-party function throws, so I have to use try/catch everywhere" | Bridge it once with `step.try()` (mapping the throw to a typed error); the rest of the pipeline stays on the Result rail. |
| "I'll throw for the validation failure too" | Validation and other expected failures are Results. Reserve `throw` for invariant violations and corrupted state. |

## Red Flags

- A function whose signature says `Promise<User>` but throws on the not-found path
- `try/catch` blocks scattered through business logic instead of at infrastructure edges
- Returning `null`/`undefined` to signal distinct failures the caller needs to tell apart
- A single `catch (e)` swallowing several unrelated failure modes
- `throw new Error('not found')` for a recoverable, caller-handleable condition
- Result errors mapped to HTTP status codes in multiple handlers instead of one shared mapper
- Error unions that grow unbounded with no grouping by domain

## Verification

After implementing fallible logic:

- [ ] Functions with expected failures return `Result<T, E>`, not `Promise<T>` that throws
- [ ] The error type `E` enumerates every expected failure (no `string`/`any`)
- [ ] Chained operations compose via `createWorkflow` / `step`, short-circuiting on `err`
- [ ] Throwing third-party calls are bridged with `step.try()` and mapped to typed errors
- [ ] Results map to HTTP status in one place at the boundary
- [ ] `switch` on `result.error` is exhaustive (compiler errors on a missing case)
- [ ] `throw` / `asserts` is used only for invariant violations and impossible states
