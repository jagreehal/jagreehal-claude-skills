---
description: Review captured reports and identify patterns
---

Review all active reports and identify patterns. Follow these steps:

1. List all files in `~/.claude/trk-db/active/`

2. Read each report file and extract:
   - ID (timestamp)
   - Category
   - Related skills
   - Root cause
   - Whether suggested actions were taken

3. Group reports by category:
   ```
   ## Pattern Violations (X reports)
   - [id]: [description] - skills: [skills]

   ## Convention Violations (X reports)
   - [id]: [description]

   ## Quality Issues (X reports)
   - [id]: [description]

   ## Process Issues (X reports)
   - [id]: [description]

   ## Improvements (X reports)
   - [id]: [description]
   ```

4. Identify patterns across reports:
   - Which skills are violated most frequently?
   - Which categories have most reports?
   - Are there common root causes?

5. Generate recommendations:
   - If same skill violated multiple times: "Consider adding lint rule or hook"
   - If convention violated multiple times: "Update CLAUDE.md with explicit rule"
   - If process issue repeats: "Consider workflow change"

6. Present summary:

```
## TRK Report Summary

Active reports: X
Resolved reports: Y

### By Category
- Pattern violations: X
- Convention violations: X
- Quality issues: X
- Process issues: X
- Improvements: X

### Most Affected Skills
1. [skill] - X violations
2. [skill] - X violations
3. [skill] - X violations

### Common Root Causes
1. [root cause pattern] - X reports
2. [root cause pattern] - X reports

### Recommendations
1. [Recommendation based on patterns]
2. [Recommendation based on patterns]

### Ready to Resolve
Reports with completed suggested actions:
- [id]: [description]

Run /trk-resolve <id> <resolution> to mark resolved.
```

7. If no active reports:
   ```
   No active reports.

   All previous issues have been resolved!
   ```
