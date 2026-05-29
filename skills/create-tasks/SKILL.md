---
name: create-tasks
description: Creates well-formed, self-contained tasks from a template that any engineer can implement without prior context or follow-up questions. Use when creating tasks, defining work items, breaking down a feature or PRD, or converting requirements into actionable, vertically-sliced work.
version: 1.1.0
---

# Create Tasks

## Overview

Create tasks that carry enough context for an engineer who was in none of the conversations to implement them without asking questions. A good task states what to build, why it matters, the decisions to honor, how to verify it, and what it depends on. The core principle: a task is a vertical slice sized for one day, never a PRD deliverable copied verbatim, which is usually an epic in disguise.

Tasks should follow the tools and documentation conventions of the project they're applied to. If the conventions aren't clear, ask the user to clarify, then document them.

## When to Use

- Turning a PRD, spec, or conversation into implementable work items
- Breaking a feature into independently shippable pieces
- Converting requirements into tasks an AFK agent or engineer can pick up cold

**When NOT to use:** A single-file change with obvious scope, or when the source already contains well-defined, day-sized tasks.

**Related:** [implementation-planning](../implementation-planning/SKILL.md) (sequences and checkpoints the tasks this skill produces), [session-continuity](../session-continuity/SKILL.md) (tracks task execution across sessions), [tdd-workflow](../tdd-workflow/SKILL.md) (acceptance criteria become test specs), [testing-strategy](../testing-strategy/SKILL.md) (verifies each task's criteria).

## What Engineers Need

Every task must provide:

- What they're building (deliverable)
- Why it matters (context)
- Key decisions and principles they must follow
- Acceptance criteria
- Dependencies
- Related code/patterns
- How to verify it works

## Before Creating Tasks: Slice First

🚨 **NEVER create a task without validating its size first.** A PRD deliverable is NOT automatically a task; it may be an epic that needs splitting.

### Example Mapping Discovery

🚨 **Never copy PRD bullets verbatim.** Use Example Mapping to transform them into executable specifications.

| Card | What You Do |
|------|-------------|
| 🟡 **Story** | State the deliverable in one specific sentence |
| 🔵 **Rules** | List every business rule/constraint (3-4 max per task) |
| 🟢 **Examples** | For EACH rule: happy path + edge cases + error cases |
| 🔴 **Questions** | Surface unknowns → resolve or spike first |

**The Examples (🟢) ARE your acceptance criteria.** Write them in Given-When-Then format:

```
Given [context/precondition]
When [action/trigger]
Then [expected outcome]
```

**Edge case checklist**, for each rule, consider:

| Category | Check For |
|----------|-----------|
| **Input** | Empty, null, whitespace, boundaries, invalid format, special chars, unicode, too long |
| **State** | Concurrent updates, race conditions, invalid sequences, already exists, doesn't exist |
| **Errors** | Network failure, timeout, partial failure, invalid permissions, quota exceeded |

**Example:** PRD says "User can search products"

Rules identified: (1) Search by title, (2) Pagination, (3) Empty state

For Rule 1 alone, edge case thinking yields:

- Given products exist → When search → Then results (happy path)
- Given no matches → When search → Then empty set
- Given empty search term → When submit → Then validation error OR all products? (🔴 Question!)
- Given special chars in search → When search → Then handled safely

### Splitting Signals (Task Too Big)

If ANY of these are true, **STOP and split**:

- ❌ Can't describe in a specific, action-oriented title
- ❌ Would take more than 1 day
- ❌ Title requires "and" or lists multiple things
- ❌ Has multiple clusters of acceptance criteria
- ❌ Cuts horizontally (all DB, then all API, then all UI)
- ❌ PRD calls it "full implementation" or "complete system"

### SPIDR Splitting Techniques

When you need to split, use these techniques:

| Technique | Split By | Example |
|-----------|----------|---------|
| **S**pikes | Unknown areas | "Research payment APIs" before "Implement payments" |
| **P**aths | Different user flows | "Pay with card" vs "Pay with PayPal" |
| **I**nterfaces | Different UIs/platforms | "Desktop search" vs "Mobile search" |
| **D**ata | Different data types | "Upload images" vs "Upload videos" |
| **R**ules | Different business rules | "Basic validation" vs "Premium validation" |

### Vertical Slices Only

Every task must be a **vertical slice**, cutting through all layers needed for ONE specific thing:

```
✅ VERTICAL (correct):
"Add search by title" → touches UI + API + DB for ONE search type

❌ HORIZONTAL (wrong):
"Build search UI" → "Build search API" → "Build search DB"
```

## Task Naming

### Formula

`[Action verb] [specific object] [outcome/constraint]`

### Good Names

- "Add price range filter to product search"
- "Implement POST /api/users endpoint with email validation"
- "Display product recommendations on home page"
- "Enable CSV export for transaction history"
- "Validate required fields on checkout form"

### Rejected Patterns

🚨 **NEVER use these; they signal an epic, not a task:**

| Pattern | Why It's Wrong |
|---------|----------------|
| "Full implementation of X" | Epic masquerading as task |
| "Build the X system" | Too vague, no specific deliverable |
| "Complete X feature" | Undefined scope |
| "Implement X" (alone) | Missing specificity |
| "X and Y" | Two tasks combined |
| "Set up X infrastructure" | Horizontal slice |

If you catch yourself writing one of these, **STOP and apply SPIDR**.

## Task Size Validation (INVEST)

Every task MUST pass INVEST before creation:

| Criterion | Question | Fail = Split |
|-----------|----------|--------------|
| **I**ndependent | Does it deliver value alone? | Depends on other incomplete tasks |
| **N**egotiable | Can scope be discussed? | Rigid, all-or-nothing |
| **V**aluable | Does user/stakeholder see benefit? | Only technical benefit |
| **E**stimable | Can you size it confidently? | "Uh... maybe 3 days?" |
| **S**mall | Fits in 1 day? | More than 1 day |
| **T**estable | Has concrete acceptance criteria? | Vague or missing criteria |

### Hard Limits

- **Max 1 day of work:** if longer, split it
- **Must be vertical:** touches all layers for ONE thing
- **Must be demoable:** when done, you can show it working

## Task Template

```markdown
## Deliverable: [What user/stakeholder sees]

### Context
[Where this came from and why it matters. PRD reference, bug report, conversation
summary — whatever helps the engineer understand WHY. You MUST provide the specific
file path or URL for any referenced file like a PRD or bug report — don't assume the
engineer knows where things are stored.]

### Key Decisions and Principles
- [Decision/Principle] — [rationale]

### Delivers
[Specific outcome in user terms]

### Acceptance Criteria
- Given [context] When [action] Then [outcome]

### Dependencies
- [What must exist first]

### Related Code
- `path/to/file` — [what pattern/code to use]

### Verification
[Specific commands/tests that prove it works]
```

## Process

1. **Slice first:** Apply Example Mapping. If a task has >3-4 rules or hits a splitting signal, use SPIDR to break it down.
2. **Discover acceptance criteria:** For each rule, generate happy path, edge cases, and error cases using the checklist. Write as Given-When-Then. Surface questions.
3. **Name it:** Write a specific, action-oriented title. If you can't, the task isn't clear enough.
4. **Validate size:** Must pass INVEST. Max 1 day. Must be a vertical slice.
5. **Gather context** from PRD, conversation, bug report, etc.
6. **Identify key decisions** that affect implementation.
7. **Find related code/patterns** in the codebase.
8. **Specify verification commands.**
9. **Output the task** using the template.

## Checkpoint

Before finalizing any task, verify ALL of these:

| Check | Question | If No |
|-------|----------|-------|
| **Size** | Is this ≤1 day of work? | Split using SPIDR |
| **Name** | Is the title specific and action-oriented? | Rewrite using the formula |
| **Vertical** | Does it cut through all layers for ONE thing? | Restructure as a vertical slice |
| **INVEST** | Does it pass all 6 criteria? | Fix the failing criterion |
| **Context** | Can an engineer implement without asking questions? | Add what's missing |

🚨 **If the PRD says "full implementation" or similar, you MUST split it. Creating such a task is a critical failure.**

## Red Flags

- Copying PRD bullets verbatim as tasks
- A task title containing "and" or listing multiple deliverables
- Horizontal slices ("build the API", "build the UI")
- Acceptance criteria that are vague or missing Given-When-Then structure
- Referenced PRDs or bug reports with no file path or URL
- A task that fails any INVEST criterion left unsplit
- Estimating a task at more than one day and creating it anyway

## Integration with Task Workflows

This skill creates task **definitions**. For managing execution across sessions, consider:

- Creating tasks in `.claude/tasks.md` for session continuity
- Using `requirements.md` for implementation specs
- Using `session.md` for progress tracking

Tasks created with this skill can be integrated into any task management system (GitHub Issues, Jira, Linear, or file-based workflows).
