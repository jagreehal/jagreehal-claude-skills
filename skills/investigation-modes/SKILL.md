---
name: investigation-modes
description: "Three explicit investigation modes: LEARNING (build understanding), INVESTIGATION (diagnose problems), SOLVING (implement fixes). Prefix messages with mode, ask before transitioning."
version: 1.0.0
---

# Investigation Modes

Investigate technical problems systematically with explicit modes.

## Core Principle

Operate in exactly one mode at a time. Ask before transitioning. User controls the pace.

## Critical Rules

| Rule | Enforcement |
|------|-------------|
| Prefix every message | `[MODE: LEARNING]`, `[MODE: INVESTIGATION]`, `[MODE: SOLVING]` |
| Ask before transitioning | Never change modes without user confirmation |
| User controls pace | "do X, THEN Y" = complete X, STOP, ask before Y |
| Stay in your lane | Each mode has boundaries |

## Mode State Machine

```
              ┌──────────────────────────────────────────┐
              │                                          │
              ▼                                          │
    ┌─────────────────┐                                 │
    │    LEARNING     │◀─────────────────────┐          │
    │ (understand)    │                      │          │
    └────────┬────────┘                      │          │
             │                               │          │
             │ "Ready to investigate?"       │          │
             │                               │          │
             ▼                               │          │
    ┌─────────────────┐                      │          │
    │  INVESTIGATION  │──────────────────────┘          │
    │ (diagnose)      │   "Need more context"           │
    └────────┬────────┘                                 │
             │                                          │
             │ "Ready to solve?"                        │
             │                                          │
             ▼                                          │
    ┌─────────────────┐                                 │
    │    SOLVING      │─────────────────────────────────┘
    │ (implement)     │   "Need to reinvestigate"
    └─────────────────┘
```

## Mode Definitions

### [MODE: LEARNING]

**Triggers:** understand, analyze, map, familiarize, schema, "how does X work"

**Purpose:** Build mental models and reusable understanding

**Outputs:**
- Architecture schemas and diagrams
- Process documentation
- System mappings
- Clarifying questions

**Boundaries:**
- ⛔ Do NOT analyze specific incidents
- ⛔ Do NOT form hypotheses about problems
- ⛔ Do NOT propose fixes

**Exit:** "I've completed the [schema/analysis/mapping]. Ready to move to INVESTIGATION mode?"

---

### [MODE: INVESTIGATION]

**Triggers:** investigate, debug, diagnose, find root cause, "why is X happening"

**Purpose:** Apply methodology to specific problems

**Outputs:**
- Evidence and findings
- Hypotheses with supporting data
- Timeline reconstructions
- Root cause identification

**Boundaries:**
- ⛔ Do NOT implement fixes
- ⛔ Do NOT modify code or config
- ⛔ Do NOT assume solutions without evidence

**Exit:** "Investigation complete. I've identified [findings]. Ready to move to SOLVING mode?"

---

### [MODE: SOLVING]

**Triggers:** fix, implement, resolve, correct, "how do we fix X"

**Purpose:** Implement solutions based on investigation findings

**Outputs:**
- Solution proposals
- Implementation plans
- Code/config changes
- Verification steps

**Entry requirement:** Should have investigation findings. If entering without investigation: "Note: Entering SOLVING mode without prior investigation. Should we investigate first?"

---

## Mode Selection Protocol

At session start or when unclear:

```
"What mode should I operate in?
- LEARNING: Build understanding
- INVESTIGATION: Diagnose a specific problem
- SOLVING: Implement fixes"
```

Wait for user confirmation before proceeding.

## Examples

### WRONG - Mode Mixing

```
User: "Analyze the authentication system"

Claude: "The auth system works like this... [explanation]
I noticed a potential bug in token refresh... [hypothesis]
Let me fix that now... [starts editing]"
```

**Problem:** Mixed all three modes without asking.

### CORRECT - Mode Discipline

```
User: "Analyze the authentication system"

Claude: "[MODE: LEARNING]

The authentication system consists of:

1. Login endpoint (src/auth/login.ts:12)
   - Validates credentials against user store
   - Issues JWT with 1h expiry

2. Token refresh (src/auth/refresh.ts:8)
   - Accepts refresh token
   - Issues new access token

3. Middleware (src/auth/middleware.ts:23)
   - Validates JWT on protected routes
   - Extracts user context

I've completed the system mapping.
Ready to move to INVESTIGATION mode, or would you like me
to go deeper on any component?"
```

---

### WRONG - Jumping Ahead

```
User: "Investigate the login bug, THEN we'll figure out a fix"

Claude: "I found the issue—it's a race condition in token
generation. Here's the fix: [implements fix]"
```

**Problem:** User said "THEN" - should have stopped after investigation.

### CORRECT - Respecting Sequence

```
User: "Investigate the login bug, THEN we'll figure out a fix"

Claude: "[MODE: INVESTIGATION]

Findings:

Evidence:
- Error occurs 2.3% of logins (production logs)
- Always when concurrent requests from same user
- Token table shows duplicate entries

Hypothesis (80% confidence):
Race condition in src/auth/token.ts:45
- Two requests read "no token" simultaneously
- Both create new tokens
- Second insert fails on unique constraint

Timeline:
- 10:00:00.001 - Request A reads token table (empty)
- 10:00:00.003 - Request B reads token table (empty)
- 10:00:00.010 - Request A inserts token
- 10:00:00.012 - Request B inserts token (fails)

Investigation complete. Ready to discuss solutions?"
```

## Investigation Methodology

### Scientific Method

1. **Observe:** Gather data, identify patterns
2. **Hypothesize:** Form testable explanations
3. **Experiment:** Design specific tests
4. **Evaluate:** Analyze results, adjust

### Root Cause Analysis

| Technique | When |
|-----------|------|
| 5 Whys | Simple causal chains |
| Timeline Analysis | Temporal patterns |
| Fault Tree | Complex failure scenarios |

### Performance Analysis (USE Method)

| Metric | Meaning |
|--------|---------|
| Utilization | % time resource is busy |
| Saturation | Work queued/waiting |
| Errors | Count of error events |

Apply to: CPU, memory, disk, network, connections.

## Integration

| Skill | Relationship |
|-------|--------------|
| `debugging-methodology` | Evidence-based investigation |
| `observability` | Instrument to gather evidence |
| `confidence-levels` | Express hypothesis confidence |

## Anti-Patterns

| Anti-Pattern | Violation |
|--------------|-----------|
| Mode mixing | Doing all three without asking |
| Jumping ahead | "THEN" ignored |
| Assuming solutions | Solving without evidence |
| Missing prefix | Forgot `[MODE: X]` |
| Self-transition | Changed modes without asking |

## Quick Reference

Before every message:
- [ ] Did I prefix with current mode?
- [ ] Am I staying within mode boundaries?
- [ ] Did user authorize this mode?
- [ ] If transitioning, did I ask first?
- [ ] If user said "THEN", did I stop after first part?
