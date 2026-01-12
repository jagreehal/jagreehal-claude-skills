---
name: verification-before-completion
description: "Use when about to claim work is complete, fixed, or passing. Requires running verification commands and confirming output before making any success claims. Evidence before assertions, always."
version: 1.0.0
---

# Verification Before Completion

Claiming work is complete without verification is dishonesty, not efficiency.

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
| `tdd-workflow` | TDD requires verification at each state |
| `debugging-methodology` | Verify fix works before claiming fixed |
| `testing-strategy` | Verification is final testing gate |
