---
name: parallel-agent-dispatch
description: "Use when facing 2+ independent tasks that can be worked on without shared state. Dispatch one agent per problem domain for concurrent investigation."
version: 1.0.0
---

# Parallel Agent Dispatch

When you have multiple unrelated problems, investigating sequentially wastes time. Dispatch one agent per independent problem domain.

## When to Use

- MUST: When 3+ independent failures exist
- MUST: When problems have no shared state
- SHOULD: When each problem can be understood in isolation
- NEVER: When failures might be related (fix one might fix others)
- NEVER: When agents would edit same files

## Decision Flow

```
Multiple failures?
    ↓ yes
Are they independent?
    ↓ yes           → no: Single agent investigates all
Can they work in parallel?
    ↓ yes           → no: Sequential agents
Parallel dispatch
```

## The Pattern

### 1. Identify Independent Domains

Group failures by what's broken:
- File A tests: User authentication
- File B tests: Order processing
- File C tests: Email notifications

Each domain is independent - fixing auth doesn't affect email.

### 2. Create Focused Agent Tasks

Each agent gets:
- **Specific scope:** One test file or subsystem
- **Clear goal:** Make these tests pass
- **Constraints:** Don't change other code
- **Expected output:** Summary of findings and fixes

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
3. Run full test suite
4. Integrate all changes

## Agent Prompt Structure

```markdown
Fix the 3 failing tests in src/auth/user-auth.test.ts:

1. "should validate JWT token" - expects valid token, gets null
2. "should reject expired token" - not rejecting expired
3. "should refresh token" - refresh returns old token

Your task:
1. Read the test file, understand what each test verifies
2. Identify root cause - timing, logic, or configuration?
3. Fix by addressing actual issue (not just making tests pass)

Do NOT increase timeouts - find the real issue.

Return: Summary of root cause and what you fixed.
```

## MUST/SHOULD/NEVER Rules

### MUST

- MUST: Verify problems are independent before dispatching
- MUST: Give each agent specific, focused scope
- MUST: Include expected output format in prompt
- MUST: Verify fixes don't conflict after agents return
- MUST: Run full test suite after integration

### SHOULD

- SHOULD: Include error messages in agent prompts
- SHOULD: Specify constraints (what NOT to change)
- SHOULD: Request summary of root cause, not just "fixed"

### NEVER

- NEVER: Dispatch for related failures
- NEVER: Let agents edit same files
- NEVER: Skip post-integration verification
- NEVER: Use vague prompts ("fix the tests")

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Too broad scope | "Fix auth tests" not "fix all tests" |
| No context | Include error messages in prompt |
| No constraints | Specify what NOT to change |
| Vague output | Request specific summary format |

## When NOT to Use

- **Related failures:** Fix one might fix others
- **Need full context:** Understanding requires system-wide view
- **Exploratory debugging:** Don't know what's broken yet
- **Shared state:** Agents would interfere

## Integration

| Skill | Relationship |
|-------|--------------|
| `debugging-methodology` | Each agent follows debugging process |
| `verification-before-completion` | Verify after integration |
| `tdd-workflow` | Agents follow TDD when fixing |
