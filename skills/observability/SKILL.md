---
name: observability
description: Makes functions observable with the trace() wrapper, structured logging (Pino), and OpenTelemetry, keeping telemetry orthogonal to business logic. Use when adding tracing or spans to fn(args, deps) functions, emitting structured JSON logs, redacting sensitive data, applying OpenTelemetry semantic conventions, correlating logs with traceId/spanId, or emitting canonical wide-event log lines with autotel.
version: 1.1.0
libraries: ["autotel", "pino"]
---

# Functions + OpenTelemetry

## Overview

Observability implements the **Observer pattern**: business logic is the subject (it produces `Result`s), tracing is the observer (it watches without interfering). The `trace()` wrapper records spans, maps results to span status, and emits logs, while the wrapped function stays blind to telemetry. This separation means you can add, change, or disable observability without touching business logic, and tests run unchanged because `trace()` is a no-op when tracing is off.

```
PURE CORE (Subject)
├── Business logic: fn(args, deps): Result<T, E>
├── No knowledge of tracing
└── Returns Results, doesn't control observability

OBSERVER LAYER
├── trace() wrapper watches the flow
├── Result.ok -> span.setStatus(OK)
├── Result.error -> span.setStatus(ERROR)
└── Business logic remains "blind" to telemetry
```

## When to Use

- Adding tracing/spans to `fn(args, deps)` functions
- Replacing string-interpolated logs with structured JSON fields
- Redacting sensitive data from logs and span attributes
- Applying OpenTelemetry semantic conventions for attribute names
- Correlating logs with traces via `traceId`/`spanId`
- Emitting canonical wide-event log lines (one log per request)

**When NOT to use:** Inside hot loops where span overhead matters more than visibility, or as a substitute for returning proper errors. Telemetry observes results, it does not replace [`result-types`](../result-types/SKILL.md). Do not put logging logic inside business functions; wrap them instead.

**Related:** [`result-types`](../result-types/SKILL.md) (the `Result` whose ok/err drives span status), [`fn-args-deps`](../fn-args-deps/SKILL.md) (the functions `trace()` wraps), [`api-design`](../api-design/SKILL.md) (where `X-Request-ID` originates for correlation), [`resilience`](../resilience/SKILL.md) (tracing retried steps and timeouts).

## Required Behaviors

### 1. Use Structured Logging (Pino)

NEVER use string interpolation. Use JSON fields:

```typescript
// WRONG - Unstructured
deps.logger.info(`getUser called with userId=${args.userId}`);

// CORRECT - Structured
deps.logger.info({ userId: args.userId, action: 'getUser' }, 'getUser called');
```

Why Pino:
- 5x faster than Winston
- JSON by default
- Built-in redaction for sensitive data

### 2. Redact Sensitive Data

```typescript
import pino from 'pino';

const logger = pino({
  redact: ['password', 'apiKey', 'token', '*.secret', 'user.email'],
});

// Sensitive fields automatically stripped
logger.info({ event: 'login', user: req.body });
// Output: { "user": { "email": "[Redacted]", "password": "[Redacted]" } }
```

### 3. Wrap Functions with trace()

Use [autotel](https://github.com/jagreehal/autotel) for automatic spans:

```typescript
import { trace, type TraceContext } from 'autotel';

const getUser = trace(
  (ctx: TraceContext) => async (
    args: { userId: string },
    deps: GetUserDeps
  ) => {
    ctx.setAttribute('user.id', args.userId);

    const user = await deps.db.findUser(args.userId);
    if (!user) {
      ctx.setStatus({ code: 2, message: 'User not found' });
      return err('NOT_FOUND');
    }

    ctx.setStatus({ code: 1 }); // OK
    return ok(user);
  }
);
```

### 4. Use Semantic Conventions

Use [OpenTelemetry standard attribute names](https://opentelemetry.io/docs/specs/semconv/):

```typescript
// WRONG - Custom keys
ctx.setAttribute('userId', args.userId);
ctx.setAttribute('orderTotal', total);

// CORRECT - Semantic conventions
ctx.setAttribute('user.id', args.userId);
ctx.setAttribute('order.value', total);
```

| Standard Key | Instead Of | Why |
|-------------|-----------|-----|
| `user.id` | `userId` | Backends auto-correlate |
| `http.method` | `method` | Automatic dashboards |
| `db.system` | `database` | DB performance views |
| `error.type` | `errorCode` | Error aggregation |

### 5. Map Result to Span Status

```typescript
const getUser = trace((ctx) => async (args, deps) => {
  const result = await getUserCore(args, deps);

  if (!result.ok) {
    ctx.setStatus({ code: 2, message: result.error });
  } else {
    ctx.setStatus({ code: 1 });
  }

  return result;
});
```

### 6. Redact Sensitive Data in Span Attributes

Pino redaction protects logs, but sensitive data can also leak into span attributes sent to Jaeger or Honeycomb:

```typescript
// The problem: You set span attributes for debugging
ctx.setAttribute('user.email', user.email);
ctx.setAttribute('auth.token', req.headers.authorization);  // 😱 Token in traces!

// The fix: Implement a global attribute filter
const SENSITIVE_KEYS = ['password', 'token', 'apiKey', 'secret', 'authorization'];

function sanitizeAttributes(attrs: Record<string, unknown>): Record<string, unknown> {
  return Object.fromEntries(
    Object.entries(attrs).map(([key, value]) => {
      const isSensitive = SENSITIVE_KEYS.some(k =>
        key.toLowerCase().includes(k.toLowerCase())
      );
      return [key, isSensitive ? '[REDACTED]' : value];
    })
  );
}

init({
  service: 'my-service',
  attributeFilter: sanitizeAttributes,
});
```

SOC2 and GDPR compliance often require filtering at both layers. Defense in depth.

### 7. Correlate Logs and Traces

Include `traceId` and `spanId` in every log:

```typescript
import { context, trace } from '@opentelemetry/api';
import pino from 'pino';

function createCorrelatedLogger() {
  const baseLogger = pino();

  return {
    info: (obj: object, msg?: string) => {
      const span = trace.getSpan(context.active());
      const spanContext = span?.spanContext();

      baseLogger.info({
        ...obj,
        traceId: spanContext?.traceId,
        spanId: spanContext?.spanId,
      }, msg);
    },
  };
}
```

### 8. Emit Canonical Log Lines (Wide Events)

Traditional logging is **optimized for writing, not querying**. Canonical log lines emit ONE log per request with ALL context:

```typescript
init({
  service: 'checkout-api',
  logger,
  canonicalLogLines: {
    enabled: true,
    rootSpansOnly: true, // One log per request
    logger,
  },
});
```

Accumulate context throughout the request:

```typescript
const processCheckout = trace((ctx) => async (req: CheckoutRequest) => {
  setUser(ctx, { id: req.userId });
  ctx.setAttributes({
    'user.subscription': user.subscription,
    'cart.id': req.cartId,
    'cart.item_count': items.length,
    'payment.method': req.paymentMethod,
  });

  // On error, add error context
  if (paymentFailed) {
    ctx.setAttributes({
      'error.type': 'PaymentError',
      'error.code': 'card_declined',
    });
  }

  // ONE canonical log emitted at span end with ALL attributes
  return result;
});
```

**Result:** Query logs like a database:

```sql
SELECT * FROM logs
WHERE user.subscription = 'premium'
  AND error.code IS NOT NULL;
```

Key characteristics:
- **High cardinality**: user IDs, order IDs enable precise queries
- **Flat structure**: Use dot-notation (`user.id`, `cart.total_cents`)
- **Emitted at span end**: All context available
- **One per request**: `rootSpansOnly: true`

## Quick Setup

```bash
npm install autotel pino
```

```typescript
import { init, trace, track } from 'autotel';

init({
  service: 'my-service',
  endpoint: process.env.OTEL_ENDPOINT,
  debug: true,  // Console output in development
});
```

### Backend-Specific Endpoints

| Backend | Endpoint |
|---------|----------|
| Jaeger | `http://localhost:4318/v1/traces` |
| Honeycomb | `https://api.honeycomb.io` (+ API key header) |
| Grafana Tempo | `http://localhost:4318/v1/traces` |
| Local dev | `debug: true` (console output) |

### track() for Business Events

Use `track()` for business-level events (not spans):

```typescript
import { track } from 'autotel';

// Track business events without creating spans
track('order.created', {
  orderId: order.id,
  customerId: order.customerId,
  total: order.total,
  itemCount: order.items.length,
});

track('user.signup', {
  userId: user.id,
  source: user.referralSource,
});
```

**When to use `trace()` vs `track()`:**
- `trace()` - Operations with duration (API calls, DB queries, workflows)
- `track()` - Point-in-time events (user actions, business milestones)

## Testing

Tests don't change. When tracing is disabled, `trace()` is a no-op:

```typescript
it('returns user when found', async () => {
  const mockUser = { id: '123', name: 'Alice' };
  const deps = { db: { findUser: vi.fn().mockResolvedValue(mockUser) } };

  const result = await getUser({ userId: '123' }, deps);

  expect(result.ok).toBe(true);
});
```

## Pattern Summary

```typescript
// 1. Define deps type (unchanged)
type MyFunctionDeps = { db: Database; logger: Logger };

// 2. Wrap with trace(), keep deps explicit
const myFunction = trace(
  (ctx: TraceContext) => async (args, deps: MyFunctionDeps) => {
    ctx.setAttribute('key', value);
    const result = await doWork(args, deps);
    ctx.setStatus({ code: result.ok ? 1 : 2 });
    return result;
  }
);

// 3. Test without caring about tracing
const result = await myFunction(args, mockDeps);
```

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "String logs are easier to read" | They are unqueryable. `logger.info({ userId }, 'msg')` lets you filter and aggregate; interpolation does not. |
| "I'll add tracing logic inside the function" | That couples business logic to telemetry and breaks the no-op-in-tests property. Wrap with `trace()` instead. |
| "Custom attribute names are fine" | `userId` won't auto-correlate; `user.id` does. Semantic conventions unlock backend dashboards for free. |
| "Pino redaction covers us" | Span attributes bypass log redaction and ship to Jaeger/Honeycomb. Redact at both layers, defense in depth. |
| "We log plenty already" | Many narrow logs are write-optimized noise. One canonical wide event per request is query-optimized signal. |
| "Tests will need updating for tracing" | They won't. `trace()` is transparent and a no-op when disabled. If tests change, the wrapper leaked into logic. |

## Red Flags

- String interpolation in log messages instead of structured fields
- Retry, branching, or tracing decisions made inside the business function
- Custom attribute keys (`userId`, `orderTotal`) instead of semantic conventions (`user.id`, `order.value`)
- Tokens, passwords, or emails appearing in logs or span attributes
- Logs with no `traceId`/`spanId` to correlate with traces
- Many small logs per request instead of one canonical wide event
- Tests that have to mock or assert on tracing

## Verification

After making a function observable:

- [ ] Logs use structured JSON fields, not string interpolation
- [ ] Tracing lives in the `trace()` wrapper, not the business function
- [ ] Attribute names follow OpenTelemetry semantic conventions
- [ ] Sensitive data is redacted in both Pino and span attributes
- [ ] `Result` ok/err maps to span status (code 1 / code 2)
- [ ] Logs carry `traceId`/`spanId` for correlation
- [ ] One canonical log line per request where wide events are enabled
- [ ] Existing tests pass unchanged (the function stayed telemetry-blind)

## The Rules

1. **Use structured logging** - JSON fields, not string interpolation
2. **Wrap with trace()** - Observability orthogonal to business logic
3. **Use semantic conventions** - Standard attribute names
4. **Correlate logs and traces** - Include traceId/spanId
5. **Emit canonical log lines** - One wide event per request with all context
6. **Map Result to span status** - ok = success, err = failure
7. **Tests don't change** - trace() is transparent
