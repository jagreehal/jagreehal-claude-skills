---
name: design-exploration
description: "Use before any creative work - creating features, building components, adding functionality. Explores user intent, requirements, and design before implementation. One question at a time, multiple choice preferred."
version: 1.0.0
---

# Design Exploration

Turn ideas into fully-formed designs through collaborative dialogue before writing code.

## The Iron Law

```
NO IMPLEMENTATION WITHOUT DESIGN AGREEMENT FIRST
```

If you haven't validated the design, you cannot write production code.

## When to Use

- MUST: Before creating new features
- MUST: Before building new components
- MUST: Before significant behavior changes
- SHOULD: Before complex refactoring
- SHOULD: When requirements are ambiguous

## The Process

### Phase 1: Understand Context

- MUST: Check current project state (files, docs, recent commits)
- MUST: Understand what exists before proposing changes
- SHOULD: Review related code to understand patterns

### Phase 2: Clarify Intent

- MUST: Ask questions one at a time (not multiple questions per message)
- MUST: Prefer multiple choice when possible
- MUST: Focus on: purpose, constraints, success criteria
- NEVER: Assume requirements without asking
- NEVER: Skip clarification because "it seems obvious"

### Phase 3: Explore Approaches

- MUST: Propose 2-3 different approaches with trade-offs
- MUST: Lead with your recommendation and explain why
- SHOULD: Present trade-offs: complexity, performance, maintainability
- NEVER: Present only one option

### Phase 4: Present Design

- MUST: Break design into sections (200-300 words each)
- MUST: Ask after each section if it looks right
- MUST: Cover: architecture, components, data flow, error handling, testing
- SHOULD: Be ready to backtrack and clarify
- NEVER: Present entire design in one massive dump

### Phase 5: Document and Proceed

- MUST: Write validated design to `docs/plans/YYYY-MM-DD-<topic>-design.md`
- MUST: Commit the design document
- SHOULD: Ask "Ready to set up for implementation?"

## Question Patterns

### Good: Multiple Choice
```
How should we handle authentication?

1. JWT tokens (stateless, scalable)
2. Session cookies (simpler, server-managed)
3. OAuth delegation (external provider)

Which fits your needs?
```

### Good: Focused Open-Ended
```
What should happen when a user's session expires mid-operation?
```

### Bad: Multiple Questions
```
What auth method? How should errors be handled? What about rate limiting?
```

### Bad: Leading Questions
```
You want JWT tokens, right?
```

## YAGNI Ruthlessly

- MUST: Remove unnecessary features from all designs
- MUST: Challenge "nice to have" features
- SHOULD: Ask "Do we need this for v1?"
- NEVER: Add features "while we're at it"
- NEVER: Design for hypothetical future requirements

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

## Red Flags - STOP

If you catch yourself:
- Starting to write code before design is validated
- Presenting entire design at once
- Asking multiple questions in one message
- Not offering alternative approaches
- Adding features "just in case"

**STOP. Return to the appropriate phase.**

## Integration

| Skill | Relationship |
|-------|--------------|
| `implementation-planning` | Creates detailed plan from design |
| `tdd-workflow` | Implementation follows TDD |
| `research-first` | Research informs design decisions |
