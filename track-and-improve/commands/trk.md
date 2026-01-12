---
argument-hint: <description>
description: Capture mistake or improvement with 5 whys analysis
---

Capture a mistake or improvement opportunity. Follow these steps:

1. Extract the description from the user's `/trk` command

2. Identify which category this falls into:
   - `pattern-violation` - Violated fn-args-deps, result-types, validation-boundary, etc.
   - `convention-violation` - Violated CLAUDE.md or project conventions
   - `quality-issue` - Code quality problem
   - `process-issue` - Workflow/process problem
   - `improvement` - Opportunity, not a mistake

3. Identify related skills from our patterns:
   - fn-args-deps
   - result-types
   - validation-boundary
   - observability
   - resilience
   - config-management
   - testing-strategy
   - tdd-workflow
   - strict-typescript
   - pattern-enforcement

4. Perform 5 whys root cause analysis:
   - Each "why" should dig deeper
   - Fifth why should reach the systemic/root cause
   - Focus on what could prevent recurrence

5. Extract last 5 message exchanges from conversation for context

6. Generate suggested actions:
   - Concrete, actionable items
   - May include: update CLAUDE.md, add hook, modify skill, add lint rule

7. Create report in `~/.claude/trk-db/active/` with format:

```markdown
---
id: YYYY-MM-DD-HH-MM-SS
created: ISO8601 timestamp
project: current project name
status: active
category: [category]
related_skills: [skill1, skill2]
---

# [User's description]

## 5 Whys Analysis

1. **Why did this happen?** [Analysis]
2. **Why did that happen?** [Analysis]
3. **Why did that happen?** [Analysis]
4. **Why did that happen?** [Analysis]
5. **Root cause:** [Systemic root cause]

## Context (Last 5 Messages)

[Extracted conversation]

## Suggested Actions

- [ ] [Action 1]
- [ ] [Action 2]
- [ ] [Action 3]

## Resolution

[Empty - filled when resolved]
```

8. Initialize git repo if `~/.claude/trk-db/.git` doesn't exist:
   ```bash
   cd ~/.claude/trk-db && git init
   ```

9. Git add and commit:
   ```bash
   cd ~/.claude/trk-db && git add . && git commit -m "Add report: [description]"
   ```

10. Confirm to user:
    ```
    Report captured: ~/.claude/trk-db/active/[id].md

    Category: [category]
    Related skills: [skills]
    Root cause: [root cause summary]

    Run /trk-review to see patterns.
    ```
