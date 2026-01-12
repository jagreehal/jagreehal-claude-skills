# jagreehal-claude-skills

Opinionated TypeScript patterns for AI-assisted development. Skills, commands, and hooks for Claude Code that enforce production-grade architecture.

## Installation

### From Marketplace

```bash
# Add the marketplace
/plugin marketplace add jagreehal/jagreehal-claude-skills

# List available plugins
/plugin list jagreehal-marketplace

# Install only what you need
/plugin install <plugin-name>@jagreehal-marketplace
```

### Available Plugins

This marketplace contains **10 plugins**. Install only what you need.

| Plugin | Skills | Description |
|--------|--------|-------------|
| `typescript-patterns` | 9 | Core TS architecture: fn(args, deps), Result types, Zod, observability |
| `testing-tdd` | 4 | TDD workflow: red-green-refactor, test pyramid, performance testing |
| `communication-behavior` | 6 | Claude style: critical peer, concise output, research-first |
| `workflow-productivity` | 10 | Session management, verification, git worktrees, parallel agents |
| `frontend-react` | 4 | React patterns, Storybook, UI design, browser automation |
| `documentation-architecture` | 5 | Documentation standards, ADRs, data visualization |
| `debugging-analysis` | 2 | Evidence-based debugging, code flow analysis |
| `skill-authoring` | 1 | Guide for creating custom skills |
| `code-review` | - | Auto code review on file modifications (hooks) |
| `track-and-improve` | - | 5 whys root cause analysis for mistakes |

### Quick Start Examples

```bash
# TypeScript developer wanting core patterns + TDD
/plugin install typescript-patterns@jagreehal-marketplace
/plugin install testing-tdd@jagreehal-marketplace

# Frontend developer
/plugin install frontend-react@jagreehal-marketplace
/plugin install typescript-patterns@jagreehal-marketplace

# Want Claude to be more concise and research-driven
/plugin install communication-behavior@jagreehal-marketplace

# Full productivity workflow
/plugin install workflow-productivity@jagreehal-marketplace
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
    "typescript-patterns@jagreehal-marketplace": true,
    "testing-tdd@jagreehal-marketplace": true
  }
}
```

---

## Plugin Details

### typescript-patterns (9 skills)

Core TypeScript architecture patterns for production-grade code.

| Skill | Description |
|-------|-------------|
| `fn-args-deps` | Core pattern: `fn(args, deps)` for testable functions |
| `validation-boundary` | Zod schemas at boundaries, trust inside |
| `result-types` | Never throw - use `Result<T, E>` with workflows |
| `strict-typescript` | Beyond `strict: true` - advanced types, ESLint enforcement |
| `config-management` | Validate config at startup, secrets in memory only |
| `api-design` | Production-ready HTTP APIs with clean handlers, error envelopes |
| `pattern-enforcement` | ESLint rules that fail the build |
| `resilience` | Retry/timeout at workflow level, not in functions |
| `observability` | `trace()` wrapper, Pino logging, OpenTelemetry |

### testing-tdd (4 skills)

TDD workflow and comprehensive testing strategies.

| Skill | Description |
|-------|-------------|
| `tdd-workflow` | Red-green-refactor with Result type testing |
| `testing-strategy` | Test pyramid with vitest-mock-extended |
| `writing-tests` | Test naming, assertions, edge case checklists (BugMagnet-based) |
| `performance-testing` | Load testing, chaos engineering, trace correlation |

### communication-behavior (6 skills)

How Claude communicates and behaves during sessions.

| Skill | Description |
|-------|-------------|
| `critical-peer` | Professional skepticism, concise output, research first |
| `concise-output` | Maximum information density, eliminate filler phrases |
| `confidence-levels` | Express confidence as %, explain gaps, show evidence |
| `research-first` | Validate solutions before presenting, never ask lazy questions |
| `literal-answers` | Treat questions as literal questions, answer honestly |
| `answer-questions-directly` | Answer questions literally, don't interpret as instructions |

### workflow-productivity (10 skills)

Session management, task tracking, and development workflow.

| Skill | Description |
|-------|-------------|
| `session-continuity` | Persist tasks across sessions with `.claude/` files |
| `investigation-modes` | LEARNING/INVESTIGATION/SOLVING with explicit transitions |
| `verification-before-completion` | Run verification commands before claiming work complete |
| `design-exploration` | Explore user intent collaboratively before implementation |
| `implementation-planning` | Create bite-sized TDD task plans with exact file paths |
| `git-worktrees` | Create isolated git worktrees for feature work |
| `parallel-agent-dispatch` | Dispatch multiple agents in parallel for independent tasks |
| `code-review-reception` | Handle code review feedback with technical verification |
| `branch-completion` | Guide completion of development work with verification |
| `create-tasks` | Create well-formed tasks with context and acceptance criteria |

### frontend-react (4 skills)

Frontend development with React and modern tooling.

| Skill | Description |
|-------|-------------|
| `react-development` | Modern React patterns, technology stack, accessibility |
| `storybook-journeys` | Storybook user journey storyboards with MSW API mocking |
| `ui-design-principles` | Design systems, implementation-ready interfaces |
| `agent-browser` | Browser automation for web testing, form filling, screenshots |

### documentation-architecture (5 skills)

Documentation standards and system architecture decisions.

| Skill | Description |
|-------|-------------|
| `documentation-standards` | 8 quality dimensions, user-centered documentation |
| `system-architecture` | Trade-off analysis, ADRs, pattern selection |
| `structured-writing` | Voice preservation, gap identification |
| `data-visualization` | Chart selection, encoding hierarchy, accessibility |
| `design-principles` | Fail-fast, no `any`, domain naming, YAGNI |

### debugging-analysis (2 skills)

Evidence-based debugging and code analysis.

| Skill | Description |
|-------|-------------|
| `debugging-methodology` | Evidence-based debugging with instrumentation |
| `code-flow-analysis` | Trace execution paths before implementing |

### skill-authoring (1 skill)

Meta-skill for creating your own Claude Code skills.

| Skill | Description |
|-------|-------------|
| `skill-authoring` | Guide for creating, editing, and reviewing skills |

### code-review

Automatic code review triggered on file modifications. Uses hooks to review against project-specific rules aligned with TypeScript patterns.

### track-and-improve

Capture mistakes and improvement opportunities with 5 whys root cause analysis. Learn from patterns to prevent future issues.

---

## Commands

| Command | Description |
|---------|-------------|
| `/scaffold-function <name>` | Generate fn(args, deps) function with tests |
| `/verify-patterns` | Quick check for pattern violations |
| `/full-review [--report] [--scope <path>]` | Comprehensive codebase review with detailed report |
| `/init-project` | Set up new project with patterns |
| `/learn-from-prs [--count <n>] [--state <state>]` | Analyze PR feedback patterns and suggest config updates |
| `/workflow <mode\|off>` | Set collaboration mode: STEP-BY-STEP, DEEP-THINK, or PAIR |
| `/track-improve <description>` | Capture mistake or improvement with 5 whys root cause analysis |

## Agents

| Agent | Description |
|-------|-------------|
| `pattern-checker` | Autonomous agent that scans codebase for pattern violations |
| `task-check` | Verifies task completion with context-aware standards |

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

```text
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
