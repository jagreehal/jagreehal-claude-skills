---
name: code-flow-analysis
description: Traces a code execution path with file:line references and an execution diagram before any change is made, forcing real understanding of fn(args, deps) flows, Result propagation, and workflow composition. Use before fixing a bug, implementing a feature, refactoring, or starting a TDD cycle, whenever you are about to change non-trivial code.
version: 1.1.0
---

# Code Flow Analysis Protocol

## Overview

Trace execution paths before implementing. Understand the flow, then fix. When fixing bugs, implementing features, or refactoring, first map how the code currently flows through your `fn(args, deps)` functions, Result types, and workflows, using concrete `file:line` references, not abstractions like "the handler."

**Why this matters:** Understanding the flow makes the solution obvious; guessing wastes time. A five-line diagram of the real path exposes where to add code, where errors propagate, and which assumptions are wrong before you touch anything.

## When to Use

Before:
- Fixing bugs
- Implementing features
- Refactoring
- Starting TDD cycles
- Debugging issues

**When NOT to use:** Typos, formatting, documentation-only changes. These don't need a trace.

**Related:** Run this BEFORE [debugging-methodology](../debugging-methodology/SKILL.md) adds instrumentation; the trace tells you where to probe. Feeds the RED phase of [tdd-workflow](../tdd-workflow/SKILL.md). Always show [result-types](../result-types/SKILL.md) propagation and [fn-args-deps](../fn-args-deps/SKILL.md) signatures in diagrams. Identify where retry/timeout belongs per [resilience](../resilience/SKILL.md), validation per [validation-boundary](../validation-boundary/SKILL.md), and state certainty with [confidence-levels](../confidence-levels/SKILL.md).

## The Protocol (3 Quick Steps)

**Keep it lightweight** - This isn't detailed planning, just enough to guide implementation. 5-10 lines max for diagrams.

### 1. Trace the Execution Path

Answer these with **file:line references**:

- **Entry point:** Which event/request triggers this? (`src/api/routes.ts:45`)
- **Function chain:** Which `fn(args, deps)` functions are called? (`src/domain/get-user.ts:12`)
- **Error location:** Where does the failure occur? (`src/domain/get-user.ts:28`)
- **Workflow composition:** Does it use `createWorkflow()`? Which steps? (`src/workflows/load-user-data.ts:23`)
- **Result flow:** How does the Result propagate? (`src/api/handlers.ts:67`)

### 2. Quick Diagram

Simple class.method() flow with relevant data and Result types:

```
Event: POST /users/:id
  ↓ (args: { userId: string })
Handler.getUser() [src/api/handlers.ts:45]
  ↓ (validates with Zod)
getUser(args, deps) [src/domain/get-user.ts:12]
  ↓ (deps: { db, logger })
deps.db.findUser() [src/infra/database.ts:89]
  ↓ (returns: User | null)
Result check [src/domain/get-user.ts:28] ← 💥 Error here
  ↓ (if null) → err('NOT_FOUND')
  ↓ (if user) → ok(user)
resultToResponse() [src/api/handlers.ts:67]
  ↓
HTTP 200 or 404
```

**Keep it short** - 5-10 lines max. Focus on the relevant path.

**Key elements:**
- Show `fn(args, deps)` signatures
- Show Result types (`ok()` vs `err()`)
- Show workflow steps if applicable
- Mark error location with 💥
- Include relevant data fields in flow

### 3. Verify Understanding

Ask: "Here's the flow: [diagram]. The error occurs at [file:line] when [condition]. Correct?"

**Wait for confirmation, then proceed.**

**Skip for trivial changes** - Typos, formatting, docs-only changes don't need this protocol.

## Integration with Patterns

### fn(args, deps) Pattern

When tracing, identify:
- Which functions receive which `args`
- Which `deps` are injected at each step
- Where dependencies are wired (composition root)

```typescript
// Trace shows:
getUser(args: { userId }, deps: { db, logger })
  ↓
createUser(args: { name, email }, deps: { db, logger, mailer })
  ↓
// Question: Why does createUser need mailer but getUser doesn't?
// Answer: Each function declares only what it uses (per fn-args-deps)
```

### Result Types

Show Result propagation:

```
getUser() → Result<User, 'NOT_FOUND' | 'DB_ERROR'>
  ↓
createWorkflow({ getUser })
  ↓
step(() => getUser(...)) → unwraps Result
  ↓
if err → short-circuits, returns err
if ok → continues to next step
```

### Workflow Composition

Trace through `createWorkflow()`:

```
workflow(async (step) => {
  const user = await step(() => getUser(...));      // Step 1
  const posts = await step(() => getPosts(...));    // Step 2 (skipped if Step 1 err)
  return { user, posts };                           // Only if all ok
})
```

## Example: Bug Fix

**Problem:** `getUser` returns `err('DB_ERROR')` but database is working.

**❌ WRONG (guessing):**
"I'll add retry logic to getUser."

**✅ RIGHT (tracing first):**

1. **Trace:**
   - Entry: `GET /users/:id` → `Handler.getUser` [src/api/handlers.ts:45]
   - Calls: `getUser(args, deps)` [src/domain/get-user.ts:12]
   - Error: `catch` block returns `err('DB_ERROR')` [src/domain/get-user.ts:28]
   - But: `deps.db.findUser` is mocked in tests, real DB in integration

2. **Diagram:**
   ```
   Handler.getUser() [src/api/handlers.ts:45]
     ↓
   getUser(args, deps) [src/domain/get-user.ts:12]
     ↓
   deps.db.findUser() [src/infra/database.ts:89]
     ↓ (throws Error)
   catch block [src/domain/get-user.ts:28] ← 💥 Returns err('DB_ERROR')
     ↓
   But: Error message is "Connection timeout", not "Connection refused"
   ```

3. **Verify:** "The error occurs in the catch block, but the actual error is a timeout, not a connection failure. The function is catching all errors as 'DB_ERROR'. Should we distinguish timeout vs connection errors?"

**Now the fix is clear:** Add specific error handling for timeout vs connection errors, or add timeout to the workflow level (per resilience patterns).

## Example: Feature Implementation

**Request:** "Add email validation to user creation."

**❌ WRONG:**
"I'll add validation inside createUser function."

**✅ RIGHT:**

1. **Trace current flow:**
   ```
   POST /users
     ↓
   Handler.createUser() [src/api/handlers.ts:67]
     ↓
   createUserSchema.safeParse() [src/api/handlers.ts:70] ← Validation happens here
     ↓
   createUser(args, deps) [src/domain/create-user.ts:15]
     ↓
   deps.db.saveUser() [src/infra/database.ts:102]
   ```

2. **Diagram shows:** Validation already happens at boundary (per validation-boundary pattern).

3. **Verify:** "Email validation should be in the Zod schema at the boundary, not inside createUser. The schema is at [file:line]. Should I add email validation there?"

## Rules

1. **Always trace before implementing** - No exceptions for non-trivial changes
2. **Use file:line references** - Not abstractions like "the handler" or "some function"
3. **Show Result flow** - How errors propagate through the system
4. **Show deps injection** - Where dependencies come from
5. **Get confirmation** - Don't proceed without user verification
6. **Keep diagrams concise** - 5-15 lines, focus on the relevant path

## Anti-Patterns

❌ **"I'll fix the validation error"** (didn't trace where it occurs)
✅ **"Let me trace where validation fails... [diagram]. The error is at [file:line] when [condition]. Correct?"**

❌ **"I'll add retry logic"** (didn't check if retry exists at workflow level)
✅ **"Tracing the flow... [diagram]. Retry should be at workflow level per resilience patterns, not inside the function. Correct?"**

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "I already know how this flows" | Then writing the 5-line diagram costs nothing and confirms it |
| "Tracing slows me down" | Guessing wrong and re-fixing is slower; one wrong fix erases the savings |
| "It's just a small change" | Small changes in the wrong place still break the flow |
| "I'll trace it if the first fix fails" | The first fix sets the pattern; trace first |

## Quick Reference

| Situation | What to Trace |
|-----------|--------------|
| Bug fix | Error location, Result flow, deps chain |
| Feature | Entry point, function chain, where to add code |
| Refactor | Current flow, what changes, impact on callers |
| Performance | Slow path, external calls, workflow steps |

## Red Flags - STOP and Trace First

If you catch yourself:
- Proposing a fix without a `file:line` for where the failure occurs
- Referring to code by abstraction ("the handler", "some function") instead of a path
- Adding retry/validation/caching without checking whether it already exists upstream
- Changing a function's internals without knowing who calls it
- Assuming a `Result` is `ok()` without tracing where `err()` can originate

**ALL of these mean: STOP. Produce the diagram, then proceed.**

## Verification

Before implementing, confirm:

- [ ] Entry point identified with `file:line`
- [ ] Full `fn(args, deps)` call chain mapped with `file:line` references
- [ ] `Result` propagation shown (`ok()` / `err()` paths and short-circuits)
- [ ] Error/change location marked precisely
- [ ] Diagram is concise (5-15 lines, relevant path only)
- [ ] Understanding confirmed with the user before changing code

