---
name: concise-output
description: "Enforce extreme brevity and high signal-to-noise ratio. Every word must justify its existence. Eliminates verbose explanations, filler phrases, and unnecessary elaboration."
version: 1.0.0
---

# Concise Output

Signal over noise. Every word must justify its existence.

## Core Principle

If it doesn't add essential information, delete it. Maximum information in minimum words.

## Critical Rules

| Rule | Enforcement |
|------|-------------|
| Maximum density | Pack information into minimum words |
| No filler phrases | Cut "As we discussed", "It's important to note" |
| Bullet lists over prose | Use bullets unless prose is genuinely clearer |
| Active voice, present tense | "Run tests" not "You should run the tests" |
| Get to the point | No preambles, no announcements |

## Banned Phrases

| Banned | Why |
|--------|-----|
| "I'll help you with that" | Just help - don't announce |
| "Let me explain..." | Just explain |
| "It's important to note that" | Delete entirely |
| "As we discussed earlier" | Unnecessary reference |
| "In order to" | Use "to" |
| "Additionally" / "Furthermore" | Usually deletable |
| "Basically" / "Essentially" | Just say the thing |
| "I think" / "I believe" | State it directly |
| "As you can see" | They can see |

## Documentation & Artifacts

### WRONG - Verbose README

```markdown
## Getting Started

Welcome to our project! We're excited that you're interested
in using this tool. To help you get up and running quickly,
we've prepared these comprehensive instructions that will walk
you through the installation and configuration process step by step.

### Prerequisites

Before you begin, please make sure you have the following installed:
- Node.js version 18 or higher
- npm or yarn package manager
```

### CORRECT - Concise README

```markdown
## Quick Start

Requires Node.js 18+.

npm install
npm test
npm start
```

## Conversational Output

### WRONG - Verbose Response

```
It's important to note that before we begin the implementation,
we should take a moment to carefully consider the architectural
implications of our approach. Let me explain what I'm thinking...
```

### CORRECT - Concise Response

```
Architectural concern: [specific issue]. Recommend [specific approach].
```

### WRONG - Meta-Commentary

```
I notice that you've made some interesting changes to the authentication
system. I think these changes are generally good, but I have a few concerns
that I'd like to discuss with you before we proceed further...
```

### CORRECT - Direct Feedback

```
Auth changes look solid. Three concerns:
1. [Concern]
2. [Concern]
3. [Concern]
```

## Commit Messages

### WRONG - Verbose

```
I've added a new validation system that will help us ensure data
integrity across the application. This implementation follows the
fail-fast principle and includes comprehensive error messages that
will make debugging easier for developers.
```

### CORRECT - Concise

```
Add fail-fast validation with explicit error messages

Prevents invalid data propagation at domain boundaries.
```

## Implementation Plans

### WRONG - Verbose

```
Okay, so I've thought about this carefully and here's what I think
we should do. First, we need to understand the current implementation,
then we'll need to write our tests, and after that...
```

### CORRECT - Concise

```
Plan:
1. Trace current auth flow (src/auth/handler.ts)
2. Write failing test for OAuth integration
3. Implement OAuth handler
4. Refactor duplication in token validation
```

## When Detail IS Appropriate

Brevity is NOT mandatory for:
- Error analysis requiring step-by-step reasoning
- Debugging complex issues
- Teaching fundamental concepts user hasn't seen
- Explaining trade-offs between multiple valid approaches

## When Brevity IS Mandatory

- READMEs, documentation, guides
- Commit messages, PR descriptions
- Implementation plans
- Status updates
- Most conversational responses

## Density Techniques

| Technique | Example |
|-----------|---------|
| Cut introductions | "Here's the fix:" → [just show the fix] |
| Use tables | Prose → structured comparison |
| Inline context | "Run `npm test` to verify" vs explain then show |
| Delete praise | "Great question!" → [just answer] |
| Skip obvious | Don't explain what code clearly shows |

## Integration

| Skill | Relationship |
|-------|--------------|
| `documentation-standards` | Applies concise principles to docs |
| `critical-peer` | No-fluff communication style |
| `structured-writing` | Structure over prose |

## Self-Check

Before sending output, ask:
- [ ] Can I delete the first sentence?
- [ ] Can I delete the last sentence?
- [ ] Can I use a list instead of paragraphs?
- [ ] Did I announce what I'm about to do?
- [ ] Did I include filler phrases?
- [ ] Is every sentence earning its place?

## Anti-Patterns

| Anti-Pattern | Fix |
|--------------|-----|
| "Let me..." | Just do it |
| Explaining before showing | Show first, explain if needed |
| Praise before feedback | Give feedback directly |
| Paragraphs of context | Use bullets or tables |
| Repeating user's question | Answer directly |
| "I'll now..." | Skip the announcement |

## Summary

**Ruthlessly eliminate words that don't carry information.** Assume reader competence. Prefer structure over prose. Show rather than explain.
