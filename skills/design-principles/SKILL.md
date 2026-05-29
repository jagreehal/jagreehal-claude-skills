---
name: design-principles
description: Applies software design rules beyond syntax (fail-fast over fallbacks, explicit over implicit, composition over inheritance, illegal states unrepresentable) and runs an 8-dimension design analysis on code. Use when reviewing or refactoring code for design quality, naming, coupling, type safety, or when deciding how to structure functions, types, and modules.
version: 1.3.0
---

# Design Principles

## Overview

These are design rules that operate above syntax: how to name things, how to model state, where dependencies come from, when to mutate, and when an abstraction earns its keep. They complement the `fn(args, deps)` pattern, Result types, and validation boundaries; together they decide whether code is testable, honest about its failure modes, and navigable months later.

The throughline is the same in every rule: **make the safe thing the explicit thing, and make the wrong thing impossible to express.** Fail fast with context instead of silently coalescing nulls. Use discriminated unions so illegal states won't typecheck. Inject dependencies instead of constructing them inside. Name with domain language so the code reads like the problem. The second half of this skill is an 8-dimension analysis protocol that turns these principles into a systematic, evidence-based code review.

## When to Use

- Reviewing or refactoring code for design quality
- Deciding how to model state, types, dependencies, or module boundaries
- Catching naming, coupling, immutability, or type-safety problems
- Running a structured design analysis on a class or module

**When NOT to use:** Prose or article quality (use [spine-framework](../spine-framework/SKILL.md) or [structured-writing](../structured-writing/SKILL.md)); large-scale architecture across many modules (use [system-architecture](../system-architecture/SKILL.md)).

**Related:** [fn-args-deps](../fn-args-deps/SKILL.md) for explicit dependency injection, [result-types](../result-types/SKILL.md) for fail-fast error handling, [system-architecture](../system-architecture/SKILL.md) for module-scale design, [data-visualization](../data-visualization/SKILL.md) which applies these rules to chart code.

For how this layer fits the whole system, see [`references/architecture.md`](../../references/architecture.md).

## Critical Rules

| Rule | Enforcement |
|------|-------------|
| Fail-fast over fallbacks | No `??` chains; throw clear errors |
| No `any`, no `as` | Type escape hatches defeat TypeScript |
| Make illegal states unrepresentable | Discriminated unions, not optional fields |
| Explicit dependencies | `fn(args, deps)`, never `new X()` inside |
| Domain names only | Never `data`, `utils`, `helpers`, `handler` |
| No comments | Code should be self-explanatory |
| Immutable by default | Return new values, don't mutate |

## Fail-Fast Over Fallbacks

Never use nullish coalescing chains; they hide bugs and turn a clear failure into a confusing one downstream.

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

Forbidden without explicit user approval:

```typescript
// FORBIDDEN
const x: any = something;
const y = something as SomeType;
const z = something as unknown as OtherType;
// @ts-ignore
// @ts-expect-error
```

There is always a type-safe alternative:

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

Use discriminated unions, not optional fields:

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

If a state combination shouldn't exist, make the type forbid it.

## Domain Names Only

Forbidden generic names:

- `data`, `info`, `item`
- `utils`, `helpers`, `common`, `shared`
- `manager`, `handler`, `processor`, `service` (when vague)

Use domain language:

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

Comments indicate a failure to express intent in code:

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

- `// TODO:` with a ticket reference
- Legal / license headers
- Complex regex explanations (but prefer named patterns)

## Immutability by Default

Return new values, don't mutate inputs:

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
- `map` / `filter` / `reduce` over `forEach` with mutation

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

When a function uses another object's data more than its own, move the logic:

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

**Detection:** Count references to `this` versus external objects. More external? Feature envy.

## YAGNI: You Aren't Gonna Need It

Don't build for hypothetical future needs:

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

"But we might need it" is not a requirement.

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
| Explicit deps | [fn-args-deps](../fn-args-deps/SKILL.md) pattern |
| Type safety | strict-typescript, validation-boundary |
| Fail-fast | [result-types](../result-types/SKILL.md) (use `err()`, not throw) |
| Immutability | Result types are immutable |
| No comments | critical-peer challenges unclear code |

## 8-Dimension Design Analysis Protocol

A systematic, evidence-based review across eight design dimensions. Use it at class or module level for design-quality assessment, refactoring-opportunity identification, design-focused code review, architecture evaluation, and pattern/anti-pattern detection.

**Scope:** Small-scale analysis of a single class, module, or small set of related files.

### Step 1: Understand the Code (REQUIRED)

Auto-invoke the `code-flow-analysis` skill FIRST. Before analyzing, you MUST understand:

- Code structure and flow (file:line references)
- Class / method responsibilities
- Dependencies and relationships
- Current behavior

Never analyze code you don't fully understand. Evidence-based analysis requires comprehension.

### Step 2: Systematic Dimension Analysis

Evaluate the code across the **8 dimensions** below, in order. For each dimension, identify specific, evidence-based findings.

### Step 3: Generate Findings Report

Provide structured output with severity levels, file:line references for ALL findings, concrete code examples, actionable recommendations, and before/after code where helpful.

### Rules

**ALWAYS:**

- Auto-invoke `code-flow-analysis` FIRST
- Provide file:line references for EVERY finding
- Show actual code snippets, not abstractions
- Be specific: enumerate exact issues
- Justify severity levels (why Critical vs Suggestion)
- Focus on evidence-based findings, no speculation
- Prioritize actionable insights only

**NEVER:**

- Analyze code you haven't understood
- Use generic descriptions ("this could be better")
- Guess about behavior; verify with code flow
- Skip dimensions; evaluate all 8 systematically
- Suggest changes without showing code examples
- Use "probably", "might", "maybe" without evidence
- Highlight what's working well; focus only on improvements

**SKIP:**

- Trivial findings and nitpicks that don't improve design
- Style preferences, unless they affect readability/maintainability
- Premature optimizations without evidence
- Subjective opinions; stick to principles and evidence

### 1. Naming

| Check | Violation |
|-------|-----------|
| Generic words | `data`, `utils`, `helper`, `manager`, `handler` |
| Unclear intent | `process()`, `handle()`, `doSomething()` |
| Inconsistent | Similar concepts named differently |

```typescript
// WRONG
class DataProcessor {
  processData(data: any) { }
}

// CORRECT
class OrderTotalCalculator {
  calculate(order: Order): Money { }
}
```

### 2. Coupling & Cohesion

**Feature Envy:** a method uses more than three properties of another object.

```typescript
// WRONG - Feature Envy
class UserProfile {
  displaySubscription(): string {
    return `Plan: ${this.subscription.planName}, ` +
           `Price: $${this.subscription.monthlyPrice}`;
  }
}

// CORRECT - Tell, Don't Ask
class Subscription {
  getDescription(): string {
    return `Plan: ${this.planName}, Price: $${this.monthlyPrice}`;
  }
}

class UserProfile {
  displaySubscription(): string {
    return this.subscription.getDescription();
  }
}
```

### 3. Immutability

| Check | Violation |
|-------|-----------|
| `let` instead of `const` | Unnecessary mutability |
| Missing `readonly` | Mutable class properties |
| Array mutation | `push()`, `pop()`, `splice()` |

### 4. Domain Integrity

**Anemic Domain Model:** entities with only getters/setters, logic stranded in services.

```typescript
// WRONG - Anemic + Tell Don't Ask violation
class PlaceOrderUseCase {
  placeOrder(orderId: string) {
    const order = repository.load(orderId);
    if (order.getStatus() === 'DRAFT') {  // Asking, not telling
      order.place();
    }
  }
}

// CORRECT - Rich Domain
class Order {
  place() {
    if (this.status !== 'DRAFT') {
      throw new Error('Cannot place order not in draft');
    }
    this.status = 'PLACED';
  }
}

class PlaceOrderUseCase {
  placeOrder(orderId: string) {
    const order = repository.load(orderId);
    order.place();  // Telling — order enforces its own invariant
  }
}
```

### 5. Type System

| Check | Violation |
|-------|-----------|
| `any` keyword | Type safety abandoned |
| `as` assertions | Lying to the compiler |
| Primitive obsession | `string` for domain concepts |
| Stringly-typed | `status: string` instead of a union |

```typescript
// WRONG
status: string;

// CORRECT
type OrderStatus = 'pending' | 'confirmed' | 'shipped';
status: OrderStatus;
```

### 6. Simplicity

| Check | Violation |
|-------|-----------|
| Dead code | Unused imports, methods |
| Duplication | >3 lines repeated |
| Over-abstraction | Interface with a single implementation |
| YAGNI | Building for hypothetical needs |

### 7. Object Calisthenics

| Rule | Check |
|------|-------|
| One indentation level | >1 level of nesting = violation |
| No ELSE keyword | Use early return |
| Small entities | Methods <20 lines, files <200 lines |

### 8. Performance

Only flag when all three hold:

1. There's evidence of actual inefficiency
2. The improvement is significant
3. The fix doesn't harm readability

```typescript
// WRONG - O(n²)
items.forEach(item => {
  const cat = categories.find(c => c.id === item.categoryId);
});

// CORRECT - O(n)
const categoryMap = new Map(categories.map(c => [c.id, c]));
items.forEach(item => {
  const cat = categoryMap.get(item.categoryId);
});
```

## Common Rationalizations

| Rationalization | Reality |
|------------|---------|
| "A `??` fallback is safer than throwing" | It buries the bug. The failure resurfaces later with no context. Fail fast. |
| "One `as` cast won't hurt" | It lies to the compiler, and the next reader trusts the lie. Use a type guard. |
| "`data` / `utils` is fine, everyone knows what it means" | Nobody does. Domain names carry the intent the type can't. |
| "I'll generalize this interface now to save time later" | YAGNI. The shape you guess at rarely matches the requirement that arrives. |
| "A comment is easier than renaming" | The comment rots; the name doesn't. Make the code say it. |
| "Mutating the parameter is fine, the caller doesn't care" | Until it does, silently. Return a new value. |

## Red Flags

- `??` chains masking missing data instead of failing fast
- Any `any`, `as`, `@ts-ignore`, or `@ts-expect-error` without explicit approval
- Optional fields encoding states that should be a discriminated union
- Generic names: `data`, `utils`, `helpers`, `manager`, `handler`, `process()`
- Comments explaining what unclear code does
- Functions mutating their inputs
- Dependencies constructed with `new X()` inside instead of injected
- Anemic entities with logic stranded in services
- Functions over 20 lines or files over 200 lines
- Nesting deeper than two levels, or `else` where an early return fits

## Design Analysis Output Format

When reporting findings:

```markdown
## 🔴 Critical Issues

### [Dimension] - [Brief Description]
**Location:** file.ts:line
**Issue:** [What's wrong]
**Recommendation:** [Specific fix]

## 🟡 Suggestions

[Same format]
```

## Verification

After a design review:

- [ ] Code understood via `code-flow-analysis` before any finding
- [ ] All 8 dimensions evaluated systematically
- [ ] Every finding has a file:line reference and a real code snippet
- [ ] Severity levels justified (Critical vs Suggestion)
- [ ] No `any` / `as` / `@ts-ignore` left unflagged
- [ ] No `??` fallback chains hiding missing data
- [ ] Illegal states made unrepresentable where applicable
- [ ] Names use domain language, not generic terms
