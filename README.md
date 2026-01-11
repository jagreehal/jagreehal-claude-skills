# jagreehal-claude-skills

Opinionated TypeScript patterns for AI-assisted development. Skills, commands, and hooks for Claude Code that enforce production-grade architecture.

## Installation

### From Marketplace

```bash
# Add the marketplace
/plugin marketplace add jagreehal/jagreehal-claude-skills

# Install the plugin
/plugin install jagreehal-claude-skills@jagreehal-marketplace
```

### Manual Configuration

Add to your `.claude/settings.local.json`:

```json
{
  "extraKnownMarketplaces": {
    "jagreehal-marketplace": {
      "source": {
        "source": "github",
        "repo": "jagreehal/jagreehal-claude-skills"
      }
    }
  },
  "enabledPlugins": {
    "jagreehal-claude-skills@jagreehal-marketplace": true
  }
}
```

## Skills

### Core Patterns (Technical)

| Skill | Description |
|-------|-------------|
| `fn-args-deps` | Core pattern: `fn(args, deps)` for testable functions |
| `validation-boundary` | Zod schemas at boundaries, trust inside |
| `result-types` | Never throw - use `Result<T, E>` with workflows |
| `observability` | `trace()` wrapper, Pino logging, OpenTelemetry |
| `resilience` | Retry/timeout at workflow level, not in functions |
| `config-management` | Validate config at startup, secrets in memory only |
| `api-design` | Production-ready HTTP APIs with clean handlers, error envelopes, health checks |
| `strict-typescript` | Beyond `strict: true` - advanced types, ESLint enforcement |
| `pattern-enforcement` | ESLint rules that fail the build |
| `testing-strategy` | Test pyramid with vitest-mock-extended |
| `writing-tests` | Test naming, assertions, edge case checklists (BugMagnet-based) |
| `performance-testing` | Load testing, chaos engineering, trace correlation |
| `react-development` | Modern React patterns, technology stack, accessibility |
| `storybook-journeys` | Storybook user journey storyboards with MSW API mocking and interactions |

### Behavioral (Workflow)

| Skill | Description |
|-------|-------------|
| `critical-peer` | Professional skepticism, concise output, research first |
| `tdd-workflow` | Red-green-refactor with Result type testing |
| `session-continuity` | Persist tasks across sessions with `.claude/` files |
| `design-principles` | Fail-fast, no `any`, domain naming, YAGNI, 8-dimension analysis |
| `debugging-methodology` | Evidence-based debugging with instrumentation |
| `code-flow-analysis` | Trace execution paths before implementing |

### Communication & Research

| Skill | Description |
|-------|-------------|
| `research-first` | Validate solutions before presenting, never ask lazy questions |
| `confidence-levels` | Express confidence as %, explain gaps, show evidence |
| `concise-output` | Maximum information density, eliminate filler phrases |
| `literal-answers` | Answer questions literally, don't interpret as instructions |

### Domain Skills

| Skill | Description |
|-------|-------------|
| `documentation-standards` | 8 quality dimensions, user-centered documentation |
| `system-architecture` | Trade-off analysis, ADRs, pattern selection |
| `investigation-modes` | LEARNING/INVESTIGATION/SOLVING with explicit transitions |
| `ui-design-principles` | Design systems, implementation-ready interfaces |
| `structured-writing` | Voice preservation, gap identification |
| `data-visualization` | Chart selection, encoding hierarchy, accessibility |

## Commands

| Command | Description |
|---------|-------------|
| `/scaffold-function <name>` | Generate fn(args, deps) function with tests |
| `/verify-patterns` | Quick check for pattern violations |
| `/full-review [--report] [--scope <path>]` | Comprehensive codebase review with detailed report |
| `/init-project` | Set up new project with patterns |
| `/learn-from-prs [--count <n>] [--state <state>]` | Analyze PR feedback patterns and suggest config updates |

## Agents

| Agent | Description |
|-------|-------------|
| `pattern-checker` | Autonomous agent that scans codebase for pattern violations and generates compliance reports |
| `task-check` | Verifies task completion with context-aware standards (POC vs production) before finishing work |

## Core Libraries

| Library | Purpose |
|---------|---------|
| `zod` | Schema validation at boundaries |
| `@jagreehal/workflow` | Result types and workflow composition |
| `autotel` | OpenTelemetry trace() wrapper |
| `pino` | Structured logging (5x faster than Winston) |
| `vitest-mock-extended` | Typed mocks from deps interfaces |
| `@total-typescript/ts-reset` | Fix JSON.parse returning any |
| `type-fest` | Utility types |
| `k6` | Load testing and performance validation |
| `node-env-resolver` | Configuration validation and secret management |

## The Pattern

```typescript
// 1. Define explicit deps type
type GetUserDeps = { db: Database; logger: Logger };

// 2. Function takes (args, deps), returns Result
async function getUser(
  args: { userId: string },
  deps: GetUserDeps
): Promise<Result<User, 'NOT_FOUND' | 'DB_ERROR'>> {
  const user = await deps.db.findUser(args.userId);
  return user ? ok(user) : err('NOT_FOUND');
}

// 3. Validate at boundary with Zod
const GetUserSchema = z.object({ userId: z.string().uuid() });

// 4. Handler maps Result to HTTP
app.get('/users/:id', async (req, res) => {
  const parsed = GetUserSchema.safeParse(req.params);
  if (!parsed.success) return res.status(400).json(formatZodError(parsed.error));

  const result = await getUser(parsed.data, deps);
  return resultToResponse(result, res);
});
```

## Architecture

```
HTTP Handlers
  -> validate with Zod, map Result to HTTP

Workflows
  -> createWorkflow({ ... })(step => { ... })
  -> step.retry(), step.withTimeout()

Business Functions
  -> fn(args, deps): Result<T, E>
  -> wrapped with trace()

Infrastructure
  -> postgres, redis, http (just transport)
```

## Philosophy

- **Explicit over implicit** - Dependencies visible in signatures
- **Parse, don't validate** - Transform to types that can't be invalid
- **Never throw** - Errors are values, not exceptions
- **Composition over inheritance** - Workflows compose functions
- **Rules over rituals** - ESLint enforces patterns, not documentation

## Based On

These patterns are derived from [arrangeactassert.com](https://arrangeactassert.com) TypeScript architecture posts.
