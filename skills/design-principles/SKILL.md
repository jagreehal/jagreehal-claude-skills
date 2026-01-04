---
name: design-principles
description: "Software design beyond syntax. Fail-fast over fallbacks, explicit over implicit, composition over inheritance. Integrates with fn(args, deps) and Result type patterns."
version: 1.0.0
---

# Design Principles

Design rules that complement fn(args, deps), Result types, and validation boundaries.

## Critical Rules

| Rule | Enforcement |
|------|-------------|
| Fail-fast over fallbacks | No `??` chains - throw clear errors |
| No `any`, no `as` | Type escape hatches defeat TypeScript |
| Make illegal states unrepresentable | Discriminated unions, not optional fields |
| Explicit dependencies | fn(args, deps), never `new X()` inside |
| Domain names only | Never `data`, `utils`, `helpers`, `handler` |
| No comments | Code should be self-explanatory |
| Immutable by default | Return new values, don't mutate |

## Fail-Fast Over Fallbacks

**Never use nullish coalescing chains:**

```typescript
// WRONG - Hides bugs, debugging nightmare
const name = user?.profile?.name ?? settings?.defaultName ?? 'Unknown';

// CORRECT - Fail immediately with context
if (!user) {
  throw new Error(`Expected user, got null. Context: userId=${userId}`);
}
if (!user.profile) {
  throw new Error(`User ${user.id} has no profile`);
}
return user.profile.name;
```

**Error message format:** `Expected [X]. Got [Y]. Context: [debugging info]`

## No Type Escape Hatches

**Forbidden without explicit user approval:**

```typescript
// FORBIDDEN
const x: any = something;
const y = something as SomeType;
const z = something as unknown as OtherType;
// @ts-ignore
// @ts-expect-error
```

**There is always a type-safe alternative:**

```typescript
// Instead of `as`, use type guards
function isUser(x: unknown): x is User {
  return typeof x === 'object' && x !== null && 'id' in x;
}

if (isUser(data)) {
  // data is User here
}

// Instead of `any`, use unknown + validation
const data: unknown = JSON.parse(input);
const user = UserSchema.parse(data);  // Zod validates and types
```

## Make Illegal States Unrepresentable

**Use discriminated unions, not optional fields:**

```typescript
// WRONG - Illegal states possible
type Order = {
  status: string;
  shippedDate?: Date;      // Can be set when status !== 'shipped'
  cancelReason?: string;   // Can be set when status !== 'cancelled'
};

// CORRECT - Type system prevents illegal states
type Order =
  | { status: 'pending'; items: Item[] }
  | { status: 'shipped'; items: Item[]; shippedDate: Date; trackingNumber: string }
  | { status: 'cancelled'; items: Item[]; cancelReason: string };
```

**If a state combination shouldn't exist, make the type forbid it.**

## Domain Names Only

**Forbidden generic names:**
- `data`, `info`, `item`
- `utils`, `helpers`, `common`, `shared`
- `manager`, `handler`, `processor`, `service` (when vague)

**Use domain language:**

```typescript
// WRONG
class DataProcessor {
  processData(data: any) { }
}
function handleItem(item: Item) { }
const utils = { formatThing };

// CORRECT
class OrderTotalCalculator {
  calculate(order: Order): Money { }
}
function shipOrder(order: Order) { }
const priceFormatter = { formatCurrency };
```

## No Code Comments

Comments indicate failure to express intent in code:

```typescript
// WRONG - Comment explains unclear code
// Check if user is admin and not suspended
if (user.role === 'admin' && !user.suspendedAt) { }

// CORRECT - Code is self-documenting
const isActiveAdmin = user.role === 'admin' && !user.suspendedAt;
if (isActiveAdmin) { }

// Or extract to function
function isActiveAdmin(user: User): boolean {
  return user.role === 'admin' && !user.suspendedAt;
}
```

**Acceptable comments:**
- `// TODO:` with ticket reference
- Legal/license headers
- Complex regex explanations (but prefer named patterns)

## Immutability by Default

**Return new values, don't mutate inputs:**

```typescript
// WRONG - Mutates input
function addItem(order: Order, item: Item): void {
  order.items.push(item);  // Caller's object changed!
}

// CORRECT - Returns new value
function addItem(order: Order, item: Item): Order {
  return {
    ...order,
    items: [...order.items, item],
  };
}
```

**Prefer:**
- `const` over `let`
- Spread (`...`) over mutation
- `map`/`filter`/`reduce` over `forEach` with mutation

**When mutation IS acceptable:**
- Building arrays in loops (push is faster than spread for large arrays)
- Performance-critical hot paths (measure first)
- Local scope only (never mutate inputs, only local variables)

```typescript
// OK: Mutation in local scope for performance
function processLargeDataset(items: Item[]): ProcessedItem[] {
  const results: ProcessedItem[] = [];  // Local mutable array
  for (const item of items) {
    results.push(transform(item));  // Much faster than spread
  }
  return results;  // Return immutable result
}
```

## Feature Envy Detection

**When a function uses another object's data more than its own, move the logic:**

```typescript
// FEATURE ENVY - obsessed with Order's internals
function calculateInvoiceTotal(order: Order): Money {
  return order.items
    .map(i => i.price * i.quantity)
    .reduce((a, b) => a + b, 0)
    + order.taxRate * subtotal
    + order.shippingCost;
}

// CORRECT - Logic belongs on Order
class Order {
  calculateTotal(): Money {
    // Uses this.items, this.taxRate, this.shippingCost
  }
}

function createInvoice(order: Order): Invoice {
  return new Invoice(order.calculateTotal());
}
```

**Detection:** Count references to `this` vs external objects. More external? Feature envy.

## YAGNI - You Aren't Gonna Need It

**Don't build for hypothetical future needs:**

```typescript
// WRONG - Speculative generalization
interface PaymentProcessor {
  process(payment: Payment): Result<Receipt, PaymentError>;
  refund(payment: Payment): Result<Receipt, PaymentError>;
  partialRefund(payment: Payment, amount: Money): Result<Receipt, PaymentError>;
  schedulePayment(payment: Payment, date: Date): Result<Receipt, PaymentError>;
  recurringPayment(payment: Payment, schedule: Schedule): Result<Receipt, PaymentError>;
  // ... 10 more methods "we might need"
}

// CORRECT - Build what you need now
interface PaymentProcessor {
  process(payment: Payment): Result<Receipt, PaymentError>;
}
// Add refund() when requirements actually demand it
```

**"But we might need it" is not a requirement.**

## Object Calisthenics (Adapted)

### No ELSE keyword

```typescript
// WRONG
function getStatus(user: User): string {
  if (user.isAdmin) {
    return 'admin';
  } else {
    return 'user';
  }
}

// CORRECT - Early return
function getStatus(user: User): string {
  if (user.isAdmin) return 'admin';
  return 'user';
}
```

### Keep entities small

- Functions: < 20 lines
- Files: < 200 lines
- If larger, split

### One level of indentation (prefer max 2)

```typescript
// WRONG - 4 levels deep
function process(orders: Order[]) {
  for (const order of orders) {
    for (const item of order.items) {
      if (item.inStock) {
        if (item.price > 0) {
          // deeply nested
        }
      }
    }
  }
}

// CORRECT - Extract and flatten
function process(orders: Order[]) {
  const items = orders.flatMap(o => o.items);
  const validItems = items.filter(isValidItem);
  validItems.forEach(processItem);
}
```

## Integration with Other Skills

| Principle | Relates To |
|-----------|------------|
| Explicit deps | fn-args-deps pattern |
| Type safety | strict-typescript, validation-boundary |
| Fail-fast | result-types (use err(), not throw) |
| Immutability | Result types are immutable |
| No comments | critical-peer challenges unclear code |

## When Tempted to Cut Corners

| Temptation | Instead |
|------------|---------|
| Use `??` chain | Fail fast with clear error |
| Use `any` or `as` | Fix the types properly |
| Name it `data` or `utils` | Use domain language |
| Write a comment | Make code self-explanatory |
| Mutate a parameter | Return new value |
| Build "for later" | Build what you need now |
| Add `else` branch | Use early return |
