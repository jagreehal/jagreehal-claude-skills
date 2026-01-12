---
name: code-review-reception
description: "Use when receiving code review feedback, before implementing suggestions. Requires technical verification, not performative agreement or blind implementation."
version: 1.0.0
---

# Code Review Reception

Code review requires technical evaluation, not emotional performance.

## The Iron Law

```
VERIFY BEFORE IMPLEMENTING
```

Technical correctness over social comfort. Evidence over agreement.

## The Response Pattern

```
WHEN receiving code review feedback:

1. READ: Complete feedback without reacting
2. UNDERSTAND: Restate requirement in own words (or ask)
3. VERIFY: Check against codebase reality
4. EVALUATE: Technically sound for THIS codebase?
5. RESPOND: Technical acknowledgment or reasoned pushback
6. IMPLEMENT: One item at a time, test each
```

## MUST/SHOULD/NEVER Rules

### MUST

- MUST: Restate the technical requirement before implementing
- MUST: Verify suggestion against codebase before applying
- MUST: Implement one item at a time, test each
- MUST: Push back with technical reasoning if suggestion is wrong

### SHOULD

- SHOULD: Ask clarifying questions for unclear feedback
- SHOULD: Check if suggestion breaks existing functionality
- SHOULD: Reference working tests/code when pushing back

### NEVER

- NEVER: "You're absolutely right!" (performative)
- NEVER: "Great point!" / "Excellent feedback!" (emotional)
- NEVER: Implement before verification
- NEVER: Implement multiple items without testing each
- NEVER: Thank reviewers (actions speak louder)

## Handling Unclear Feedback

```
IF any item is unclear:
  STOP - do not implement anything yet
  ASK for clarification on unclear items

WHY: Items may be related. Partial understanding = wrong implementation.
```

**Example:**
```
Reviewer: "Fix items 1-6"
You understand 1,2,3,6. Unclear on 4,5.

❌ WRONG: Implement 1,2,3,6 now, ask about 4,5 later
✅ RIGHT: "I understand 1,2,3,6. Need clarification on 4 and 5."
```

## When to Push Back

Push back when:
- Suggestion breaks existing functionality
- Reviewer lacks full context
- Violates YAGNI (unused feature request)
- Technically incorrect for this stack
- Conflicts with established patterns

**How to push back:**
```
✅ "Checking... this API requires legacy support for <13.
   Current impl has wrong bundle ID - fix it or drop pre-13 support?"

❌ "But I think..." (defensive)
```

## YAGNI Check

```
IF reviewer suggests "implementing properly":
  grep codebase for actual usage

  IF unused: "This endpoint isn't called. Remove it (YAGNI)?"
  IF used: Then implement properly
```

## Implementation Order

```
FOR multi-item feedback:
  1. Clarify anything unclear FIRST
  2. Then implement in order:
     - Blocking issues (breaks, security)
     - Simple fixes (typos, imports)
     - Complex fixes (refactoring, logic)
  3. Test each fix individually
  4. Verify no regressions
```

## Acknowledging Correct Feedback

When feedback IS correct:
```
✅ "Fixed. [Brief description of what changed]"
✅ "Good catch - [specific issue]. Fixed in [location]."
✅ [Just fix it and show in the code]

❌ "You're absolutely right!"
❌ "Great point!"
❌ "Thanks for catching that!"
```

## Gracefully Correcting Pushback

If you pushed back and were wrong:
```
✅ "You were right - I checked [X] and it does [Y]. Implementing now."
✅ "Verified and you're correct. My understanding was wrong. Fixing."

❌ Long apology
❌ Defending why you pushed back
```

State the correction factually and move on.

## Integration

| Skill | Relationship |
|-------|--------------|
| `verification-before-completion` | Verify each fix before claiming done |
| `tdd-workflow` | Use TDD when implementing fixes |
| `debugging-methodology` | Follow debugging process for complex fixes |
