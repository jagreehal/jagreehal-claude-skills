# Code Review Rules

Semantic rules aligned with TypeScript patterns. Customize for your project.

---

## Rule 1: fn(args, deps) Pattern

All business functions must use the two-parameter signature.

### Required

```typescript
// CORRECT: deps explicitly injected
type GetUserDeps = { db: Database; logger: Logger };

async function getUser(
  args: { userId: string },
  deps: GetUserDeps
): Promise<Result<User, GetUserError>> {
  // ...
}
```

### Forbidden

```typescript
// WRONG: Importing deps
import { db } from '../infra/database';

async function getUser(userId: string): Promise<User> {
  return db.find(userId);
}
```

### Detection

- Imports from `/infra/`, `/services/`, or `/repositories/` in business logic
- Global deps: `config.`, `process.env.`, `new Service()` inside functions
- Missing deps parameter in function signature

**Why:** Explicit deps make functions testable with `mock<DepsType>()`.

---

## Rule 2: Result Types for Expected Failures

Never throw for expected domain errors.

### Required

```typescript
// CORRECT: Result type
type GetUserError = 'NOT_FOUND' | 'DB_ERROR';

async function getUser(
  args: { userId: string },
  deps: GetUserDeps
): Promise<Result<User, GetUserError>> {
  const user = await deps.db.findUser(args.userId);
  if (!user) return err('NOT_FOUND');
  return ok(user);
}
```

### Forbidden

```typescript
// WRONG: Throwing for expected case
async function getUser(userId: string): Promise<User> {
  const user = await db.findUser(userId);
  if (!user) throw new NotFoundError('User not found');
  return user;
}
```

### Detection

- `throw` statements in business logic (allowed in boundary/infra)
- try/catch with typed error matching
- Functions returning Promise<T> without Result wrapper

**Why:** Result types force callers to handle all cases at compile time.

---

## Rule 3: Validation Boundary

Validate once at the edge, never inside business logic.

### Required

```typescript
// CORRECT: Validation at API boundary
const createUserSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1)
});

// Handler validates, business logic trusts
app.post('/users', async (req, res) => {
  const input = createUserSchema.parse(req.body);
  const result = await createUser(input, deps);
  // ...
});

// Business function trusts input
async function createUser(
  args: { email: string; name: string },
  deps: CreateUserDeps
): Promise<Result<User, CreateUserError>> {
  // No validation here - already validated
}
```

### Forbidden

```typescript
// WRONG: Validation inside business function
async function createUser(args: { email: string }, deps: Deps) {
  if (!args.email.includes('@')) {
    return err('INVALID_EMAIL');
  }
  // ...
}
```

### Detection

- Zod schemas inside `/domain/` or `/application/` folders
- Manual validation (regex, if checks) in business functions
- `.parse()` or `.safeParse()` outside boundary layer

**Why:** Double validation is waste. Trust your boundaries.

---

## Rule 4: Maximum Type Safety

No type escape hatches. There's always a type-safe solution.

### Forbidden

- `any` type
- `as Type` assertions
- `@ts-ignore` or `@ts-expect-error`
- `!` non-null assertions
- `eslint-disable` comments
- Optional bags instead of discriminated unions

### Required

```typescript
// Use discriminated unions
type ApiResponse =
  | { status: 'success'; data: User }
  | { status: 'error'; code: string; message: string };

// Use type guards instead of assertions
function isUser(value: unknown): value is User {
  return typeof value === 'object' && value !== null && 'id' in value;
}

// Use branded types
type UserId = string & { readonly __brand: 'UserId' };
```

**Why:** Type escape hatches bypass compile-time safety. They always have a type-safe alternative.

---

## Rule 5: No Dangerous Fallback Values

Required values should fail fast, not silently default.

### Forbidden

```typescript
// WRONG: Hiding missing required data
const userId = config.userId ?? 'default-user';
const apiUrl = process.env.API_URL || 'http://localhost:3000';
const user = await getUser(id).catch(() => null);
```

### Required

```typescript
// CORRECT: Fail fast at startup
function getConfig() {
  const apiUrl = process.env.API_URL;
  if (!apiUrl) throw new Error('API_URL is required');
  return { apiUrl };
}

// CORRECT: Make optionality explicit
interface Config {
  apiUrl: string; // Required, no default
  logLevel?: string; // Explicitly optional
}
```

### Detection

- `?? 'default'` patterns (especially on config/env)
- `|| fallback` for required values
- `.catch(() => defaultValue)` hiding errors

**Why:** Silent defaults hide bugs. Required values must be required.

---

## Rule 6: Domain Naming

Names express domain purpose, not code organization.

### Forbidden

- Files: `utils.ts`, `helpers.ts`, `types.ts`, `services.ts`, `handlers.ts`
- Variables: `data`, `result`, `value`, `item`, `temp`
- Functions: `processData()`, `handleRequest()`, `formatValue()`
- Folders: `/utils`, `/helpers`, `/common`, `/shared`, `/core`

### Required

```typescript
// Domain-specific names
const user = await deps.db.findUser(userId);
const orderTotal = calculateOrderTotal(order);
const validatedEmail = validateEmailFormat(input);

// Domain-specific files
// calculateOrderTotal.ts
// UserRepository.ts
// EmailValidationService.ts
```

### Exceptions

- Framework conventions: `hooks/`, `components/`, `pages/`
- Test files: `*.test.ts`, `*.spec.ts`
- Config files: `config.ts`, `constants.ts`

**Why:** Generic names are mental dumping grounds. Specific names reveal intent.

---

## Rule 7: Deps Type Export

Every function's deps type must be exported for testing.

### Required

```typescript
// CORRECT: Exported deps type
export type GetUserDeps = {
  db: { findUser: (id: string) => Promise<User | null> };
  logger: Logger;
};

export async function getUser(
  args: { userId: string },
  deps: GetUserDeps
): Promise<Result<User, 'NOT_FOUND'>> {
  // ...
}
```

### Forbidden

```typescript
// WRONG: Inline deps type (can't mock in tests)
async function getUser(
  args: { userId: string },
  deps: { db: Database; logger: Logger }
): Promise<Result<User, 'NOT_FOUND'>> {
  // ...
}
```

### Detection

- Functions with deps parameter but no exported type
- Deps types defined inline in function signature

**Why:** `mock<GetUserDeps>()` requires exported type.

---

## Review Procedure

For each file:

1. **Read complete file**
2. **Check each rule systematically**
3. **Report findings with file:line references**

---

## Report Format

### Violations Found

```
FAIL

Violations:
1. [fn(args, deps)] - src/domain/get-user.ts:15
   Issue: Imports database directly from infra
   Fix: Add deps parameter with db dependency

2. [RESULT TYPES] - src/domain/create-order.ts:42
   Issue: Throws NotFoundError for expected case
   Fix: Return err('NOT_FOUND') instead
```

### No Violations

```
PASS

File meets all semantic requirements.
```

---

## Customization

Add project-specific rules below this line.
The agent enforces exactly what you define.
