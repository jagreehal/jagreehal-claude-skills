# Code Review

Code review triggered automatically when Claude finishes modifying files. Reviews against project-specific rules aligned with our TypeScript patterns.

## How It Works

1. **PostToolUse hook** logs every file modification (Write, Edit, MultiEdit)
2. **Stop hook** triggers review when Claude stops responding
3. **Agent** reads your project rules and reviews all modified files

When activated, you'll see:
```bash
code-review:code-reviewer(Review modified files)
```

## Review Agents

Two agents are available:

### 1. code-reviewer (Default)

Standard Claude agent that reviews files using Read/Grep tools.

### 2. codex-code-reviewer (Codex CLI)

Uses the `codex` CLI tool for review. Requires codex to be installed.

**To use codex-code-reviewer:**
- Install codex CLI first
- Use Task tool with `subagent_type: "codex-code-reviewer"` instead of "code-reviewer"

**Benefits of codex:**
- Can use different models (e.g., `--model gpt-4.1`)
- Structured JSON output option
- Faster for large codebases
- Can be called directly from scripts

**Example direct usage:**
```bash
./hooks/tools/codex-review.sh .claude/code-review/rules.md src/domain/get-user.ts
```

## Installation

```bash
/plugin marketplace add jagreehal/jagreehal-claude-skills
/plugin install code-review@jagreehal-claude-skills
```

## Setup

**Auto-initializes on first hook run.**

Creates/updates:
- `.claude/settings.json` - Adds `codeReview` configuration
- `.claude/code-review/rules.md` - Default rules based on our patterns

Customize `.claude/code-review/rules.md` for your project.

## Configuration

Settings in `.claude/settings.json`:
```json
{
  "codeReview": {
    "enabled": true,
    "fileExtensions": ["ts", "tsx"],
    "rulesFile": ".claude/code-review/rules.md"
  }
}
```

Set `"enabled": false` to disable for a project.

## Default Rules

Our default rules enforce:
1. **fn(args, deps) Pattern** - No global dependencies
2. **Result Types** - No throwing for expected errors
3. **Validation Boundary** - Zod at edges only
4. **Maximum Type Safety** - No `any`, no `as`
5. **Domain Naming** - No generic names
6. **No Dangerous Fallbacks** - No `??` chains hiding bugs

## Customization

Copy default rules and customize:
```bash
# Rules are auto-created at:
.claude/code-review/rules.md
```

Add project-specific rules. The agent enforces exactly what you define.

## Requirements

- `jq` - Install with `brew install jq` (macOS) or `apt-get install jq` (Linux)
- `codex` (optional) - Required only if using `codex-code-reviewer` agent

## Integration

Best used with:
- `pattern-enforcement` skill - ESLint rules that fail the build
- `testing-strategy` skill - Test coverage and quality
- `tdd-workflow` skill - Disciplined development

This agent catches semantic issues that lint can't detect.
