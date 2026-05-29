---
name: validation-boundary
description: Validates untrusted input once at the system boundary with Zod schemas and branded types, so business functions trust their args by contract. Use when handling HTTP request bodies, query params, CLI args, queue messages, env vars, or third-party API responses; when defining Zod schemas or branded types; or when deciding where validation belongs in a TypeScript app.
version: 1.1.0
libraries: ["zod"]
---

# Validation at the Boundary

## Overview

Validation is a **boundary concern**. You check passports once at the border, not at every street corner. Untrusted input (HTTP bodies, query params, CLI args, queue messages, env vars, third-party responses) is parsed and rejected at the edge of the system. Everything inside the boundary trusts its types by contract.

```
External Input (HTTP, CLI, Queue, 3rd-party)  <- untrusted
       |
       v
Boundary Layer (parse with Zod)               <- reject bad data here
       |
       v
Business Functions fn(args, deps)             <- args ALREADY valid by contract
```

This matters because validation scattered through internal code is impossible to reason about: you can never tell whether a given value has been checked, so you re-check defensively everywhere, and bugs hide in the gaps. Concentrating it at the boundary means each business function has one job, and the type system, not runtime guards, guarantees `args` are well-formed. This is what lets [`fn-args-deps`](../fn-args-deps/SKILL.md) functions stay clean and what feeds typed failures into [`result-types`](../result-types/SKILL.md).

## When to Use

- Handling HTTP request bodies, query strings, route params, or headers
- Reading CLI arguments, environment variables, or config files
- Consuming queue/event messages
- **Parsing third-party API responses** (always untrusted; validate shape before use)
- Defining the input types for a public function or module boundary
- Introducing branded types for IDs, tokens, or values that must be validated

**When NOT to use:** Do NOT validate between internal functions that already share a type contract, inside utilities called by already-validated code, or on data that came back from your own database. Re-validating trusted data is noise and signals a missing boundary.

**Related:** [`fn-args-deps`](../fn-args-deps/SKILL.md) (the functions whose `args` this protects), [`result-types`](../result-types/SKILL.md) (how domain-validation failures are returned), [`api-design`](../api-design/SKILL.md) (error response shape), [`strict-typescript`](../strict-typescript/SKILL.md) (branded types).

For how this layer fits the whole system, see [`references/architecture.md`](../../references/architecture.md).

## Parse, Don't Validate

**Validation** checks data and returns true/false.
**Parsing** transforms data into a new, richer type.

```typescript
// Validation mindset: "Is this email valid?"
function isValidEmail(s: string): boolean { ... }

// Parsing mindset: "Give me an Email, or fail"
function parseEmail(s: string): Email { ... }
```

With parsing, you have an `Email` type that CANNOT be invalid by construction.

## Required Behaviors

### 1. Define Schemas with Zod

```typescript
import { z } from 'zod';

const CreateUserSchema = z.object({
  name: z.string().min(2).max(100),
  email: z.string().email(),
});

type CreateUserInput = z.infer<typeof CreateUserSchema>;
```

### 2. Use Branded Types for Stronger Guarantees

```typescript
const EmailSchema = z.string().email().brand<'Email'>();
const UserIdSchema = z.string().uuid().brand<'UserId'>();

type Email = z.infer<typeof EmailSchema>;   // string & { __brand: 'Email' }
type UserId = z.infer<typeof UserIdSchema>; // string & { __brand: 'UserId' }

// Now TypeScript prevents accidental raw strings
function sendEmail(to: Email, subject: string) { ... }

sendEmail("alice@example.com", "Hello");  // ERROR: string not assignable to Email
sendEmail(EmailSchema.parse("alice@example.com"), "Hello");  // OK
```

#### When to Use Branded Types vs Plain Types

| Use Branded Types | Use Plain Types |
|-------------------|-----------------|
| IDs that look alike (`userId`, `orderId`) | Internal-only types |
| Security-sensitive values (tokens, keys) | Simple strings with no confusion risk |
| Values that MUST go through validation | Prototyping / early development |
| Cross-boundary data | Types only used in one function |

**Rule of thumb:** If mixing up two string parameters would cause a bug, brand them.

### 3. Validate at HTTP/Queue/CLI Boundaries

```typescript
app.post('/users', async (req, res) => {
  // 1. Validate at the boundary
  const parsed = CreateUserSchema.safeParse(req.body);

  if (!parsed.success) {
    return res.status(400).json(formatZodError(parsed.error));
  }

  // 2. Call business function with valid, typed data
  const user = await userService.createUser(parsed.data);

  return res.status(201).json(user);
});
```

### 4. Business Functions Trust the Contract

NO validation inside business functions. They trust args are already valid:

```typescript
// CORRECT - No validation, trust the contract
async function createUser(
  args: CreateUserInput,  // Already validated!
  deps: CreateUserDeps
): Promise<User> {
  const user = { id: crypto.randomUUID(), ...args };
  await deps.db.saveUser(user);
  return user;
}

// WRONG - Validation mixed with business logic
async function createUser(args: { name: string; email: string }, deps) {
  if (!args.name || args.name.length < 2) {
    throw new Error('Name must be at least 2 characters');  // DON'T DO THIS
  }
  // ...
}
```

### 5. Standardize Validation Error Responses

```typescript
type ValidationErrorResponse = {
  error: 'VALIDATION_FAILED';
  message: string;
  issues: Array<{
    path: string;
    message: string;
    code: string;
  }>;
};

function formatZodError(error: z.ZodError): ValidationErrorResponse {
  return {
    error: 'VALIDATION_FAILED',
    message: 'Request validation failed',
    issues: error.issues.map(issue => ({
      path: issue.path.join('.'),
      message: issue.message,
      code: issue.code,
    })),
  };
}
```

## Two Layers of Validation

| Type | Where | What | Tool |
|------|-------|------|------|
| **Schema Validation** | Boundary | Shape, types, format, ranges | Zod |
| **Domain Validation** | Business function | Business rules (email exists, has permission) | Database lookups |

```typescript
// Schema validation (boundary)
const TransferSchema = z.object({
  fromAccount: z.string().uuid(),
  toAccount: z.string().uuid(),
  amount: z.number().positive(),
});

// Domain validation (business function)
async function validateTransfer(args: TransferInput, deps: TransferDeps) {
  const account = await deps.db.getAccount(args.fromAccount);
  if (account.balance < args.amount) {
    return err('INSUFFICIENT_FUNDS');  // Business rule, not schema
  }
  // ...
}
```

## Common Patterns

### Coercion (Query Parameters)

```typescript
const PaginationSchema = z.object({
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

// "?page=2&limit=50" -> { page: 2, limit: 50 }
```

### Partial Updates (PATCH)

```typescript
const UpdateUserSchema = z.object({
  name: z.string().min(2).optional(),
  email: z.string().email().optional(),
});
```

### Transforms

```typescript
const CreatePostSchema = z.object({
  title: z.string().transform(s => s.trim()),
  slug: z.string().transform(s => s.toLowerCase().replace(/\s+/g, '-')),
});
```

### Express Middleware

```typescript
function validateBody<T>(schema: z.ZodSchema<T>) {
  return (req: Request, res: Response, next: NextFunction) => {
    const result = schema.safeParse(req.body);

    if (!result.success) {
      return res.status(400).json(formatZodError(result.error));
    }

    req.body = result.data;
    next();
  };
}

app.post('/users', validateBody(CreateUserSchema), async (req, res) => {
  const user = await userService.createUser(req.body);
  res.status(201).json(user);
});
```

## Quick Reference

| Question | Answer |
|----------|--------|
| Where validate shape/format? | Boundary (Zod schema) |
| Where validate business rules? | Business function |
| Should fn(args, deps) validate args? | NO. Trust the contract |
| Error for invalid input? | HTTP 400 (client error) |

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'll just check the input inside the function too, to be safe" | Double validation means neither layer is authoritative and the function now has two jobs. Parse once at the boundary; trust the type after. |
| "It came from our own database, but I'll validate it anyway" | Data that already crossed a boundary (or originated internally) is trusted. Re-validating it is noise that hides where the real boundary is. |
| "The third-party API always returns the right shape" | External services are untrusted. They change, fail, and can return malicious or instruction-like content. Parse their responses like any other boundary input. |
| "A plain string is fine for the user ID" | If two same-typed values can be swapped by mistake (userId vs orderId), brand them so the compiler catches the mix-up. |
| "Throwing inside the business function is simpler than returning a Result for the bad-balance case" | Schema validation belongs at the boundary; *business-rule* failures (insufficient funds, not found) are expected outcomes: return them as `result-types`, don't throw. |

## Red Flags

- `if (!args.email)` or `.length < 2` checks inside a business function
- The same field validated in a handler and again deeper in the call stack
- A `fetch().then(r => r.json())` result used without parsing its shape
- Raw `string` parameters for IDs, tokens, or other easily-confused values
- A Zod schema defined but only used for types, never `.parse()`d at the edge
- Validation logic duplicated across multiple handlers instead of shared middleware/schema

## Verification

After wiring up input handling:

- [ ] Every external input is parsed with a Zod schema at the boundary
- [ ] Business functions accept already-validated types and contain no shape checks
- [ ] IDs/tokens that could be confused use branded types
- [ ] Third-party responses are parsed before use
- [ ] Invalid input returns a consistent error (HTTP 400 / `VALIDATION_FAILED`)
- [ ] Business-rule failures are returned as Results, not thrown (see [`result-types`](../result-types/SKILL.md))
- [ ] No re-validation of internal or database-sourced data
