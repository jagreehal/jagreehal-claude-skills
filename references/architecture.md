# Architecture Reference

The shared mental model behind the TypeScript skills. Individual skills govern one layer each; this is the map of how they fit together. Use alongside `fn-args-deps`, `result-types`, `validation-boundary`, `resilience`, `observability`, `api-design`, and `design-principles`.

## The Layers

```text
HTTP / Transport boundary        ── api-design, validation-boundary
  parse input with Zod, map Result → HTTP status
        │
        ▼
Workflows                        ── resilience, ts-workflows
  compose steps; step.retry(), step.withTimeout()
        │
        ▼
Business functions               ── fn-args-deps, result-types
  fn(args, deps): Result<T, E>, wrapped with trace()
        │
        ▼
Infrastructure                   ── config-management, observability
  postgres, redis, http — just transport, injected as deps
```

Each layer only knows the layer directly below it, and only through an explicit dependency. Nothing reaches around a layer; nothing throws across one.

## The Canonical Pattern

```typescript
// 1. Explicit deps type — dependencies are visible in the signature
type GetUserDeps = { db: Database; logger: Logger };

// 2. Function takes (args, deps), returns a Result — failures are values
async function getUser(
  args: { userId: string },
  deps: GetUserDeps,
): Promise<Result<User, 'NOT_FOUND' | 'DB_ERROR'>> {
  const user = await deps.db.findUser(args.userId);
  return user ? ok(user) : err('NOT_FOUND');
}

// 3. Validate at the boundary with Zod — inside the function, args are trusted
const GetUserSchema = z.object({ userId: z.string().uuid() });

// 4. Handler maps the Result to HTTP — the only place that knows about HTTP
app.get('/users/:id', async (req, res) => {
  const parsed = GetUserSchema.safeParse(req.params);
  if (!parsed.success) return res.status(400).json(formatZodError(parsed.error));

  const result = await getUser(parsed.data, deps);
  return resultToResponse(result, res);
});
```

## The Principles

- **Explicit over implicit**: dependencies are visible in signatures (`fn-args-deps`), never reached from module scope.
- **Parse, don't validate**: transform untrusted input into types that cannot be invalid, once, at the boundary (`validation-boundary`).
- **Never throw for expected failures**: errors are values (`Result<T, E>`), not exceptions (`result-types`). `throw` is reserved for programmer error and impossible states.
- **Composition over inheritance**: workflows compose functions; resilience wraps steps without touching business logic (`resilience`).
- **Rules over rituals**: ESLint enforces the boundaries so they hold under AI-generated code (`pattern-enforcement`), not documentation alone.
- **Observability is orthogonal**: `trace()` and structured logging wrap functions without entering their logic (`observability`).

## Where Each Skill Fits

| Concern | Skill |
|---|---|
| Function shape & dependency injection | `fn-args-deps` |
| Returning failures as values | `result-types` |
| Validating untrusted input | `validation-boundary` |
| Compiler & type-level safety | `strict-typescript` |
| Startup config & secrets | `config-management` |
| HTTP handlers & error envelopes | `api-design` |
| Retry / timeout / circuit breaking | `resilience` |
| Tracing & structured logging | `observability` |
| Enforcing the boundaries in CI | `pattern-enforcement` |
| Design quality across all layers | `design-principles` |

Derived from the TypeScript architecture posts at [arrangeactassert.com](https://arrangeactassert.com).
