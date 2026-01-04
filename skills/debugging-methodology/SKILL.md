---
name: debugging-methodology
description: "Evidence-based debugging. Instrument before guessing, trace before theorizing. Uses observability patterns to make failures visible and systematic."
version: 1.0.0
---

# Debugging Methodology

Stop guessing. Add instrumentation. Follow the evidence.

## Core Principle

**Measure, don't speculate.** When something fails, the answer is never "maybe it's X" followed by random changes. The answer is: add instrumentation that produces the specific data needed to explain the failure.

## The Anti-Pattern

```
Problem occurs
  → "Maybe it's a race condition"
  → Change something random
  → Still broken
  → "Could be caching"
  → Change something else
  → User frustrated, hours wasted
```

**Why this happens:** Insufficient data. You're debugging blind.

## The Protocol

### 1. Document the Symptom Exactly

```typescript
// WRONG: "The API returns an error"
// RIGHT: Exact symptom with context

/*
Symptom: getUser returns err('DB_ERROR')
Expected: ok(user) with { id: '123', name: 'Alice' }
Actual: err('DB_ERROR')
Context: userId='123', environment=test, after migration
Error message: "Connection refused to localhost:5432"
*/
```

**Capture:**
- Exact error message (copy-paste, don't paraphrase)
- Expected vs actual behavior
- Input values that triggered the failure
- Environment context

### 2. Add Instrumentation FIRST

Before forming ANY hypothesis, make the invisible visible:

```typescript
// BEFORE: Silent failure
async function getUser(
  args: { userId: string },
  deps: GetUserDeps
): Promise<Result<User, 'NOT_FOUND' | 'DB_ERROR'>> {
  const user = await deps.db.findUser(args.userId);
  if (!user) return err('NOT_FOUND');
  return ok(user);
}

// AFTER: Observable failure
async function getUser(
  args: { userId: string },
  deps: GetUserDeps
): Promise<Result<User, 'NOT_FOUND' | 'DB_ERROR'>> {
  deps.logger.debug('getUser called', { userId: args.userId });

  try {
    deps.logger.debug('Calling db.findUser', { userId: args.userId });
    const user = await deps.db.findUser(args.userId);
    deps.logger.debug('db.findUser returned', {
      userId: args.userId,
      found: !!user,
      userKeys: user ? Object.keys(user) : null
    });

    if (!user) {
      deps.logger.info('User not found', { userId: args.userId });
      return err('NOT_FOUND');
    }

    deps.logger.debug('Returning user', { userId: user.id });
    return ok(user);
  } catch (error) {
    deps.logger.error('Database error in getUser', {
      userId: args.userId,
      error: error instanceof Error ? error.message : String(error),
      stack: error instanceof Error ? error.stack : undefined
    });
    return err('DB_ERROR');
  }
}
```

### 3. Instrument at Decision Points

Add logging at every branch, every external call, every state change:

| Point | What to Log |
|-------|-------------|
| Function entry | All args, relevant deps state |
| External calls | Request params, before and after |
| Conditionals | Which branch taken, why |
| Transformations | Input shape, output shape |
| Error paths | Full error object, context |
| Function exit | Return value, duration |

### 4. Use OpenTelemetry Spans

For complex flows, use tracing:

```typescript
import { trace } from 'autotel';

async function processOrder(
  args: { orderId: string },
  deps: ProcessOrderDeps
): Promise<Result<Order, OrderError>> {
  return trace('processOrder', { orderId: args.orderId }, async (span) => {
    span.setAttribute('order.id', args.orderId);

    const validationResult = await trace('validateOrder', async () => {
      return validateOrder(args, deps);
    });

    if (!validationResult.ok) {
      span.setAttribute('error.type', validationResult.error);
      return validationResult;
    }

    const paymentResult = await trace('processPayment', async () => {
      return processPayment({ order: validationResult.value }, deps);
    });

    span.setAttribute('payment.success', paymentResult.ok);
    return paymentResult;
  });
}
```

### 5. Form Evidence-Based Hypothesis

**Only AFTER you have data:**

```
Evidence from logs:
- getUser called with userId='123' ✓
- db.findUser called ✓
- db.findUser threw: "Connection refused to localhost:5432"

Hypothesis: Database connection failed
Evidence: Error message explicitly says "Connection refused"
Test: Check if database is running, check connection string
```

**Hypothesis must:**
- Be based on observed data (not speculation)
- Explain ALL symptoms
- Be testable with a single change

### 6. One Change at a Time

```
WRONG:
  → Change connection string AND add retry AND increase timeout
  → "It works now!" (but which fix was it?)

RIGHT:
  → Check database is running (it wasn't)
  → Start database
  → Retest → Works
  → Root cause: Database container wasn't started
```

## Result Type Debugging

When debugging Result-returning functions:

### Check the Error Path

```typescript
// Add explicit logging for err() returns
if (!user) {
  const errorContext = {
    userId: args.userId,
    dbQueryExecuted: true,
    queryDuration: Date.now() - startTime,
  };
  deps.logger.info('Returning NOT_FOUND', errorContext);
  return err('NOT_FOUND');
}
```

### Trace Through Workflows

```typescript
// When createWorkflow fails, add step-level logging
const workflow = createWorkflow()
  .pipe(step('validate', async (input) => {
    deps.logger.debug('Step: validate', { input });
    const result = await validate(input, deps);
    deps.logger.debug('Step: validate result', { ok: result.ok });
    return result;
  }))
  .pipe(step('process', async (input) => {
    deps.logger.debug('Step: process', { input });
    const result = await process(input, deps);
    deps.logger.debug('Step: process result', { ok: result.ok });
    return result;
  }));
```

### Verify Deps Are Correct

```typescript
// When mocking in tests, verify deps behavior
it('returns NOT_FOUND when user missing', async () => {
  const deps = mock<GetUserDeps>();
  deps.db.findUser.mockResolvedValue(null);

  // Debug: verify mock is configured correctly
  console.log('Mock configured:', {
    findUser: deps.db.findUser.getMockName(),
    mockReturnValue: await deps.db.findUser('test'),
  });

  const result = await getUser({ userId: '123' }, deps);

  // Debug: verify what was called
  console.log('findUser called with:', deps.db.findUser.mock.calls);
  console.log('Result:', result);

  expect(result.ok).toBe(false);
});
```

## Debugging Checklist

Before guessing, answer these:

| Question | How to Answer |
|----------|---------------|
| What are the input values? | Log function entry |
| Which code path executed? | Log at conditionals |
| What did external calls return? | Log before/after deps calls |
| What error was thrown? | Log in catch block with stack |
| What was the return value? | Log function exit |

## Anti-Patterns

### Never Guess

```
WRONG: "It's probably a race condition"
RIGHT: "Let me add timestamps to see the execution order"

WRONG: "Maybe the mock isn't working"
RIGHT: "Let me log what the mock returns when called"

WRONG: "Could be a caching issue"
RIGHT: "Let me log cache hits/misses with keys"
```

### Never Change Multiple Things

```
WRONG: Fix A, B, and C → "It works!" (which one fixed it?)
RIGHT: Fix A → Test → Still broken → Fix B → Test → Works (B was the issue)
```

### Never Remove Instrumentation Prematurely

```
WRONG: Problem seems fixed → Delete all logging
RIGHT: Problem confirmed fixed → Keep structured logging, remove debug-level only
```

### Never Assume Code Does What It Says

```typescript
// Function is CALLED getUser but does it RETURN user?
async function getUser(args, deps) {
  // Don't assume. Log the actual return value.
  const result = /* ... */;
  deps.logger.debug('getUser returning', { result });
  return result;
}
```

## Integration with Testing

### Debug Failing Tests Systematically

```typescript
it('processes order correctly', async () => {
  // 1. Log test setup
  console.log('=== TEST: processes order correctly ===');

  const deps = mock<ProcessOrderDeps>();
  deps.db.findOrder.mockResolvedValue(mockOrder);
  console.log('Deps configured:', {
    findOrderReturns: mockOrder
  });

  // 2. Log function call
  console.log('Calling processOrder with:', { orderId: '123' });
  const result = await processOrder({ orderId: '123' }, deps);

  // 3. Log result before assertion
  console.log('Result:', JSON.stringify(result, null, 2));

  // 4. Now assert
  expect(result.ok).toBe(true);
});
```

### Verify Mock Interactions

```typescript
// After test fails, check what was actually called
console.log('Mock calls:', {
  findOrder: deps.db.findOrder.mock.calls,
  saveOrder: deps.db.saveOrder.mock.calls,
  sendEmail: deps.mailer.send.mock.calls,
});
```

## Decision Tree

```
Problem occurs
    │
    ▼
Can you see exact failure point?
    NO → Add function entry/exit logging
    YES ↓
Do you know input values at failure?
    NO → Log all args and deps state
    YES ↓
Do you know which code path executed?
    NO → Log at every conditional
    YES ↓
Do you know what external calls returned?
    NO → Log before/after deps calls
    YES ↓
Do you know the error details?
    NO → Log full error with stack
    YES ↓
Form hypothesis from evidence → Test with ONE change
```

## Quick Reference

| Symptom | Instrumentation to Add |
|---------|----------------------|
| Wrong return value | Log at every return statement |
| Function never called | Log at caller and callee entry |
| External call fails | Log request params and response |
| Intermittent failure | Add timestamps, log state |
| Test passes locally, fails in CI | Log environment, deps versions |
| Result is err() unexpectedly | Log at every err() return |

## Debugging Workflows

When a `createWorkflow()` pipeline fails, debug systematically:

### 1. Identify Which Step Failed

```typescript
const workflow = createWorkflow({ validateOrder, processPayment, sendConfirmation });

const result = await workflow(async (step) => {
  deps.logger.debug('Starting workflow');

  const validated = await step(() => validateOrder(args, deps));
  deps.logger.debug('validateOrder completed', { ok: validated !== undefined });

  const payment = await step(() => processPayment({ order: validated }, deps));
  deps.logger.debug('processPayment completed', { ok: payment !== undefined });

  const confirmation = await step(() => sendConfirmation({ order: validated, payment }, deps));
  deps.logger.debug('sendConfirmation completed', { ok: confirmation !== undefined });

  return { order: validated, confirmation };
});

if (!result.ok) {
  deps.logger.error('Workflow failed', { error: result.error });
  // Error type tells you which step failed
}
```

### 2. Use Existing Traces

If you have OpenTelemetry set up (see observability skill), use existing traces:

```
In Jaeger/Honeycomb:
1. Find the trace by traceId or time range
2. Look for the RED span (error status)
3. Expand span attributes for error details
4. Check parent spans for context

Query example:
  service.name = "my-service"
  status = ERROR
  span.kind = INTERNAL
```

### 3. Debug step.try() Failures

When third-party code throws:

```typescript
const config = await step.try(
  () => {
    deps.logger.debug('Parsing config JSON', { raw: user.configJson });
    return JSON.parse(user.configJson);
  },
  {
    error: 'INVALID_CONFIG' as const,
    onError: (e) => {
      // Log the actual exception before it's converted to Result
      deps.logger.error('JSON.parse failed', {
        error: e instanceof Error ? e.message : String(e),
        raw: user.configJson?.substring(0, 100),  // First 100 chars
      });
    },
  }
);
```

## Integration with Observability

When debugging in production, leverage your existing traces:

1. **Find the trace** - Use traceId from logs or error reports
2. **Walk the spans** - Each step() creates a child span
3. **Check attributes** - Look for error.type, error.message
4. **Correlate with logs** - Use traceId to find related log entries

```typescript
// In your error handler, include trace context
app.use((err, req, res, next) => {
  const span = trace.getSpan(context.active());
  logger.error('Request failed', {
    error: err.message,
    traceId: span?.spanContext().traceId,
    spanId: span?.spanContext().spanId,
    path: req.path,
  });
  res.status(500).json({ error: 'Internal error', traceId: span?.spanContext().traceId });
});
```

## Remember

- **Evidence before hypothesis** - Don't guess, measure
- **One change at a time** - Know what fixed it
- **Structured logging pays off** - Pino + OpenTelemetry
- **Keep observability** - Debug logs become production traces
- **Use existing traces** - Don't re-instrument if traces already exist
