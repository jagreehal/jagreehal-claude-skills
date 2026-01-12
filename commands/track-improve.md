---
argument-hint: <description>
description: Capture mistake or improvement opportunity with 5 whys root cause analysis
---

# Track and Improve

Capture a mistake or improvement opportunity. Follow these steps:

1. Extract the description from the user's `/track-improve` command
2. Identify your current persona/role (what system prompt you're operating under)
3. Perform 5 whys root cause analysis of why this mistake happened
4. Extract last 5 message exchanges from the current conversation
5. Create a report in `~/.claude/trk-db/active/` with format:

```markdown
---
id: YYYY-MM-DD-HH-MM-SS
created: ISO8601 timestamp
project: current project name
persona: current persona/role
status: active
category: rule-violation|improvement|confusion
---

# [User's description]

## 5 Whys Analysis

1. **Why did this happen?** [Your analysis]
2. **Why did that happen?** [Your analysis]
3. **Why did that happen?** [Your analysis]
4. **Why did that happen?** [Your analysis]
5. **Root cause:** [Your conclusion]

## Context (Last 5 Messages)

[Extracted conversation]

## Resolution

[Empty - filled when resolved]
```

6. Initialize git repo if `~/.claude/trk-db/.git` doesn't exist
7. Git add and commit with message: "Add report: [description]"
8. Confirm to user: "Report captured: ~/.claude/trk-db/active/[id].md"

## Categories

- **rule-violation:** Violated a skill pattern or rule (e.g., used `any`, forgot Result types)
- **improvement:** Opportunity to improve process or code quality
- **confusion:** Unclear requirements, ambiguous instructions, or misunderstanding

## 5 Whys Analysis

For each "why", dig deeper into the underlying cause:

**Example:**
```
1. Why did this happen? Used `any` type instead of proper type
2. Why did that happen? Didn't know the correct type structure
3. Why did that happen? Didn't check existing type definitions
4. Why did that happen? Rushed to implement without understanding codebase
5. Root cause: Lack of code-flow-analysis before implementation
```

## Integration with Skills

- **code-flow-analysis:** If mistake was due to not understanding flow
- **strict-typescript:** If mistake was type-related
- **result-types:** If mistake was error handling related
- **answer-questions-directly:** If mistake was misinterpreting user intent

## Rules

1. Always perform 5 whys - don't stop at surface level
2. Be honest about root causes - don't blame external factors
3. Extract actual conversation context - not summaries
4. Use ISO8601 timestamps
5. Initialize git repo if needed
6. Commit immediately after creating report
