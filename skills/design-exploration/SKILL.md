---
name: design-exploration
description: Explores user intent, requirements, and trade-offs through collaborative dialogue before any code is written, producing a validated design document. Use before creating features, building components, or making significant behavior changes. Use when requirements are ambiguous, when an architectural decision is imminent, or when you are tempted to start coding without a shared understanding of what "done" means.
version: 1.1.0
---

# Design Exploration

## Overview

Turn an idea into a fully-formed design through collaborative dialogue, then write it down before any production code exists. The design document is the shared source of truth between you and the human: it defines what we are building, why, and how we will know it is done. Code without an agreed design is guessing, and guessing at speed is how an agent produces a confident, well-tested implementation of the wrong thing.

The core principle is an iron law:

```
NO IMPLEMENTATION WITHOUT DESIGN AGREEMENT FIRST
```

If the design has not been validated by the human, you cannot write production code. The entire value of this skill is surfacing misunderstandings *before* they get encoded.

## When to Use

- Before creating a new feature
- Before building a new component
- Before a significant behavior change
- Before making an architectural decision
- When requirements are ambiguous or only exist as a vague idea
- Before complex refactoring

**When NOT to use:** Single-file, single-function changes with unambiguous, self-contained requirements; typo fixes; or work where the design is already documented and approved.

**Related:** Feed the output into [implementation-planning](../implementation-planning/SKILL.md) to turn the validated design into tasks. Isolate the work in a [git-worktrees](../git-worktrees/SKILL.md) workspace if it needs to run in parallel. Implementation follows [tdd-workflow](../tdd-workflow/SKILL.md).

## The Process

### Phase 1: Understand Context

- Check current project state: files, docs, recent commits
- Understand what exists before proposing changes
- Review related code to learn existing patterns and conventions

### Phase 2: Clarify Intent

- Ask questions one at a time; never bundle multiple questions into one message
- Prefer multiple choice when the option space is known
- Focus on purpose, constraints, and success criteria
- Never assume requirements without asking
- Never skip clarification because "it seems obvious"

### Phase 3: Explore Approaches

- Propose 2-3 different approaches with explicit trade-offs (complexity, performance, maintainability)
- Lead with your recommendation and explain why
- Never present only one option

### Phase 4: Present Design

- Break the design into sections of 200-300 words each
- Ask after each section whether it looks right before continuing
- Cover architecture, components, data flow, error handling, and testing
- Be ready to backtrack and re-clarify
- Never dump the entire design in one massive message

### Phase 5: Document and Proceed

- Write the validated design to `docs/plans/YYYY-MM-DD-<topic>-design.md`
- Commit the design document; it belongs in version control alongside the code
- Ask "Ready to set up for implementation?"

## Question Patterns

**Good: multiple choice**
```
How should we handle authentication?

1. JWT tokens (stateless, scalable)
2. Session cookies (simpler, server-managed)
3. OAuth delegation (external provider)

Which fits your needs?
```

**Good: focused open-ended**
```
What should happen when a user's session expires mid-operation?
```

**Bad: multiple questions at once**
```
What auth method? How should errors be handled? What about rate limiting?
```

**Bad: leading question**
```
You want JWT tokens, right?
```

## YAGNI Ruthlessly

- Remove unnecessary features from every design
- Challenge every "nice to have"
- Ask "Do we need this for v1?"
- Never add features "while we're at it"
- Never design for hypothetical future requirements

## Design Document Template

```markdown
# [Feature Name] Design

**Goal:** [One sentence]

**Constraints:**
- [List constraints]

## Architecture

[2-3 sentences + diagram if helpful]

## Components

### [Component 1]
- Purpose:
- Inputs:
- Outputs:
- Error cases:

## Data Flow

[Sequence or flow description]

## Error Handling

| Error | Response |
|-------|----------|
| ... | ... |

## Testing Strategy

- Unit: [what]
- Integration: [what]
- Edge cases: [list]

## Open Questions

- [ ] [Any unresolved decisions]
```

## Red Flags

If you catch yourself doing any of these, STOP and return to the appropriate phase:

- Starting to write code before the design is validated
- Presenting the entire design at once
- Asking multiple questions in one message
- Offering only one approach
- Adding features "just in case"
- Silently filling in ambiguous requirements instead of asking

## Verification

Before proceeding to planning, confirm:

- [ ] You understand the existing project state and patterns
- [ ] All ambiguous requirements were clarified one question at a time
- [ ] 2-3 approaches were presented with trade-offs and a recommendation
- [ ] The design covers architecture, components, data flow, error handling, and testing
- [ ] The human has reviewed and approved each section
- [ ] The design document is saved to `docs/plans/` and committed
