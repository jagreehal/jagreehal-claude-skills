# Track and Improve

Capture mistakes and improvement opportunities with 5 whys root cause analysis. Learn from patterns to prevent future issues.

## Purpose

When you notice Claude made a mistake or there's an improvement opportunity:
1. Capture it with `/trk <description>`
2. Claude performs 5 whys analysis
3. Report saved to `~/.claude/trk-db/`
4. Review patterns periodically with `/trk-review`
5. Resolve and learn with `/trk-resolve`

## Commands

### `/trk <description>`
Capture a mistake or improvement opportunity.

```
/trk Added inline comment when CLAUDE.md forbids them
/trk Used vi.mock() instead of vitest-mock-extended
/trk Threw error instead of returning Result type
```

Claude will:
1. Perform 5 whys root cause analysis
2. Link to relevant skills/patterns
3. Save report with conversation context
4. Commit to git

### `/trk-review`
Review captured reports and identify patterns.

```
/trk-review
```

Shows:
- Recent active reports
- Pattern categories
- Suggested improvements

### `/trk-resolve <timestamp> <resolution>`
Mark a report as resolved with what was done.

```
/trk-resolve 2025-01-15-10-30-00 "Added PreToolUse hook to block comments"
```

## Storage

Reports stored in `~/.claude/trk-db/` with git version control:

```
~/.claude/trk-db/
├── .git/
├── active/          # Unresolved reports
│   └── 2025-01-15-10-30-00.md
└── resolved/        # Completed improvements
    └── 2025-01-14-09-15-00.md
```

## Report Format

```markdown
---
id: 2025-01-15-10-30-00
created: 2025-01-15T10:30:00Z
project: my-project
status: active
category: pattern-violation
related_skills: [fn-args-deps, result-types]
---

# Added throw statement instead of Result type

## 5 Whys Analysis

1. **Why did this happen?**
   Implemented error handling with throw/catch pattern.

2. **Why did that happen?**
   Defaulted to familiar pattern instead of checking project conventions.

3. **Why did that happen?**
   Didn't read result-types skill before implementing error handling.

4. **Why did that happen?**
   Rushed to implementation without checking skill requirements.

5. **Root cause:**
   Missing pattern-check step before implementation.

## Context (Last 5 Messages)

[Extracted conversation showing the mistake]

## Suggested Actions

- [ ] Add Result type to function signature
- [ ] Replace throw with err() return
- [ ] Consider adding pattern-checker agent to workflow

## Resolution

[Empty until resolved]
```

## Categories

Reports are auto-categorized:

| Category | Description |
|----------|-------------|
| `pattern-violation` | Violated a defined pattern (fn-args-deps, result-types, etc.) |
| `convention-violation` | Violated CLAUDE.md or project conventions |
| `quality-issue` | Code quality problem (naming, structure, etc.) |
| `process-issue` | Workflow or process problem |
| `improvement` | Opportunity to improve (not a mistake) |

## Integration

Works with:
- **pattern-enforcement** - Identify when enforcement failed
- **tdd-workflow** - Track TDD violations
- **critical-peer** - Reinforce learning from mistakes

## Workflow

1. **During session**: Spot mistake, run `/trk <description>`
2. **Continue working**: Don't interrupt flow
3. **Weekly**: Run `/trk-review` to analyze patterns
4. **Take action**: Update CLAUDE.md, add hooks, or modify skills
5. **Resolve**: `/trk-resolve <id> <what was done>`

## Why This Matters

Mistakes are learning opportunities. By capturing and analyzing them:
- Identify systemic issues in guidance
- Improve CLAUDE.md with specific rules
- Add hooks to prevent future violations
- Build better skills based on real failures

**Goal: Every mistake should result in improved automation or guidance.**
