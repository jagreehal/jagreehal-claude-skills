# Project Guidelines

Guidelines for maintaining and contributing to jag-reehal-real-claude-skills.

## Version Management (MANDATORY)

When making ANY change to this repository, you MUST increment versions appropriately:

### Which Version to Bump

1. **Modifying a skill** (e.g., `skills/fn-args-deps/SKILL.md`):
   - Bump the skill's own `version` field in frontmatter
   - Consider bumping plugin version in `.claude-plugin/marketplace.json` if significant

2. **Modifying a command** (e.g., `commands/verify-patterns.md`):
   - Bump plugin version in `.claude-plugin/marketplace.json`

3. **Adding a new skill**:
   - Set new skill version to "1.0.0"
   - Bump plugin version in `.claude-plugin/marketplace.json`

4. **Adding a new command/agent**:
   - Bump plugin version in `.claude-plugin/marketplace.json`

### Version Format

- Semantic versioning: `MAJOR.MINOR.PATCH`
- **Patch** (1.0.0 → 1.0.1): Bug fixes, clarifications, minor improvements
- **Minor** (1.0.0 → 1.1.0): New patterns, significant enhancements, new examples
- **Major** (1.0.0 → 2.0.0): Breaking changes, pattern modifications

**Why:** Claude Code caches plugins by their version. Bumping versions ensures users get updates.

## Skill Structure

### Frontmatter Requirements

Every skill must have:

```yaml
---
name: skill-name
description: "Brief description of what the skill does"
version: 1.0.0
libraries: ["library1", "library2"]  # Optional, if skill requires specific libraries
---
```

### Content Structure

1. **Core Principle** - Why this pattern exists
2. **Required Behaviors** - What must be done
3. **Examples** - WRONG vs CORRECT patterns
4. **Integration** - How it works with other skills
5. **Rules** - Quick reference checklist

### Writing Guidelines

- **Be specific** - Use file:line references, concrete examples
- **Show patterns** - Always include WRONG vs CORRECT examples
- **Reference other skills** - Link related patterns
- **Keep it practical** - Focus on actionable guidance, not theory

## Command Structure

### Frontmatter

```yaml
---
argument-hint: <arg1> [optional-arg]
description: What the command does
---
```

### Content

- Clear procedure with numbered steps
- Error handling for edge cases
- Integration with agents when applicable
- Output format specifications

## Agent Structure

### Frontmatter

```yaml
---
name: agent-name
description: What the agent does
tools: Read, Glob, Grep, Bash  # List allowed tools
---
```

### Content

- Clear role definition
- Specific procedures to follow
- Output format requirements
- Error handling

## Pattern Alignment

All skills must align with the source material from `/Users/jreehal/dev/js/typescript-classes-functions/src/posts`.

When adding or modifying skills:
1. Check the corresponding post in the source directory
2. Ensure all patterns from the post are covered
3. Include code examples that match the post's style
4. Reference the post if adding new content

## Testing Skills

Before committing changes:
1. Verify examples compile (if TypeScript)
2. Check that all file:line references are accurate
3. Ensure WRONG vs CORRECT examples are clear
4. Verify integration with other skills is correct

## Documentation Standards

- Use code blocks with language tags
- Include file paths in examples: `src/domain/get-user.ts`
- Show line numbers when relevant: `src/api/handlers.ts:45`
- Use tables for comparisons
- Include diagrams for complex flows (ASCII art is fine)

## Naming Conventions

- **Skills:** kebab-case (`fn-args-deps`, `result-types`)
- **Commands:** kebab-case (`verify-patterns`, `init-project`)
- **Agents:** kebab-case (`pattern-checker`)
- **Files:** UPPERCASE for special files (`CLAUDE.md`, `README.md`)

## Integration Points

Skills should reference each other:
- `fn-args-deps` → enables `testing-strategy`
- `result-types` → used by `resilience` workflows
- `validation-boundary` → feeds into `result-types`
- `observability` → wraps `fn-args-deps` functions

When modifying a skill, check if other skills reference it and update accordingly.

## Marketplace Distribution

The `.claude-plugin/marketplace.json` file controls distribution:

- Update plugin `version` when making changes
- Keep `description` accurate
- Maintain `keywords` for discoverability
- Ensure `license` is correct (MIT)

## Contributing

When adding new content:
1. Follow existing structure and style
2. Align with source posts
3. Update README.md to include new skills/commands
4. Bump versions appropriately
5. Test that examples work
6. Verify integration with existing patterns

