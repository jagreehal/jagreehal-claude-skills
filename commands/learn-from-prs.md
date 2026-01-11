---
argument-hint: "[--count <n>] [--state merged|closed|all]"
description: Analyze PR feedback patterns and suggest config updates to catch issues locally
---

# Learn From PR Feedback

Analyze feedback from recent PRs (CodeRabbit, SonarQube, developer comments) and suggest updates to project configuration to catch these issues before PR review. Maps findings to jag-skills patterns where applicable.

## Arguments

```
ARGUMENTS: $ARGUMENTS
```

- `--count <n>`: Number of PRs to analyze (default: 5)
- `--state <state>`: PR state to fetch - merged, closed, or all (default: merged)

## Procedure

### Step 1: Verify Prerequisites

Check that `gh` CLI is authenticated:

```bash
gh auth status
```

If not authenticated, stop and inform user to run `gh auth login`.

### Step 2: Fetch Recent PRs

```bash
gh pr list --state <state> --limit <count> --json number,title,url,mergedAt,closedAt
```

If no PRs found, report "No PRs found matching criteria" and stop.

Report:
```
Found X PRs to analyze:
1. #123: PR title
2. #124: PR title
...
```

### Step 3: Collect All Feedback

For each PR, fetch ALL comments and reviews:

**PR review comments (inline code comments):**
```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments --paginate
```

**PR reviews (approval/request changes with body):**
```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/reviews --paginate
```

**Issue-style comments (general discussion):**
```bash
gh api repos/{owner}/{repo}/issues/{pr_number}/comments --paginate
```

Extract from each comment:
- `body`: The actual feedback text
- `user.login`: Who wrote it (helps identify bots like CodeRabbit, SonarQube)
- `path` and `line`: Where in code (if applicable)
- `created_at`: When

**Categorize by source:**
- **Automated tools**: Identify by user.login or body markers (CodeRabbit, SonarQube, Codacy, DeepSource, etc.)
- **Human reviewers**: Everything else

Report:
```
Collected feedback from PR #X:
- [Tool name]: Y comments
- Human reviewers: Z comments
```

### Step 4: Analyze Patterns

Group all collected feedback and identify patterns.

**Look for recurring themes and map to jag-skills patterns:**

| Feedback Theme | Related jag-skills Pattern |
|----------------|---------------------------|
| Too many function parameters | `fn-args-deps` - use args/deps signature |
| Missing error handling | `result-types` - use Result<T, E> not throw |
| Validation in wrong place | `validation-boundary` - validate at entry only |
| Console.log statements | `observability` - use structured logging |
| Hardcoded config values | `config-management` - validate at startup |
| Missing types / `any` usage | `strict-typescript` - stricter tsconfig |
| Retry logic in functions | `resilience` - retry at workflow level |
| Weak test assertions | `testing-strategy` - use typed mocks |

For each pattern found:
- Count occurrences across all PRs
- Note specific examples (file, line, comment text)
- Identify the source (which tool/reviewer caught it)
- Map to jag-skills pattern if applicable

**Prioritize by:**
1. Frequency (appears in multiple PRs)
2. Source consistency (caught by multiple reviewers/tools)
3. Severity (security > bugs > style)

Report top patterns:
```
## Feedback Patterns Found

### High Frequency (appeared in 3+ PRs)
1. [Pattern]: [X occurrences] - caught by [sources]
   Example: "[actual comment snippet]"
   Maps to: [jag-skills pattern name] or "No direct mapping"

### Medium Frequency (appeared in 2 PRs)
...

### Single Occurrence (but notable)
...
```

### Step 5: Discover Current Config

Search the project for configuration files:

```bash
find . -maxdepth 3 -type f \( \
  -name "CLAUDE.md" -o \
  -name ".claude" -o \
  -name ".*rc" -o \
  -name ".*rc.json" -o \
  -name "*.config.js" -o \
  -name "*.config.ts" -o \
  -name "tsconfig.json" -o \
  -name "eslint.config.*" -o \
  -name ".pre-commit-config.yaml" \
\) 2>/dev/null | head -30
```

Also check for `.claude/` directory contents.

For each relevant config, note:
- What it currently enforces
- What gaps exist relative to PR feedback patterns

Report:
```
## Current Configuration

Found these config files:
- [file]: [brief summary of what it controls]
...
```

### Step 6: Generate Recommendations

For each high-frequency pattern, propose specific config updates:

**Format for each recommendation:**

```markdown
### [Pattern Name]

**Problem:** [What the PR feedback consistently caught]

**Frequency:** [X occurrences across Y PRs]

**Caught by:** [Tool names, specific reviewers]

**Related jag-skills pattern:** [pattern name or "None"]

**Examples from PRs:**
- PR #123: "[comment snippet]"
- PR #456: "[comment snippet]"

**Suggested fixes:**

**Option A: CLAUDE.md** (catches during Claude Code sessions)
```markdown
## [Pattern Rule]

[Rule description referencing jag-skills pattern if applicable]

Example:
- WRONG: [anti-pattern code]
- CORRECT: [correct pattern code]
```

**Option B: [Relevant tool/config for this project]**
```
[Exact config to add, appropriate to the project's language/tooling]
```

**Recommended:** [Which option and why]
```

**Pattern-specific recommendations:**

For **fn-args-deps violations** (too many parameters):
```markdown
## Function Signatures

Use fn(args, deps) pattern:
- args: Request-specific data (userId, filters)
- deps: Long-lived dependencies (db, logger, cache)

WRONG: function getUser(userId, db, logger, cache)
CORRECT: function getUser(args: { userId }, deps: { db, logger, cache })
```

For **result-types violations** (throwing errors):
```markdown
## Error Handling

Never throw for expected errors. Return Result<T, E>:

WRONG: throw new Error('User not found')
CORRECT: return err('NOT_FOUND')
```

For **validation-boundary violations**:
```markdown
## Validation

Validate at HTTP/queue boundaries with Zod. Business functions trust validated input.

WRONG: function getUser(id) { if (!isUuid(id)) throw ... }
CORRECT: Parse with Zod at handler, pass validated type to function
```

### Step 7: Present Summary

```markdown
# PR Feedback Analysis Complete

## PRs Analyzed
- Count: X
- Date range: [oldest] to [newest]
- Feedback sources: [list tools and reviewer count]

## Key Findings

### Patterns That Should Be Caught Locally

| Pattern | Frequency | Top Source | jag-skills Pattern | Recommended Fix |
|---------|-----------|------------|-------------------|-----------------|
| [name]  | X times   | [source]   | [pattern/None]    | [config type] |

## Detailed Recommendations

[Full recommendations from Step 6]

## Quick Wins (Copy-Paste Ready)

### Add to CLAUDE.md:
```markdown
[All CLAUDE.md additions consolidated]
```

### Add to [other relevant config]:
```
[Additions consolidated by config file]
```

---
*Analysis based on PRs: #X, #Y, #Z...*
*Run `/learn-from-prs` again after implementing changes to verify improvement*
```

## Notes

- This command only suggests changes, never modifies files
- Focus recommendations on issues that appeared multiple times
- For single-occurrence issues, mention them but deprioritize
- Recommend fixes appropriate to the project's actual language and tooling
- When a pattern could be caught by multiple tools, recommend the earliest in the pipeline
- Map feedback to jag-skills patterns when applicable to provide actionable fixes
- If feedback is vague or unclear, note it but don't force a recommendation
