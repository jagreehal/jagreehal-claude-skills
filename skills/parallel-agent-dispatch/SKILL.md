---
name: parallel-agent-dispatch
description: Dispatches one focused agent per independent problem domain for concurrent investigation. Use when facing 2+ independent failures or tasks with no shared state, when sequential investigation wastes time, or when work can be safely parallelized across agents.
version: 1.1.0
---

# Parallel Agent Dispatch

## Overview

Dispatch one agent per independent problem domain so unrelated work runs concurrently instead of sequentially. When you have multiple unrelated problems, investigating them one at a time wastes time and bloats a single context window with details that don't interact. Splitting the work gives each agent a narrow scope, a clear goal, and a clean context, which produces sharper fixes and a faster overall turnaround.

The hard constraint: domains must be independent. If two failures might share a root cause, a single agent that sees both is more likely to find it than two agents that each see half.

## When to Use

- 3+ independent failures exist across unrelated subsystems
- Problems have no shared state and don't touch the same files
- Each problem can be understood in isolation
- Sequential investigation would waste time on context that doesn't interact

**When NOT to use:**

- Failures might be related: fixing one could fix the others
- Understanding requires a system-wide view
- Exploratory debugging where you don't yet know what's broken
- Agents would edit the same files and conflict

**Related:** [debugging-methodology](../debugging-methodology/SKILL.md) (each agent follows the debugging loop), [verification-before-completion](../verification-before-completion/SKILL.md) (verify after integration), [tdd-workflow](../tdd-workflow/SKILL.md) (agents fix test-first).

For multi-step and multi-agent coordination rules, see [`references/orchestration-patterns.md`](../../references/orchestration-patterns.md).

## Decision Flow

```
Multiple failures?
    │ yes
    ▼
Are they independent?  ── no ──▶ Single agent investigates all
    │ yes
    ▼
Can they work in parallel?  ── no ──▶ Sequential agents
    │ yes
    ▼
Parallel dispatch
```

## The Pattern

### 1. Identify Independent Domains

Group failures by what's broken. Each domain must be independent: fixing one cannot affect another.

```
File A tests: User authentication
File B tests: Order processing
File C tests: Email notifications
```

Fixing auth doesn't touch email. These are safe to split.

### 2. Create Focused Agent Tasks

Each agent gets:

- **Specific scope:** one test file or subsystem, not "all tests"
- **Clear goal:** make these tests pass by fixing the real issue
- **Constraints:** what NOT to change
- **Expected output:** a summary of root cause and fixes, not just "done"

### 3. Dispatch in Parallel

```typescript
// Dispatch all three concurrently
Task("Fix user-auth.test.ts failures")
Task("Fix order-processing.test.ts failures")
Task("Fix email-notifications.test.ts failures")
```

### 4. Review and Integrate

When agents return:

1. Read each summary
2. Verify fixes don't conflict
3. Run the full test suite
4. Integrate all changes

## Agent Prompt Template

```markdown
Fix the 3 failing tests in src/auth/user-auth.test.ts:

1. "should validate JWT token" — expects valid token, gets null
2. "should reject expired token" — not rejecting expired
3. "should refresh token" — refresh returns old token

Your task:
1. Read the test file, understand what each test verifies
2. Identify root cause — timing, logic, or configuration?
3. Fix by addressing the actual issue, not just making tests pass

Do NOT increase timeouts — find the real issue.

Return: summary of root cause and what you fixed.
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Scope too broad | "Fix auth tests" not "fix all tests" |
| No context | Include error messages in the prompt |
| No constraints | Specify what NOT to change |
| Vague output | Request a specific summary format |
| Dispatched related failures | Investigate as one before splitting |

## Red Flags

- Dispatching agents for failures that might share a root cause
- Two agents that would edit the same files
- Skipping the full-suite run after integration
- Vague prompts like "fix the tests" with no scope or expected output
- Agents asked to "make tests pass" without finding the real cause

## Verification

Before dispatching:

- [ ] Problems are confirmed independent (no shared state, no shared files)
- [ ] Each agent has specific scope, clear goal, and constraints
- [ ] Each prompt includes error messages and an expected output format

After agents return:

- [ ] Each summary read and root cause understood
- [ ] Fixes checked for conflicts
- [ ] Full test suite passes after integration
