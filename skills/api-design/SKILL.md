---
name: api-design
description: Builds production-ready HTTP APIs with thin handlers, consistent error envelopes, health/readiness checks, CORS, idempotency, rate limiting, and graceful shutdown. Use when designing or implementing HTTP endpoints, writing orpc route factories, defining Zod request/response schemas, mapping domain errors to status codes, or adding operational concerns (health checks, X-Request-ID, Retry-After) to a TypeScript API.
version: 1.1.0
libraries: ["@orpc/server", "zod"]
---

# API Design Patterns

## Overview

HTTP handlers have one job: **translate between HTTP and your domain**. They validate input at the boundary, call business logic written as `fn(args, deps)` returning a `Result`, and map that result to an HTTP response. Handlers stay thin and contain no business logic. That keeps them testable, keeps domain code transport-agnostic, and keeps error/operational concerns consistent across every endpoint.

```
HTTP Request
    |
    v
Handler (thin layer)
    |-> Validate Input (Zod via framework)
    |-> Call Business Logic: fn(args, deps) -> Result
    |-> Map Result to HTTP Response
    |
    v
HTTP Response
```

## When to Use

- Designing or implementing new HTTP endpoints
- Writing orpc route factories with dependency injection
- Defining request/response contracts with Zod schemas
- Mapping domain errors to consistent HTTP status codes
- Adding operational concerns: health checks, CORS, idempotency, rate limiting, graceful shutdown

**When NOT to use:** Internal function-to-function calls (no HTTP boundary), pure domain logic, or background jobs that never face an HTTP request. Validate-at-boundary logic belongs in [`validation-boundary`](../validation-boundary/SKILL.md); error modelling belongs in [`result-types`](../result-types/SKILL.md).

**Related:** [`fn-args-deps`](../fn-args-deps/SKILL.md) (the handler delegates to these), [`validation-boundary`](../validation-boundary/SKILL.md) (input validation at the edge), [`result-types`](../result-types/SKILL.md) (what business logic returns), [`resilience`](../resilience/SKILL.md) (retry/timeout around calls), [`observability`](../observability/SKILL.md) (request IDs and tracing).

For how this layer fits the whole system, see [`references/architecture.md`](../../references/architecture.md).

## Required Behaviors

### 1. Route Factory Pattern with DI

Each route follows `fn(args, deps)` and uses a factory for dependency injection:

```typescript
// routes/posts/get-post.ts
import { os, ORPCError } from "@orpc/server";
import { z } from "zod";
import type { PostRepository } from "./types";

// Explicit deps type for this route
type GetPostDeps = {
  postRepo: PostRepository;
};

// Factory function: creates route with injected deps
export function createGetPost({ deps }: { deps: GetPostDeps }) {
  return os
    .input(z.object({ postId: z.string().uuid() }))
    .output(PostResponse)
    .handler(async ({ input }) => {
      const post = await deps.postRepo.findById({ id: input.postId });
      if (!post) {
        throw new ORPCError("NOT_FOUND", {
          status: 404,
          message: `Post ${input.postId} not found`,
        });
      }
      return post;
    });
}
```

### 2. Consistent Error Envelope

All errors MUST use the same JSON shape:

```typescript
const ErrorResponse = z.object({
  code: z.string(),           // Machine-readable: "NOT_FOUND"
  message: z.string(),        // Human-readable explanation
  requestId: z.string(),      // For correlation in logs
  details: z.unknown().optional(),
});

function createErrorResponse(
  code: string,
  message: string,
  requestId: string,
  details?: unknown
) {
  return { code, message, requestId, details };
}
```

**Rule: `ORPCError(code)` must match `ErrorResponse.code`**:

```typescript
// CORRECT - codes match
throw new ORPCError("NOT_FOUND", {
  status: 404,
  data: createErrorResponse("NOT_FOUND", "User not found", requestId),
});

// WRONG - codes mismatch
throw new ORPCError("BAD_REQUEST", {
  data: createErrorResponse("MISSING_FIELD", ...), // Confusing!
});
```

### 3. Standard Error Mapping

Map all error types consistently:

```typescript
const errorToStatus: Record<string, number> = {
  NOT_FOUND: 404,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  VALIDATION_FAILED: 400,
  CONFLICT: 409,
  TOO_MANY_REQUESTS: 429,
  SERVICE_UNAVAILABLE: 503,
};
```

### 4. Health and Readiness Endpoints

```typescript
// /health - Liveness (is process running?)
export const health = os.handler(() => ({ status: "ok" }));

// /ready - Readiness (can handle traffic?)
export const ready = os.handler(async () => {
  const checks = {
    database: await checkDatabase(),
    cache: await checkCache(),
  };

  const allHealthy = Object.values(checks).every(Boolean);

  if (!allHealthy) {
    throw new ORPCError("SERVICE_UNAVAILABLE", {
      status: 503,
      data: { status: "not_ready", checks },
    });
  }

  return { status: "ready", checks };
});
```

**Response contract:**
- **200**: `{ status: "ready", checks }`
- **503**: `{ status: "not_ready", checks }`

### 5. X-Request-ID Header (Central Middleware)

Set this header centrally, not in each handler:

```typescript
// In top-level request middleware or response hook
response.headers.set("X-Request-ID", context.requestId);
```

### 6. CORS Configuration

```typescript
new CORSPlugin({
  origin: (origin) => {
    // No Origin = not a browser request (curl, server-to-server)
    // Return null = "don't emit CORS headers" (request proceeds normally)
    if (!origin) return null;
    // Return origin string to allow, null to deny
    return ALLOWED_ORIGINS.has(origin) ? origin : null;
  },
  allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization', 'Idempotency-Key'],
  credentials: true,
});
```

### 7. Idempotency for Mutations

```typescript
export const createOrder = os
  .input(CreateOrderInput)
  .handler(async ({ input, context }) => {
    const { req, requestId } = context as AppContext;

    const idempotencyKey = req.headers.get('idempotency-key');
    if (!idempotencyKey) {
      throw new ORPCError("MISSING_IDEMPOTENCY_KEY", {
        status: 400,
        data: createErrorResponse(
          "MISSING_IDEMPOTENCY_KEY",
          "Idempotency-Key header required",
          requestId
        ),
      });
    }

    // Check cache for existing result, or process and store
    // ...
  });
```

### 8. Rate Limiting with Retry-After

```typescript
throw new ORPCError("TOO_MANY_REQUESTS", {
  status: 429,
  headers: { "Retry-After": "60" },  // Seconds until retry allowed
  data: createErrorResponse(
    "TOO_MANY_REQUESTS",
    "Rate limit exceeded. Try again in 60 seconds.",
    requestId
  ),
});
```

### 9. Graceful Shutdown

```typescript
let isShuttingDown = false;

process.on('SIGTERM', () => {
  isShuttingDown = true;
  // Wait for in-flight requests, then exit
});

// In handlers or middleware
if (isShuttingDown) {
  throw new ORPCError("SERVICE_UNAVAILABLE", {
    status: 503,
    message: "Server is shutting down",
  });
}
```

### 10. Route File Organization

**One file per route** with co-located tests:

```
routes/
├── posts/
│   ├── get-post.ts           # Route factory
│   ├── get-post.test.ts      # Co-located test
│   ├── list-posts.ts
│   ├── create-post.ts
│   ├── index.ts              # Composes postsRouter
│   └── schemas.ts            # Shared Zod schemas
└── index.ts                  # Composes apiRouter
```

**Naming conventions:**

| Operation | File Name | Factory | Router Key |
|-----------|-----------|---------|------------|
| Get one | `get-post.ts` | `createGetPost` | `getPost` |
| List | `list-posts.ts` | `createListPosts` | `listPosts` |
| Create | `create-post.ts` | `createCreatePost` | `createPost` |

**Composition at boundaries:**

```typescript
// routes/posts/index.ts
export function createPostsRouter({ deps }: { deps: PostsRouterDeps }) {
  return {
    getPost: createGetPost({ deps }),
    listPosts: createListPosts({ deps }),
    createPost: createCreatePost({ deps }),
  };
}

// routes/index.ts
export function createApiRouter({ deps }: { deps: ApiRouterDeps }) {
  return {
    posts: createPostsRouter({ deps }),
    users: createUsersRouter({ deps }),
  };
}
```

## Testing Routes

```typescript
import { describe, it, expect, beforeEach } from "vitest";
import { call, ORPCError } from "@orpc/server";
import { mock } from "vitest-mock-extended";
import { createGetPost, type GetPostDeps } from "./get-post";

describe("getPost", () => {
  const postId = "550e8400-e29b-41d4-a716-446655440000";
  let deps: GetPostDeps;
  let getPost: ReturnType<typeof createGetPost>;

  beforeEach(() => {
    deps = { postRepo: mock() };
    getPost = createGetPost({ deps });
  });

  it("returns post when found", async () => {
    deps.postRepo.findById.mockResolvedValue({
      id: postId,
      title: "Test Post",
    });

    const result = await call(getPost, { postId });
    expect(result.title).toBe("Test Post");
  });

  it("throws NOT_FOUND when post missing", async () => {
    deps.postRepo.findById.mockResolvedValue(null);

    try {
      await call(getPost, { postId });
      expect.fail("Should have thrown");
    } catch (error) {
      expect(error).toBeInstanceOf(ORPCError);
      expect((error as ORPCError).code).toBe("NOT_FOUND");
    }
  });
});
```

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "Just put the business logic in the handler, it's faster" | Handlers coupled to HTTP can't be reused or tested without spinning up a server. Keep them thin; delegate to `fn(args, deps)`. |
| "Each endpoint can shape its own errors" | Inconsistent error bodies force every consumer to special-case each endpoint. Use one envelope everywhere. |
| "We'll add health checks before launch" | Orchestrators (k8s, ECS) need `/health` and `/ready` to route traffic safely. Add them from the start. |
| "Idempotency keys are overkill" | Network retries WILL replay your POST. Without a key, you double-charge or double-create. |
| "We can retry inside the handler" | Retry belongs at the workflow level, once. See [`resilience`](../resilience/SKILL.md) for why double-retry is dangerous. |
| "Set X-Request-ID in each handler" | Per-handler header logic drifts. Set it once in middleware so every response is correlated. |

## Red Flags

- Business logic (queries, calculations, side effects) living inside a handler
- Different error shapes across endpoints, or `ORPCError(code)` not matching `ErrorResponse.code`
- List endpoints without pagination
- Mutation endpoints with no `Idempotency-Key` handling
- No `/health` or `/ready` endpoints
- `Retry-After` missing on 429 responses
- Request IDs set inconsistently or not at all
- Internal error details (stack traces, SQL) leaking into 500 responses

## Verification

After implementing an API surface:

- [ ] Each route is a factory taking injected `deps` and delegates to business logic
- [ ] Every error response uses the same envelope and the code matches the `ORPCError` code
- [ ] Domain errors map to status codes via a single shared mapping
- [ ] `/health` (200) and `/ready` (200/503) endpoints exist
- [ ] Mutations require and honor an `Idempotency-Key`
- [ ] 429 responses include `Retry-After`; shutdown drains with 503
- [ ] `X-Request-ID` is set centrally in middleware
- [ ] Each route has a co-located test exercising success and error paths

## Quick Reference

| Concern | Pattern | Where |
|---------|---------|-------|
| Input validation | Zod schemas | Framework boundary |
| Error format | Consistent envelope | All error responses |
| Error codes | `ORPCError(code)` = `ErrorResponse.code` | Handler |
| Request ID | Set in middleware | Top-level |
| Health check | `/health` (200) | Liveness |
| Readiness | `/ready` (200/503) | Traffic routing |
| CORS | Plugin with origin callback | Framework config |
| Idempotency | `Idempotency-Key` header | Create/mutate endpoints |
| Rate limits | 429 + `Retry-After` header | Middleware |
| Shutdown | 503 during drain | All endpoints |
| Route files | One per route, co-located tests | Organization |
