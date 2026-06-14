---
name: code-review-reception
description: Receives code review feedback through technical verification rather than performative agreement or blind implementation. Use when receiving review comments, before implementing reviewer suggestions, when feedback is unclear, or when a suggestion may be wrong for this codebase.
version: 1.1.0
---

# Code Review Reception

## Overview

Treat code review as technical evaluation, not emotional performance. The core principle is one rule: **verify before implementing.** Technical correctness comes before social comfort, and evidence comes before agreement. A reviewer's suggestion is a hypothesis about your code, not a command. Check it against the codebase before applying it, push back with reasoning when it's wrong, and acknowledge it factually when it's right.

This matters because performative agreement ("You're absolutely right!") and blind implementation both skip the step that makes review valuable: judgment. Rubber-stamping a wrong suggestion ships a bug; thanking a reviewer instead of verifying wastes the review.

## When to Use

- Receiving code review feedback from a human, another agent, or a model
- Before implementing any reviewer suggestion
- When feedback is unclear or items may be related
- When a suggestion may break existing functionality or conflict with established patterns

**When NOT to use:** Authoring a review of someone else's code; that is the reviewer's role, not reception.

**Related:** [verification-before-completion](../verification-before-completion/SKILL.md) (verify each fix before claiming done), [tdd-workflow](../tdd-workflow/SKILL.md) (use TDD when implementing fixes), [debugging-methodology](../debugging-methodology/SKILL.md) (follow the loop for complex fixes), [critical-peer](../critical-peer/SKILL.md) (the same honesty standard applied as a reviewer).

## The Response Pattern

```
WHEN receiving code review feedback:

1. READ:      Complete feedback without reacting
2. UNDERSTAND: Restate the requirement in your own words (or ask)
3. VERIFY:    Check the suggestion against codebase reality
4. EVALUATE:  Is it technically sound for THIS codebase?
5. RESPOND:   Technical acknowledgment or reasoned pushback
6. IMPLEMENT: One item at a time, test each
```

## Handling Unclear Feedback

```
IF any item is unclear:
  STOP — do not implement anything yet
  ASK for clarification on the unclear items

WHY: Items may be related. Partial understanding produces wrong implementation.
```

**Example:**

```
Reviewer: "Fix items 1-6"
You understand 1, 2, 3, 6. Unclear on 4, 5.

WRONG: Implement 1, 2, 3, 6 now, ask about 4, 5 later
RIGHT: "I understand 1, 2, 3, 6. Need clarification on 4 and 5 before starting."
```

## When to Push Back

Push back when the suggestion:

- Breaks existing functionality
- Comes from a reviewer who lacks full context
- Violates YAGNI (requests an unused feature)
- Is technically incorrect for this stack
- Conflicts with established patterns

**How to push back, with evidence, not defensiveness:**

```
RIGHT: "Checking — this API requires legacy support for <13. Current impl
        has the wrong bundle ID. Fix it, or drop pre-13 support?"

WRONG: "But I think..." (defensive, no evidence)
```

### YAGNI Check

```
IF reviewer suggests "implementing properly":
  grep the codebase for actual usage

  IF unused: "This endpoint isn't called anywhere. Remove it (YAGNI)?"
  IF used:   implement properly
```

## Implementation Order

For multi-item feedback:

1. Clarify anything unclear FIRST
2. Then implement in order:
   - Blocking issues (breaks, security)
   - Simple fixes (typos, imports)
   - Complex fixes (refactoring, logic)
3. Test each fix individually
4. Verify no regressions

## Acknowledging Feedback

When feedback IS correct, acknowledge through action:

```
RIGHT: "Fixed. [Brief description of what changed]"
RIGHT: "Good catch — [specific issue]. Fixed in [location]."
RIGHT: [Just fix it and show it in the code]

WRONG: "You're absolutely right!"
WRONG: "Great point!"
WRONG: "Thanks for catching that!"
```

When you pushed back and were wrong, correct factually and move on:

```
RIGHT: "You were right — I checked [X] and it does [Y]. Implementing now."
RIGHT: "Verified, you're correct. My understanding was wrong. Fixing."

WRONG: A long apology
WRONG: Defending why you pushed back
```

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "Agreeing keeps things friendly" | Friendliness that ships a wrong fix helps no one. Verify, then respond on the merits. |
| "The reviewer knows best, just do it" | Reviewers lack your full context too. A suggestion is a hypothesis to check, not a command. |
| "I'll implement all six at once to save time" | Untested batches hide which change broke what. One item, one test, every time. |
| "Pushing back looks defensive" | Pushback with evidence is engineering. Silent compliance with a wrong suggestion is the real failure. |
| "Saying thanks is just being polite" | Actions acknowledge feedback better than words. Show the fix, not the gratitude. |

## Red Flags

- "You're absolutely right!" / "Great point!" / "Thanks for catching that!"
- Implementing before verifying against the codebase
- Implementing multiple items without testing each
- Implementing partial feedback while some items are still unclear
- Pushing back with opinion ("I think...") instead of evidence
- Accepting a suggestion that breaks a passing test

## Verification

Before responding to feedback:

- [ ] Read all feedback completely without reacting
- [ ] Restated each requirement (or asked about unclear items)
- [ ] Verified each suggestion against the codebase

Before claiming done:

- [ ] Implemented one item at a time
- [ ] Tested each fix individually
- [ ] Confirmed no regressions
- [ ] Acknowledged correct feedback factually, pushed back with evidence where warranted
