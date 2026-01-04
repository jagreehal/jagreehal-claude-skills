---
description: Verify that code follows jagreehal-claude-skills patterns (fn-args-deps, validation, result types, etc.)
---

Analyze the codebase and verify adherence to jagreehal-claude-skills patterns.

## Verification Checklist

### 1. Function Pattern: fn(args, deps)

Check all business logic functions for:
- [ ] Two-parameter signature: `fn(args, deps)`
- [ ] Explicit deps type defined for each function
- [ ] No hidden dependencies via imports
- [ ] No classes for business logic
- [ ] Factory at boundary (Composition Root)

**Violations to find:**
- Functions importing from `**/infra/**` directly
- Classes with constructor dependency injection
- Functions with positional parameters (3+ params)
- Missing deps type definitions

### 2. Validation at Boundary

Check for:
- [ ] Zod schemas at HTTP/queue/CLI entry points
- [ ] Business functions trust args (no internal validation)
- [ ] Branded types for IDs and sensitive values
- [ ] Consistent validation error responses

**Violations to find:**
- Validation logic inside business functions
- Missing Zod schemas at boundaries
- Inconsistent error response formats

### 3. Result Types (Never Throw)

Check for:
- [ ] Functions return `Result<T, E>`
- [ ] Using `createWorkflow()` for composition
- [ ] `step.try()` bridges throwing code
- [ ] `step.fromResult()` for Result-returning third-party code
- [ ] Exhaustive error handling in handlers

**Violations to find:**
- Business functions that throw
- Missing error handling for Result types
- Non-exhaustive switch statements on errors

### 4. Observability

Check for:
- [ ] `trace()` wrapper on business functions
- [ ] Structured logging with Pino (JSON fields, not interpolation)
- [ ] Semantic conventions for span attributes
- [ ] Span attribute redaction for sensitive data
- [ ] Log-to-trace correlation (traceId in logs)

**Violations to find:**
```bash
# String interpolation in logs
grep -rn "logger\.\w*\(\`" src/
grep -rn "logger\.\w*\(\".*\$" src/

# Missing trace wrapper
grep -rn "async function" src/domain/ | grep -v "trace("
```

### 5. Resilience

Check for:
- [ ] Retry at workflow level only (not inside functions)
- [ ] Timeouts on all external calls
- [ ] Jitter enabled for retries
- [ ] Circuit breakers for external APIs
- [ ] Only retrying transient errors

**Violations to find:**
```bash
# Retry logic inside functions
grep -rn "while.*attempt\|retry\|backoff" src/domain/

# Missing timeouts
grep -rn "await.*fetch\|axios\|http" src/ | grep -v "timeout"
```

### 6. Config Management

Check for:
- [ ] Config validated at startup with Zod
- [ ] Secrets in memory only (not process.env)
- [ ] No config reading during requests
- [ ] Fail-fast on missing required config

**Violations to find:**
```bash
# Reading env during requests
grep -rn "process\.env\." src/domain/

# Secrets in env
grep -rn "API_KEY\|SECRET\|PASSWORD" .env
```

### 7. TypeScript Config

Verify tsconfig.json has:
- [ ] `noUncheckedIndexedAccess: true`
- [ ] `exactOptionalPropertyTypes: true`
- [ ] `verbatimModuleSyntax: true`
- [ ] `erasableSyntaxOnly: true`
- [ ] `noUncheckedSideEffectImports: true`
- [ ] `@total-typescript/ts-reset` installed

### 8. ESLint Config

Verify eslint.config.mjs has:
- [ ] `no-restricted-imports` blocking infra imports
- [ ] `prefer-object-params` rule enabled
- [ ] Rules set to `'error'` not `'warn'`

### 9. Testing

Check for:
- [ ] vitest-mock-extended for typed mocks
- [ ] No vi.mock() for application code
- [ ] Database guardrails (localhost only)
- [ ] Result type assertions in tests
- [ ] Test file naming (`.test.ts`, `.test.int.ts`)

**Violations to find:**
```bash
# vi.mock usage
grep -rn "vi\.mock(" src/

# Weak assertions
grep -rn "toBeDefined()\|toBeTruthy()" src/**/*.test.ts
```

### 10. Performance Testing

Check for:
- [ ] k6 load test scripts exist
- [ ] Smoke, load, stress profiles defined
- [ ] Thresholds set for SLOs
- [ ] Trace correlation from k6 (traceparent header)

**Check:**
```bash
ls load-tests/
# Should see: smoke.js, load.js, stress.js
```

## Report Format

Generate a report with:
1. **Compliance Score**: X/10 patterns fully compliant
2. **Violations Found**: List each violation with file and line
3. **Recommended Fixes**: Specific changes needed
4. **Priority**: Critical / High / Medium

## Verification Commands

```bash
# Type check
npm run type-check

# Lint
npm run lint

# Tests pass
npm run test

# Check for pattern violations
grep -rn "throw " src/domain/
grep -rn "vi\.mock(" src/
grep -rn "from.*infra" src/domain/
```
