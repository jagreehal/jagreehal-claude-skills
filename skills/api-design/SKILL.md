---
name: api-design
description: "Build production-ready HTTP APIs with clean handlers, consistent error envelopes, health checks, CORS, and operational excellence."
version: 1.0.0
libraries: ["@orpc/server", "zod"]
---

# API Design Patterns

## Core Principle

HTTP handlers have exactly one job: **translate between HTTP and your domain**.

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

Handlers should be thin. They don't contain business logic.

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
