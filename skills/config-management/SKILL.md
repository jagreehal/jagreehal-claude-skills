---
name: config-management
description: Validates application configuration once at startup with Zod or node-env-resolver, injects it via deps, and keeps secrets in memory instead of environment variables. Use when loading env vars, building a config schema, wiring secret managers (AWS Secrets Manager, ephemeral credentials), deciding where config is read, adding secret scanning to CI, or testing code that depends on config.
version: 1.1.0
libraries: ["node-env-resolver", "zod"]
---

# Config Management

## Overview

Configuration is a leading source of runtime errors: a missing variable or a string where a number belongs takes down a code path at 3 AM, far from where the mistake was made. Validate the entire config **once at startup** so a bad config fails the process immediately, with a clear error, before serving any traffic.

Two failure modes dominate. First, reading `process.env` deep inside request handlers: this re-parses on every call, scatters config logic, and hides misconfiguration until that path executes. Resolve once, then inject the typed config through `deps`. Second, treating environment variables as a safe home for secrets. `process.env` is visible to child processes, `/proc/self/environ`, and stray log lines. Load secrets into memory from a secret manager and keep them out of the environment entirely.

## When to Use

- Loading and validating environment variables at process startup
- Defining a typed config schema (Zod or node-env-resolver validators)
- Fetching secrets from AWS Secrets Manager or similar, with rotation
- Deciding where config gets read (startup vs request time)
- Adding secret scanning (TruffleHog, Gitleaks) to CI
- Writing tests for code that depends on config

**When NOT to use:** per-request runtime input. Validate that at the API boundary (see [`validation-boundary`](../validation-boundary/SKILL.md)). Feature flags evaluated dynamically are a separate concern from startup config.

**Related:** [`validation-boundary`](../validation-boundary/SKILL.md) (Zod at boundaries), [`fn-args-deps`](../fn-args-deps/SKILL.md) (injecting config through deps), [`strict-typescript`](../strict-typescript/SKILL.md) (typing the resolved config), [`observability`](../observability/SKILL.md) (avoiding secrets in logs).

## Required Behaviors

### 1. Validate Config at Startup

Use [node-env-resolver](https://github.com/jagreehal/node-env-resolver) for multi-source configuration with validation:

```typescript
import { resolveAsync } from 'node-env-resolver';
import { processEnv } from 'node-env-resolver/resolvers';
import { postgres, string, number } from 'node-env-resolver/validators';
import { awsSecrets } from 'node-env-resolver-aws';

const config = await resolveAsync({
  resolvers: [
    // Non-sensitive config from process.env (safe)
    [processEnv(), {
      PORT: number({ default: 3000 }),
      NODE_ENV: ['development', 'production'] as const,
    }],
    // Secrets loaded directly into memory from AWS (never touch process.env)
    [awsSecrets({ secretId: 'my-app' }), {
      DATABASE_URL: postgres(),
      API_KEY: string(),
    }],
  ],
  options: {
    preventProcessEnvWrite: true,  // Secrets never touch process.env
  },
});
```

**Alternative:** Use Zod directly for simpler setups:

```typescript
// config/schema.ts
import { z } from 'zod';

const ConfigSchema = z.object({
  port: z.coerce.number().min(1).max(65535),
  database: z.object({
    host: z.string().min(1),
    port: z.coerce.number(),
    name: z.string().min(1),
  }),
  redis: z.object({
    url: z.string().url(),
  }),
  logLevel: z.enum(['debug', 'info', 'warn', 'error']),
});

export type Config = z.infer<typeof ConfigSchema>;

// main.ts - Validate immediately on startup
const config = ConfigSchema.parse({
  port: process.env.PORT,
  database: {
    host: process.env.DB_HOST,
    port: process.env.DB_PORT,
    name: process.env.DB_NAME,
  },
  redis: {
    url: process.env.REDIS_URL,
  },
  logLevel: process.env.LOG_LEVEL,
});

// If we get here, config is valid and typed
```

### 2. Never Read Config During Requests

Config should be resolved ONCE at startup, then injected:

```typescript
// WRONG - Reading env vars during request
async function getUser(args: { userId: string }, deps: GetUserDeps) {
  const timeout = parseInt(process.env.DB_TIMEOUT || '5000'); // Reads every call!
  return deps.db.findUser(args.userId, { timeout });
}

// CORRECT - Config injected via deps
type GetUserDeps = {
  db: Database;
  config: { dbTimeout: number };
};

async function getUser(args: { userId: string }, deps: GetUserDeps) {
  return deps.db.findUser(args.userId, { timeout: deps.config.dbTimeout });
}
```

### 3. Secrets in Memory Only

Never store secrets in environment variables. Load directly from secret managers into memory:

```typescript
// WRONG - Secret in env, visible in process dumps, /proc/self/environ, child processes
const apiKey = process.env.API_KEY;

// CORRECT - Fetch from secret manager at startup, loaded into memory only
const config = await resolveAsync({
  resolvers: [
    [awsSecrets({ secretId: 'my-app' }), {
      API_KEY: string(),
      DATABASE_PASSWORD: string(),
    }],
  ],
  options: {
    preventProcessEnvWrite: true,  // Secrets never touch process.env
  },
});

// Secrets are in config object in memory, never in process.env
const deps = { db: createDb(config.DATABASE_PASSWORD), apiKey: config.API_KEY };
```

**Why memory is safer:**
- `process.env` is accessible to child processes
- On Linux, `/proc/self/environ` exposes all environment variables
- Error messages and logs may accidentally include environment variables
- Secrets in memory are isolated to your application process

### 3a. Ephemeral Credentials

Prefer short-lived, auto-rotating credentials over long-lived secrets:

```typescript
const config = await resolveAsync({
  resolvers: [
    [awsSecrets({
      secretId: 'prod/db-creds',
      refreshInterval: 3600000,  // Refresh every hour
    }), {
      DB_USERNAME: string(),
      DB_PASSWORD: string(),  // Short-lived, auto-rotated
    }],
  ],
});
```

If a credential leaks, automatic expiration limits the blast radius.

### 3b. Secret Scanning in CI

Runtime policies protect production, but a committed `.env` file still leaks secrets. Run secret scanning in CI:

```yaml
# .github/workflows/security.yml
name: Security Checks

on: [push, pull_request]

jobs:
  secret-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for thorough scanning

      - name: TruffleHog Secret Scan
        uses: trufflesecurity/trufflehog@main
        with:
          extra_args: --only-verified
```

Tools like **TruffleHog** and **Gitleaks** scan commit history, catching secrets that were committed and then "deleted" (but still exist in git history).

### 4. Fail Fast on Missing Config

```typescript
// WRONG - Default values hide misconfiguration
const port = process.env.PORT || 3000;
const dbHost = process.env.DB_HOST || 'localhost';

// CORRECT - Fail immediately if missing
const ConfigSchema = z.object({
  port: z.coerce.number(),  // No default - must be provided
  dbHost: z.string().min(1),  // No default - must be provided
});

// Throws ZodError at startup if missing
const config = ConfigSchema.parse(process.env);
```

### 5. Type-Safe Config Access

Use Zod inference to ensure type safety:

```typescript
// Config type is inferred from schema
export type Config = z.infer<typeof ConfigSchema>;

// Deps include typed config
type GetUserDeps = {
  db: Database;
  config: Pick<Config, 'dbTimeout' | 'maxRetries'>;
};
```

## Environment-Specific Config

```typescript
const EnvSchema = z.enum(['development', 'staging', 'production']);

const BaseConfigSchema = z.object({
  env: EnvSchema,
  port: z.coerce.number(),
});

// Environment-specific overrides
const ProductionConfigSchema = BaseConfigSchema.extend({
  env: z.literal('production'),
  sslEnabled: z.literal(true),
});

const DevelopmentConfigSchema = BaseConfigSchema.extend({
  env: z.literal('development'),
  sslEnabled: z.literal(false).default(false),
});

const ConfigSchema = z.discriminatedUnion('env', [
  ProductionConfigSchema,
  DevelopmentConfigSchema,
]);
```

## Dependency Injection for Testability

Configuration resolution should accept resolvers as parameters:

```typescript
// config.ts
import { resolveAsync, type Resolver } from 'node-env-resolver';
import { processEnv } from 'node-env-resolver/resolvers';
import { awsSecrets } from 'node-env-resolver-aws';
import { postgres, string, number } from 'node-env-resolver/validators';

const schema = {
  PORT: number({ default: 3000 }),
  DATABASE_URL: postgres(),
  API_KEY: string(),
};

export async function getConfig(
  resolvers: Resolver[] = [
    processEnv(),
    awsSecrets({ secretId: 'my-app' }),
  ]
) {
  return resolveAsync({
    resolvers: resolvers.map(r => [r, schema]),
  });
}
```

Now your tests can inject mock resolvers:

```typescript
// config.test.ts
import { getConfig } from './config';

it('should resolve configuration', async () => {
  const mockResolver = {
    name: 'test-env',
    load: async () => ({
      DATABASE_URL: 'postgres://test:5432/testdb',
      API_KEY: 'test-key',
    }),
    loadSync: () => ({
      DATABASE_URL: 'postgres://test:5432/testdb',
      API_KEY: 'test-key',
    }),
  };

  const config = await getConfig([mockResolver]);

  expect(config.DATABASE_URL).toBe('postgres://test:5432/testdb');
  expect(config.API_KEY).toBe('test-key');
  expect(config.PORT).toBe(3000); // default value
});
```

No `vi.mock()` needed. Just pass a resolver object. This is the same dependency injection pattern we've been using throughout.

## Config in Tests

```typescript
import { mock } from 'vitest-mock-extended';

const testConfig: Pick<Config, 'dbTimeout'> = {
  dbTimeout: 100, // Fast for tests
};

const deps = {
  db: mock<Database>(),
  config: testConfig,
};

const result = await getUser({ userId: '123' }, deps);
```

## Quick Reference

| Rule | Implementation |
|------|----------------|
| Validate at startup | Zod schema.parse() in main.ts |
| Never read during request | Inject config via deps |
| Secrets in memory | SecretManager.get(), not process.env |
| Fail fast | No defaults for required config |
| Type safety | z.infer<typeof Schema> |

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "I'll read `process.env.X` right where I need it" | That re-parses on every call and hides the missing variable until that path runs. Resolve once, inject via deps. |
| "A default of `3000` / `localhost` is convenient" | Defaults mask misconfiguration in production. Required config should fail loudly when absent. |
| "Secrets in env vars are standard practice" | Env vars leak to child processes, `/proc/self/environ`, and logs. Load secrets into memory from a secret manager. |
| "We deleted the `.env` from the repo, so we're fine" | It still lives in git history. Run TruffleHog/Gitleaks over full history in CI. |
| "Mocking config in tests needs `vi.mock`" | Inject a resolver or a `Pick<Config, ...>` object instead: same DI pattern, no module mocking. |

## Red Flags

- `process.env` accessed anywhere outside the startup config module
- `process.env.X || 'default'` for required values
- Secrets read from `process.env` instead of a secret manager loaded into memory
- Config parsed lazily or per-request rather than once at boot
- Long-lived static credentials where rotating/ephemeral ones are available
- No secret scanning step in CI

## Verification

- [ ] Entire config is validated once at startup and the process exits on failure
- [ ] No required value has a fallback default
- [ ] Config is injected through `deps`, never re-read from `process.env` mid-request
- [ ] Secrets come from a secret manager into memory with `preventProcessEnvWrite`
- [ ] Config type is derived via `z.infer<typeof Schema>` (or the resolver's inferred type)
- [ ] Tests inject mock resolvers / config objects instead of mutating env
- [ ] CI runs secret scanning over full git history
