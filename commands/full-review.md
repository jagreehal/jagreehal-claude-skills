---
argument-hint: [--report] [--scope <path>]
description: Comprehensive codebase review against all jag-reehal-real-claude-skills patterns. Uses pattern-checker agent with chunking for large codebases.
---

# Full Codebase Review

Review the entire codebase against all jag-reehal-real-claude-skills patterns using the pattern-checker agent. Handles large codebases by chunking files.

## Arguments

- `--report`: Save findings to `docs/reviews/YYYY-MM-DD-full-review.md`
- `--scope <path>`: Limit to specific path (default: entire codebase)

Parse these from `$ARGUMENTS`.

## Procedure

### Step 1: Parse Arguments

Extract from `$ARGUMENTS`:
- `generate_report`: true if `--report` present
- `scope_path`: value after `--scope` or default to project root

### Step 2: Discover Files

Use Glob to find all TypeScript files:

```
Pattern: **/*.{ts,tsx}
```

**Categorize files:**
- Test files: `*.spec.ts`, `*.spec.tsx`, `*.test.ts`, `*.test.tsx`, `*.test.int.ts`
- Production files: all other `.ts`/`.tsx` files

**Exclude:**
- `node_modules/`, `dist/`, `build/` (Glob respects `.gitignore`)
- Generated files, type definitions only

Report:
```
Found X files to review:
- Production files: Y
- Test files: Z
```

### Step 3: Chunk Files

Split file list into chunks of ~30 files each for efficient processing.

**Chunking logic:**
- If total files <= 30: single chunk
- Otherwise: split evenly into chunks of ~30 files

Report: "Split into X chunks of ~Y files each"

### Step 4: Review Each Chunk

For each chunk, use the `pattern-checker` agent:

```
Use Task tool with:
- subagent_type: "pattern-checker"
- prompt: "Review these files for pattern violations: [file1, file2, ...]"
```

The pattern-checker will check:
1. fn(args, deps) pattern violations
2. Validation at boundary violations
3. Result types (never throw) violations
4. Observability violations
5. Resilience violations
6. Config management violations
7. TypeScript config violations
8. ESLint config violations
9. Testing violations
10. Performance testing violations

Collect ALL findings from each chunk.

### Step 5: Aggregate Results

Combine findings from all chunks into categories:

1. **fn(args, deps) Violations**
   - Functions with 3+ parameters
   - Infra imports in domain
   - Classes for business logic
   - Missing deps types

2. **Validation Boundary Violations**
   - Validation inside business functions
   - Missing Zod schemas at boundaries
   - Inconsistent error responses

3. **Result Types Violations**
   - Functions that throw
   - Missing error handling
   - Non-exhaustive error switches

4. **Observability Violations**
   - String interpolation in logs
   - Missing trace() wrappers
   - Non-semantic attribute names

5. **Resilience Violations**
   - Retry logic inside functions
   - Missing timeouts
   - No jitter on retries

6. **Config Management Violations**
   - Reading process.env during requests
   - Secrets in environment variables
   - Missing startup validation

7. **TypeScript Config Violations**
   - Missing strict flags
   - No ts-reset
   - Missing erasableSyntaxOnly

8. **ESLint Config Violations**
   - Missing no-restricted-imports
   - prefer-object-params not enabled
   - Rules set to 'warn' instead of 'error'

9. **Testing Violations**
   - vi.mock() usage
   - Weak assertions
   - Missing database guardrails
   - No Result type assertions

10. **Performance Testing Violations**
    - Missing k6 scripts
    - No load test profiles
    - Missing thresholds

Deduplicate similar findings. Sort by severity (Critical > High > Medium > Low).

### Step 6: Display Summary

Always display a summary:

```
## Full Codebase Review Complete

**Files reviewed:**
- Production files: X
- Test files: Y
- Total: Z

**Chunks processed:** N
**Total violations found:** V

### By Category:
- fn(args, deps): N violations
- Validation Boundary: N violations
- Result Types: N violations
- Observability: N violations
- Resilience: N violations
- Config Management: N violations
- TypeScript Config: N violations
- ESLint Config: N violations
- Testing: N violations
- Performance Testing: N violations

### Compliance Score: X%

### Top Issues:
1. [Most critical finding with file:line]
2. [Second most critical]
3. [Third most critical]
```

### Step 7: Generate Report (if --report)

If `generate_report` is true:

1. Create directory: `docs/reviews/` (if doesn't exist)
2. Write report to: `docs/reviews/YYYY-MM-DD-full-review.md`

**Report format:**

```markdown
# Full Codebase Review - YYYY-MM-DD

## Summary

- **Production files reviewed:** X
- **Test files reviewed:** Y
- **Total files reviewed:** Z
- **Chunks processed:** N
- **Total violations:** V
- **Compliance score:** X%

## fn(args, deps) Violations

[For each violation:]
- **File:** `path/to/file.ts:line`
- **Issue:** Description
- **Fix:** Specific change needed
- **Priority:** Critical/High/Medium/Low

## Validation Boundary Violations

[Same format...]

## Result Types Violations

[Same format...]

## Observability Violations

[Same format...]

## Resilience Violations

[Same format...]

## Config Management Violations

[Same format...]

## TypeScript Config Violations

[Same format...]

## ESLint Config Violations

[Same format...]

## Testing Violations

[Same format...]

## Performance Testing Violations

[Same format...]

## Recommended Action Plan

### Critical (Fix Immediately)
1. [Critical finding 1]
2. [Critical finding 2]

### High Priority
1. [High priority finding 1]
2. [High priority finding 2]

### Medium Priority
1. [Medium finding 1]

---

## Appendix: Files Reviewed

### Production Files (X)

<details>
<summary>Click to expand full list</summary>

- path/to/file1.ts
- path/to/file2.ts
...
</details>

### Test Files (Y)

<details>
<summary>Click to expand full list</summary>

- path/to/file1.test.ts
- path/to/file2.spec.ts
...
</details>

---

*Generated by full-review command*
```

Report: "Report saved to docs/reviews/YYYY-MM-DD-full-review.md"

## Error Handling

- If no files found: Report "No TypeScript files found" and exit
- If chunk review fails: Log error, continue with remaining chunks
- If pattern-checker agent unavailable: Fall back to direct grep/read analysis

## Notes

- This reuses the existing `pattern-checker` agent
- Large codebases may take significant time - consider using `--scope` to limit
- The review checks all 10 pattern categories comprehensively
- Results are deduplicated and sorted by severity

## Integration with verify-patterns

This command is a comprehensive version of `/verify-patterns`:
- `/verify-patterns` - Quick check, shows summary
- `/full-review` - Deep analysis, generates detailed report, handles large codebases



