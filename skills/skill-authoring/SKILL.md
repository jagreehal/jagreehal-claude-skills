---
name: skill-authoring
description: "Use when creating, editing, or reviewing skills. Covers discovery optimization, structure patterns, testing approaches, and format decisions."
version: 1.0.0
---

# Skill Authoring Guide

How to write skills that Claude can discover, understand, and apply effectively.

## Core Principles

### 1. Context is a Shared Resource

- MUST: Challenge every token—"Does Claude need this?"
- MUST: Keep SKILL.md body under 500 lines
- NEVER: Explain what Claude already knows (PDFs, libraries, common patterns)
- SHOULD: Move heavy reference (100+ lines) to separate files

### 2. Description Enables Discovery

- MUST: Write in third person (injected into system prompt)
- MUST: Include both WHAT it does and WHEN to use it
- MUST: Include specific triggers/symptoms/contexts
- NEVER: Summarize the workflow in description (Claude may follow description instead of reading skill)
- SHOULD: Start with action verb or "Use when..."

```yaml
# WRONG: Summarizes workflow - Claude may skip reading the skill
description: Code review with two passes - first for spec compliance, then for quality

# WRONG: Too vague
description: Helps with testing

# CORRECT: Triggers only, no workflow
description: Use when executing implementation plans with independent tasks

# CORRECT: Specific with triggers
description: Extract text and tables from PDF files. Use when working with PDFs, forms, or document extraction.
```

### 3. Match Freedom to Fragility

| Freedom Level | When to Use | Example |
|---------------|-------------|---------|
| **High** (heuristics) | Multiple valid approaches | Code review guidelines |
| **Medium** (templates) | Preferred pattern exists | Report generation |
| **Low** (exact scripts) | Fragile, error-prone | Database migrations |

---

## Skill Types & Formats

### Reference Skills (CLI tools, APIs)

Best format: **Command reference + Best practices**

```markdown
## Quick Start
[5-line example showing core workflow]

## Command Reference
[Organized by category with examples]

## Best Practices
[MUST/SHOULD/NEVER rules]

## Examples
[Real workflows]
```

Example: `agent-browser`, `git` commands

### Technique Skills (how-to)

Best format: **Pattern + Examples + Common mistakes**

```markdown
## Overview
[Core principle in 1-2 sentences]

## When to Use
[Symptoms and triggers]

## Core Pattern
[Before/after comparison]

## Implementation
[Steps or code]

## Common Mistakes
[What goes wrong + fixes]
```

Example: `condition-based-waiting`, `root-cause-tracing`

### Discipline Skills (rules/requirements)

Best format: **Iron Law + Phases + Rationalization prevention**

```markdown
## The Iron Law
[One rule that cannot be violated]

## Phases/Process
[Clear steps with gates]

## Red Flags - STOP
[Signs you're about to violate]

## Rationalization Prevention
[Table: Excuse | Reality]
```

Example: `systematic-debugging`, `verification-before-completion`, `tdd-workflow`

### Pattern Skills (mental models)

Best format: **Concept + Recognition + Application**

```markdown
## Overview
[What is this pattern?]

## When to Recognize
[Symptoms indicating pattern applies]

## How to Apply
[Steps or guidelines]

## When NOT to Apply
[Counter-examples]
```

---

## The MUST/SHOULD/NEVER Format

### When to Use

- Reference documentation (commands, APIs)
- Best practices and guidelines
- Checklists and quality gates
- Any skill where quick scanning matters

### Structure

```markdown
## Section Name

- MUST: Non-negotiable requirements
- SHOULD: Strong recommendations with valid exceptions
- NEVER: Absolute prohibitions
- MAY: Optional enhancements
```

### Writing Effective Rules

```markdown
# WRONG: Vague
- MUST: Handle errors properly

# WRONG: Too long
- MUST: When an error occurs, you should catch it and then log it with the full stack trace and context

# CORRECT: Specific and scannable
- MUST: Catch errors at boundaries; log with stack trace
- NEVER: Swallow errors silently
```

### Combine with Context

```markdown
## Forms

- MUST: Use `fill` (clears first) for inputs, not `type`
- MUST: `autocomplete` + meaningful `name`; correct `type` and `inputmode`
- SHOULD: Placeholders end with `…` and show example pattern
- NEVER: Block paste in `<input>`/`<textarea>`
```

---

## Discipline Skills: Rationalization Prevention

For skills that enforce rules (TDD, verification, debugging), Claude will rationalize under pressure.

### The Iron Law Pattern

State one unbreakable rule:

```markdown
## The Iron Law

NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST

If you haven't completed Phase 1, you cannot propose fixes.
```

### Red Flags List

Make it easy to self-check:

```markdown
## Red Flags - STOP

If you catch yourself thinking:
- "Quick fix for now, investigate later"
- "Just try changing X and see"
- "I don't fully understand but this might work"

ALL of these mean: STOP. Return to Phase 1.
```

### Rationalization Table

Capture excuses with counters:

```markdown
| Excuse | Reality |
|--------|---------|
| "Too simple to need process" | Simple issues have root causes too |
| "Emergency, no time" | Systematic is faster than thrashing |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
```

### Close Loopholes Explicitly

```markdown
# WRONG: Just states rule
Write code before test? Delete it.

# CORRECT: Closes loopholes
Write code before test? Delete it. Start over.

**No exceptions:**
- Don't keep it as "reference"
- Don't "adapt" it while writing tests
- Delete means delete
```

---

## Progressive Disclosure

### SKILL.md as Table of Contents

```markdown
# PDF Processing

## Quick start
[Inline example]

## Core operations
[Inline patterns]

## Advanced features
**Form filling**: See [FORMS.md](FORMS.md)
**API reference**: See [REFERENCE.md](REFERENCE.md)
```

Claude loads referenced files only when needed.

### When to Split Files

| Content Type | Where |
|--------------|-------|
| Patterns, concepts, quick ref | Inline in SKILL.md |
| Heavy reference (100+ lines) | Separate file |
| Reusable scripts | Separate file |
| Domain-specific schemas | Separate files by domain |

### Keep References One Level Deep

```markdown
# WRONG: Nested references
SKILL.md → advanced.md → details.md → actual info

# CORRECT: Flat references
SKILL.md → advanced.md (complete info)
SKILL.md → reference.md (complete info)
```

---

## Testing Skills

### Test Before Deploying

- MUST: Test skill with real scenarios before deploying
- MUST: Test with the model(s) you'll use (Haiku needs more guidance than Opus)
- SHOULD: Create 3+ evaluation scenarios
- NEVER: Deploy untested skills

### For Discipline Skills: Pressure Testing

1. Run scenario WITHOUT skill—document baseline behavior
2. Note rationalizations Claude uses
3. Write skill addressing those specific violations
4. Run scenario WITH skill—verify compliance
5. Find new rationalizations → add counters → re-test

### Evaluation Structure

```json
{
  "skills": ["pdf-processing"],
  "query": "Extract all text from this PDF file",
  "files": ["test-files/document.pdf"],
  "expected_behavior": [
    "Uses appropriate PDF library",
    "Extracts from all pages",
    "Saves to output file"
  ]
}
```

---

## YAML Frontmatter

### Required Fields

```yaml
---
name: skill-name-with-hyphens
description: "Third-person description with triggers. Use when [specific conditions]."
version: 1.0.0
---
```

### Constraints

| Field | Constraint |
|-------|------------|
| `name` | Max 64 chars, lowercase, letters/numbers/hyphens only |
| `description` | Max 1024 chars, non-empty, no XML tags |
| Reserved words | Cannot use "anthropic", "claude" in name |

### Optional Fields

```yaml
libraries: ["react", "zod"]  # If skill requires specific libraries
```

---

## Common Patterns

### Template Pattern

```markdown
## Report Structure

Use this template:

# [Title]

## Summary
[One paragraph]

## Findings
- Finding 1
- Finding 2

## Recommendations
1. Action 1
2. Action 2
```

### Examples Pattern

```markdown
## Commit Messages

**Example 1:**
Input: Added user authentication
Output: `feat(auth): implement JWT authentication`

**Example 2:**
Input: Fixed date display bug
Output: `fix(reports): correct timezone in date formatting`
```

### Conditional Workflow

```markdown
## Workflow

1. Determine type:
   **Creating new?** → Follow Creation workflow
   **Editing existing?** → Follow Editing workflow

2. Creation workflow:
   - Step A
   - Step B

3. Editing workflow:
   - Step X
   - Step Y
```

---

## Anti-Patterns

### Content Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Explaining basics | Wastes tokens | Assume Claude knows |
| Time-sensitive info | Becomes stale | Use "old patterns" section |
| Inconsistent terminology | Confuses | Pick one term, use throughout |
| Multiple languages | Dilutes quality | One excellent example |
| Narrative stories | Not reusable | Extract pattern |

### Structure Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Nested references | Partial reads | Keep one level deep |
| Vague descriptions | Poor discovery | Specific triggers |
| Workflow in description | Claude skips skill | Triggers only |
| No table of contents | Hard to navigate | Add for 100+ lines |
| Windows paths | Cross-platform issues | Use forward slashes |

---

## Checklist

### Before Publishing

**Frontmatter:**
- [ ] Name: lowercase, hyphens, no reserved words
- [ ] Description: third-person, triggers, no workflow summary
- [ ] Version: semantic versioning

**Content:**
- [ ] Under 500 lines (or progressive disclosure)
- [ ] Consistent terminology
- [ ] No time-sensitive information
- [ ] Keywords for search (errors, symptoms, tools)

**Format matches type:**
- [ ] Reference: commands + best practices
- [ ] Technique: pattern + examples + mistakes
- [ ] Discipline: iron law + red flags + rationalization table

**Testing:**
- [ ] 3+ evaluation scenarios
- [ ] Tested with target model(s)
- [ ] Discipline skills: pressure tested

---

## Integration

| Skill | Relationship |
|-------|--------------|
| `testing-strategy` | Testing approaches |
| `documentation-standards` | Writing style |
| `design-principles` | Structure decisions |
