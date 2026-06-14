---
name: verification-before-completion
description: Requires running the relevant verification command and reading its fresh output before claiming any work is complete, fixed, or passing. Use when about to say something passes, builds, is done, or is fixed; before committing, pushing, or opening a PR; and before trusting a sub-agent's success report. Evidence before assertions, always.
version: 1.1.0
---

# Verification Before Completion

## Overview

Claiming work is complete without verification is dishonesty, not efficiency. An agent's confidence is not evidence. Only the fresh output of a verification command is. This skill installs a hard gate before every success claim: identify the command that proves the claim, run it in full this turn, read the actual output and exit code, then state the result with that evidence attached. The gate exists because the cost of a false "all tests pass" is paid downstream, in a broken CI run, a reverted commit, or a user who trusted a claim that was never checked. Past runs, partial checks, and "should work now" prove nothing.

## When to Use

- About to claim tests pass, the build succeeds, the linter is clean, or types check
- About to claim a bug is fixed or a requirement is met
- Before committing, pushing, or opening a pull request
- Before trusting a sub-agent's or tool's report of success
- After any code change, before re-asserting a previously verified status

**When NOT to use:** There is no exception. Every completion claim needs evidence. There is no "trivial enough to skip" case.

**Related:** [tdd-workflow](../tdd-workflow/SKILL.md), [debugging-methodology](../debugging-methodology/SKILL.md), [testing-strategy](../testing-strategy/SKILL.md), [session-continuity](../session-continuity/SKILL.md).

For multi-step and multi-agent coordination rules, see [`references/orchestration-patterns.md`](../../references/orchestration-patterns.md).

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
2. RUN: Execute the FULL command (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

## Verification Requirements

| Claim | Command Required | Not Sufficient |
|-------|------------------|----------------|
| Tests pass | Test output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, "looks good" |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Types check | `npm run typecheck`: no errors | Tests passing |
| Requirements met | Line-by-line checklist | Tests passing |

## MUST/SHOULD/NEVER Rules

### MUST

- MUST: Run verification command fresh before any success claim
- MUST: Show actual output, not paraphrased results
- MUST: Include exit code or failure count
- MUST: Verify ALL requirements, not just tests
- MUST: Re-verify after any code change

### SHOULD

- SHOULD: Run full test suite, not just changed tests
- SHOULD: Include typecheck and lint in verification
- SHOULD: Quote exact output when reporting results

### NEVER

- NEVER: Use "should", "probably", "seems to" for verification
- NEVER: Express satisfaction before verification ("Great!", "Perfect!", "Done!")
- NEVER: Commit/push/PR without verification
- NEVER: Trust agent success reports without independent verification
- NEVER: Rely on partial verification
- NEVER: Claim complete based on previous run

## Red Flags - STOP

If you catch yourself:
- Using "should", "probably", "seems to"
- About to say "Great!", "Perfect!", "Done!" before running commands
- About to commit without verification
- Trusting an agent's success report
- Relying on partial verification
- Thinking "just this once"
- **ANY wording implying success without having run verification**

**STOP. Run the verification command first.**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | Verify independently |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |

## Correct Patterns

**Tests:**
```
✅ [Run: npm test] [Output: 34/34 pass] "All tests pass"
❌ "Should pass now" / "Looks correct"
```

**Build:**
```
✅ [Run: npm run build] [Output: exit 0] "Build succeeds"
❌ "Linter passed" (linter doesn't check compilation)
```

**Requirements:**
```
✅ Re-read requirements → Create checklist → Verify each → Report
❌ "Tests pass, therefore complete"
```

**Agent delegation:**
```
✅ Agent reports success → Check VCS diff → Verify changes → Report actual state
❌ Trust agent report
```

## TDD Red-Green Verification

For regression tests:
```
✅ Write test → Run (PASS?) → Revert fix → Run (MUST FAIL) → Restore → Run (PASS)
❌ "I've written a regression test" (without red-green verification)
```

## Integration

| Skill | Relationship |
|-------|--------------|
| [tdd-workflow](../tdd-workflow/SKILL.md) | TDD requires verification at each red-green state |
| [debugging-methodology](../debugging-methodology/SKILL.md) | Verify the fix works before claiming fixed |
| [testing-strategy](../testing-strategy/SKILL.md) | Verification is the final testing gate |
| [session-continuity](../session-continuity/SKILL.md) | The VERIFY state enforces this gate before COMPLETE |

## Verification

Before making any completion claim, confirm:

- [ ] Identified the exact command that proves the claim
- [ ] Ran that command in full, this turn (not a previous run)
- [ ] Read the actual output and checked the exit code or failure count
- [ ] The output confirms the claim being made
- [ ] No "should", "probably", or "seems to" language used for a verified status
- [ ] Sub-agent reports were independently verified against the VCS diff or fresh output
