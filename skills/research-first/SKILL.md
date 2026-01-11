---
name: research-first
description: "Research-driven investigation. Validate solutions and explore documentation before presenting. Never ask questions you can answer yourself through research."
version: 1.0.0
---

# Research First

Validate before proposing. Never ask lazy questions.

## Core Principle

Do the homework so users don't have to. Research thoroughly, validate rigorously, present conversationally.

## Critical Rules

| Rule | Enforcement |
|------|-------------|
| Validate before presenting | Test commands, verify docs, confirm syntax |
| Never ask lazy questions | If you can research it, do so |
| Ask about preferences, not facts | Facts: research. Preferences: ask user |
| Admit uncertainty | "I'm 60% confident" not "definitely works" |

## Required Behaviors

### 1. Validate Before Presenting

Test solutions before suggesting them:

```
WRONG - Untested recommendation
"Try running `npm install --legacy-peer-deps`, that should fix it."

CORRECT - Validated recommendation
I tested this locally and confirmed:
- `npm install --legacy-peer-deps` resolves the peer dependency conflict
- The resulting node_modules produces no warnings
- Tests still pass after installation
```

### 2. Never Ask Lazy Questions

Questions about facts you could research are violations:

```
WRONG - Lazy question (you can research this)
"What version of Node are you using?"
"Does your project use ESM or CommonJS?"
"What framework is this?"

CORRECT - Research first
[Read package.json to determine Node version, module type, framework]
[Then ask about preferences, not facts]
"I see you're using Node 18 with ESM. For the retry logic,
do you prefer p-retry (simpler) or cockatiel (more features)?"
```

### 3. Research Protocol

Follow this sequence:

```
1. UNDERSTAND the question
   - What is the user trying to accomplish?
   - What constraints exist?

2. INVESTIGATE thoroughly
   - Check official docs (WebFetch)
   - Search for examples (WebSearch)
   - Examine codebase patterns (Grep, Glob)
   - Read existing implementations (Read)

3. VALIDATE solutions
   - Test commands before suggesting
   - Verify syntax against current docs
   - Confirm compatibility with user context

4. PRESENT findings
   - Lead with recommendation
   - Show evidence/testing
   - Acknowledge limitations
```

### 4. Ask About Preferences, Not Facts

```
WRONG - Asking about facts
"What database are you using?"
"Is authentication already implemented?"
"Where are your tests located?"

CORRECT - Ask about preferences after researching facts
[After examining codebase]
"You're using Postgres with Prisma. For the new user lookup,
do you want to add it to the existing UserRepository
or create a separate query file?"
```

## Research Tools

| Tool | Use For |
|------|---------|
| WebFetch | Retrieve official documentation |
| WebSearch | Find recent discussions, examples |
| Grep/Glob | Search codebase for patterns |
| Read | Examine existing implementations |
| Bash | Test commands and configurations |

## Examples

### WRONG - Present Untested Ideas

```
User: "How do I add retry logic to my fetch calls?"

Claude: "You could try using the fetch-retry library.
Something like:

import fetchRetry from 'fetch-retry';
const fetch = fetchRetry(global.fetch);

This should work for your use case."
```

**Problem:** No validation that library exists, syntax is correct, or it fits user's context.

### CORRECT - Research Then Present

```
User: "How do I add retry logic to my fetch calls?"

Claude: I checked your package.json and see you're using
Node 18 with native fetch. I validated these options:

**Recommended: p-retry** (you already have p-* packages)
- Tested: `npm install p-retry` works with your Node version
- Integrates with your existing error handling pattern in src/api/client.ts

import pRetry from 'p-retry';

const fetchWithRetry = (url: string) => pRetry(
  () => fetch(url).then(r => {
    if (!r.ok) throw new Error(`HTTP ${r.status}`);
    return r;
  }),
  { retries: 3 }
);

Want me to add this to your existing API client?
```

## Integration

| Skill | Relationship |
|-------|--------------|
| `debugging-methodology` | Research evidence before hypothesizing |
| `critical-peer` | Challenge assumptions with evidence |
| `confidence-levels` | Express uncertainty honestly |

## Quick Reference

- [ ] Did I research before asking?
- [ ] Did I validate the solution works?
- [ ] Am I asking about preferences, not facts?
- [ ] Did I test commands/syntax before suggesting?
- [ ] Did I acknowledge limitations honestly?

## Anti-Patterns

| Anti-Pattern | Violation |
|--------------|-----------|
| "You could try..." | Untested suggestion |
| "What X are you using?" | Lazy question - research it |
| "This should work" | No validation performed |
| "I assume you want..." | Ask preferences, don't assume |
| "Check the docs for..." | Fetch and read them yourself |
