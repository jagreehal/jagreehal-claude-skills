---
name: confidence-levels
description: "Force honest confidence assessment. Express confidence as percentage, explain gaps, validate assumptions before presenting conclusions."
version: 1.0.0
---

# Confidence Levels

Express confidence as a percentage, not vague certainty.

## Core Principle

A thorough analysis that *looks* certain but isn't can mislead users into wrong decisions. Conflating explanation quality with evidence quality causes harm.

## Critical Rules

| Rule | Enforcement |
|------|-------------|
| Express confidence as % | Not "probably" - use "70% confident" |
| Explain gaps below 95% | Mandatory "Why not 100%?" |
| Validate before presenting | If you can gather evidence, do it |
| Show your math | Evidence adds confidence, gaps subtract |

## Confidence Scale

| Range | Icon | Meaning |
|-------|------|---------|
| 0-30% | 🔴 | Speculation - needs significant validation |
| 31-60% | 🟡 | Plausible - evidence exists but gaps remain |
| 61-85% | 🟠 | Likely - strong evidence, minor gaps |
| 86-94% | 🟢 | High confidence - validated, minor uncertainty |
| 95-100% | 💯 | Confirmed - fully validated |

## Calibration Guide

| Level | Meaning |
|-------|---------|
| 20% | One possibility among several |
| 40% | Evidence points this direction, key assumptions unverified |
| 60% | Evidence supports this, alternatives not ruled out |
| 80% | Strong evidence, assumptions verified, alternatives less likely |
| 95% | Validated with direct evidence, alternatives ruled out |
| 100% | Mathematical/logical certainty only |

## Pre-Conclusion Checkpoint

Before claiming ANY conclusion, complete this:

### 1. Evidence Inventory
- What hard evidence supports this?
- Direct evidence (code/logs that prove it)?
- What's the strongest piece of evidence?

### 2. Falsifiability Check
- What would INVALIDATE this theory?
- Have I looked for that data?
- If no: WHY NOT?

### 3. Assumption Audit
- What am I assuming WITHOUT verification?
- Mark each: [VERIFIED] or [ASSUMED]

### 4. Alternative Possibilities
- What else could explain these symptoms?
- Why is my conclusion more likely?

## Confidence Scoring

**Start at 50% (neutral) and adjust:**

| Factor | Adjustment |
|--------|------------|
| Direct evidence (code/logs proving it) | +15-25% |
| Verified assumptions (checked, not assumed) | +10-15% |
| Alternatives ruled out with evidence | +10-15% |
| Falsifiability check completed | +5-10% |
| Unverified critical assumptions | -15-25% |
| Plausible alternatives not ruled out | -10-15% |
| No falsifiability check | -10% |
| Circumstantial evidence only | -10% |

## Response Format

```
[Icon] [X%] Confidence: [One sentence finding]

Evidence:
- [+X%] [Evidence 1]
- [+X%] [Evidence 2]

Why not 100%:
- [-X%] [Gap 1]

To increase confidence: [What's needed]
```

## Examples

### WRONG - Premature Certainty

```
Claude: "I have complete clarity on the root cause. The issue
is definitely the database connection pool being exhausted.
Here's my detailed analysis..."

[200 lines of report]

User: [provides data that contradicts analysis]

Claude: "This changes everything..."
```

**Problem:** Claimed certainty with unverified assumptions.

### CORRECT - Honest Assessment

```
🟡 40% Confidence: Database connection pool may be exhausted

Evidence:
- [+15%] Error pattern matches connection timeout
- [+10%] Load spike occurred around failure time

Why not 100%:
- [-25%] Haven't verified actual pool metrics
- [-15%] Haven't ruled out: network issues, DNS problems
- [-10%] This is mostly pattern matching, not direct evidence

To increase confidence: I need the connection pool metrics
from the time of failure. Can you provide those?
```

### WRONG - Confidence in Explanation Quality

```
Claude: "Based on my thorough analysis of the code flow,
I'm certain the bug is in the authentication middleware."
```

**Problem:** Thoroughness of presentation ≠ correctness. Detailed reasoning without verified evidence is speculation.

### CORRECT - Evidence-Based Confidence

```
🟠 75% Confidence: Bug is in authentication middleware

Evidence:
- [+20%] Error message explicitly mentions "token expired"
- [+15%] Code trace shows validation at auth/middleware.ts:45
- [+10%] Token timestamp is from 2 hours ago

Why not 100%:
- [-10%] Haven't verified the clock sync between servers
- [-15%] Could be a different middleware in the chain

To increase confidence: Let me check the server time sync
and trace the full middleware chain.
```

## Self-Validation Rule

Before returning to user with questions you can answer yourself:

```
Can I gather more evidence myself?
├─ Search codebase for confirming/denying data?
├─ Fetch a file that validates an assumption?
├─ Check actual state vs assumed state?
└─ Run a test to verify?

If YES → DO IT. Then reassess confidence.
If NO → Present with honest confidence + what you need.
```

**Critical:** If confidence is below 80% and you CAN gather more evidence → DO IT.

## Trigger Words

Auto-invoke this skill when about to claim:
- "root cause is", "the problem is"
- "complete clarity", "definitely", "certainly"
- "clearly the issue", "obviously"
- Any conclusive claim during investigation

## Integration

| Skill | Relationship |
|-------|--------------|
| `critical-peer` | Challenge conclusions lacking evidence |
| `research-first` | Gather evidence before concluding |
| `debugging-methodology` | Evidence-based investigation |

## Anti-Patterns

| Anti-Pattern | Violation |
|--------------|-----------|
| "Complete clarity" | Claimed certainty without validation |
| "Definitely the issue" | Unqualified conclusion |
| Building detailed reports | Thoroughness ≠ correctness |
| "It's probably X" | Missing confidence % and gaps |
| Skipping falsifiability | Haven't asked "what would prove me wrong?" |

## Quick Reference

- [ ] Did I express confidence as a percentage?
- [ ] Did I explain what's stopping 100%?
- [ ] Did I show evidence for the % claimed?
- [ ] Could I gather more evidence myself?
- [ ] Did I check for falsifying evidence?
