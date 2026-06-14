---
name: pattern-enforcement
description: Enforces architectural patterns at build time with ESLint so violations fail CI instead of relying on convention. Use when configuring eslint.config.mjs, blocking domain code from importing infra, requiring object parameters, preventing server code from leaking into client bundles, choosing ESLint plugins (boundaries, prefer-object-params, no-server-imports), or constraining AI-generated code.
version: 1.1.0
libraries: ["eslint-plugin-boundaries", "eslint-plugin-prefer-object-params", "eslint-plugin-no-server-imports"]
---

# Pattern Enforcement

## Overview

Documentation is a ritual; rules are enforcement. A pattern that lives only in a README or a CLAUDE.md is a suggestion: the next contributor (human or agent) will skip it the moment it's inconvenient, and nothing stops them. The only patterns that survive are the ones that fail the build.

This skill encodes architectural intent as ESLint rules set to `'error'`: domain code cannot import infrastructure, functions take object parameters instead of positional ones, and server-only code cannot reach client bundles. This matters doubly for AI-generated code. Prompting is probabilistic (the agent might follow the pattern, might not), while a failing lint rule is deterministic (lint fails, the agent fixes it). Constrain agents with the same systems you already trust: linters, types, tests, and CI.

## When to Use

- Setting up or extending `eslint.config.mjs` for a TypeScript project
- Enforcing layered architecture (domain / infra / api boundaries)
- Requiring the `fn(args, deps)` object-parameter convention across a codebase
- Preventing server imports or Node.js modules from reaching client code
- Constraining AI/agent contributions so deviations fail CI
- Migrating an existing codebase onto these patterns incrementally

**When NOT to use:** compiler-level type safety (flags, `any`/`as` bans) belongs in [`strict-typescript`](../strict-typescript/SKILL.md); runtime input checks belong in [`validation-boundary`](../validation-boundary/SKILL.md). ESLint enforces *structure*, not *values*.

**Related:** [`strict-typescript`](../strict-typescript/SKILL.md) (compile-time enforcement and `@typescript-eslint`), [`fn-args-deps`](../fn-args-deps/SKILL.md) (the object-param / DI pattern these rules enforce), [`config-management`](../config-management/SKILL.md), [`api-design`](../api-design/SKILL.md).

## Required ESLint Rules

### 1. Enforce Architectural Boundaries

Domain code must NOT import from infrastructure:

```typescript
// WRONG
import { db } from '../infra/database';

// CORRECT - Inject dependency
async function getUser(args, deps: { db: Database }) {
  return deps.db.findUser(args.userId);
}
```

**Simple approach** - Use `no-restricted-imports`:

```javascript
// eslint.config.mjs
export default {
  rules: {
    "no-restricted-imports": [
      "error",
      {
        patterns: [{
          group: ["**/infra/**"],
          message: "Domain code must not import from infra. Inject dependencies instead.",
        }],
      },
    ],
  },
};
```

**Better approach** - Use `eslint-plugin-boundaries` for directional rules:

```bash
npm install -D eslint-plugin-boundaries
```

```javascript
import boundaries from 'eslint-plugin-boundaries';

export default [{
  plugins: { boundaries },
  settings: {
    'boundaries/elements': [
      { type: 'domain', pattern: 'src/domain/**' },
      { type: 'infra', pattern: 'src/infra/**' },
      { type: 'api', pattern: 'src/api/**' },
    ],
  },
  rules: {
    'boundaries/element-types': ['error', {
      default: 'disallow',
      rules: [
        { from: 'domain', allow: ['domain'] },              // Domain is pure
        { from: 'infra', allow: ['domain', 'infra'] },      // Infra implements domain
        { from: 'api', allow: ['domain', 'infra', 'api'] }, // API wires everything
      ],
    }],
  },
}];
```

### 2. Enforce Function Signatures

Functions should use object parameters, not positional:

```typescript
// WRONG - Positional parameters
function createUser(name: string, email: string, age: number) { }

// CORRECT - Object parameter
function createUser(args: { name: string; email: string; age: number }) { }
```

```bash
npm install -D eslint-plugin-prefer-object-params
```

```javascript
import preferObjectParams from 'eslint-plugin-prefer-object-params';

export default [{
  plugins: { 'prefer-object-params': preferObjectParams },
  rules: {
    'prefer-object-params/prefer-object-params': 'error',
  },
}];
```

Rule ignores single-parameter functions, constructors, and test files by default.

### 3. Enforce Server/Client Boundaries

Prevent server code from leaking to client bundles:

```bash
npm install -D eslint-plugin-no-server-imports
```

```javascript
import noServerImports from 'eslint-plugin-no-server-imports';

export default [{
  plugins: { 'no-server-imports': noServerImports },
  rules: {
    'no-server-imports/no-server-imports': ['error', {
      serverFilePatterns: [
        '**/*.server.ts',
        '**/*.server.tsx',
        '**/server/**',
        '**/api/**',
      ],
    }],
  },
}];
```

Also block Node.js modules in client code:

```javascript
export default [{
  files: ['src/components/**/*.tsx', 'src/hooks/**/*.ts'],
  rules: {
    'import/no-nodejs-modules': ['error', { allow: [] }],
  },
}];
```

## Complete ESLint Config

```javascript
// eslint.config.mjs
import js from '@eslint/js';
import tseslint from '@typescript-eslint/eslint-plugin';
import tsparser from '@typescript-eslint/parser';
import preferObjectParams from 'eslint-plugin-prefer-object-params';
import globals from 'globals';

export default [
  js.configs.recommended,
  {
    files: ['**/*.{ts,tsx}'],
    languageOptions: {
      parser: tsparser,
      parserOptions: {
        ecmaVersion: 2022,
        sourceType: 'module',
        project: './tsconfig.json',
      },
      globals: { ...globals.node, ...globals.es2022 },
    },
    plugins: {
      '@typescript-eslint': tseslint,
      'prefer-object-params': preferObjectParams,
    },
    rules: {
      ...tseslint.configs.recommended.rules,

      // Architectural boundaries
      'no-restricted-imports': ['error', {
        patterns: [{
          group: ['**/infra/**'],
          message: 'Domain code must not import from infra.',
        }],
      }],

      // Function signatures
      'prefer-object-params/prefer-object-params': 'error',

      // TypeScript
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      '@typescript-eslint/no-explicit-any': 'warn',

      // Code quality
      'prefer-const': 'error',
      'no-var': 'error',
      'object-shorthand': 'error',
      'prefer-template': 'error',
    },
  },
  {
    files: ['**/*.test.ts', '**/*.spec.ts'],
    rules: {
      'prefer-object-params/prefer-object-params': 'off',
    },
  },
];
```

## Essential Plugins

| Plugin | Purpose |
|--------|---------|
| `@typescript-eslint/eslint-plugin` | TypeScript-aware rules |
| `eslint-plugin-import` | Broken imports, circular deps |
| `eslint-plugin-unused-imports` | Auto-remove dead imports |
| `eslint-plugin-unicorn` | Modern, safer patterns |
| `eslint-plugin-boundaries` | Architectural boundaries |
| `eslint-plugin-prefer-object-params` | Object parameters |

## Migrating Existing Codebases

The `prefer-object-params` rule currently reports violations but doesn't auto-fix them (the transformation is too complex for safe automation, since call sites need updating too).

For large-scale migrations, consider:

1. **Incremental adoption:** Start with `'warn'` and fix violations file-by-file
2. **Codemod scripts:** Use [jscodeshift](https://github.com/facebook/jscodeshift) to automate the transformation:

```javascript
// transform-to-object-params.js (jscodeshift)
export default function transformer(file, api) {
  const j = api.jscodeshift;
  // Transform function declarations with 2+ params to object pattern
  // ... (custom logic for your codebase)
}
```

```bash
npx jscodeshift -t transform-to-object-params.js src/**/*.ts
```

3. **AI-assisted refactoring:** Modern coding agents can batch-refactor functions when given clear rules

The key is that the ESLint rule *catches* violations. The migration strategy is separate from enforcement.

## Why Rules Matter for AI-Generated Code

Prompting is probabilistic - AI might follow patterns, might not.
Rules are deterministic - lint fails, code fails, agent fixes.

> If AI is writing code in your repo, constrain it with the same systems you already trust: linters, types, tests, and CI checks.

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "The pattern is documented in CLAUDE.md, that's enough" | Documentation is opt-in. The next agent ignores it without consequence. A failing rule is mandatory. |
| "I'll set it to `'warn'` so it doesn't block anyone" | Warnings are noise everyone scrolls past. If the pattern matters, it's `'error'`. |
| "ESLint boundaries are too strict for our app" | Then your layering is unclear, not the rule. Define the elements explicitly and the rule documents the architecture. |
| "Positional params are fine for two arguments" | Two becomes five. Object params make every call site self-documenting and refactor-safe from day one. |
| "We can't migrate the whole codebase at once" | Adopt incrementally (`'warn'` then fix file-by-file, or codemod), but keep the rule on so new violations can't land. |
| "The AI usually follows the pattern" | "Usually" is probabilistic. A lint error makes it deterministic: lint fails, agent fixes. |

## Red Flags

- Architectural patterns that exist only in docs, with no lint rule backing them
- ESLint rules set to `'warn'` for patterns that are supposed to be mandatory
- `import` of `../infra/**` from inside `src/domain/**`
- Functions with three or more positional parameters
- Server-only modules imported into components/hooks, or `import/no-nodejs-modules` absent from client globs
- CI that does not run `eslint` (or runs it with `--quiet`, swallowing warnings)

## Verification

- [ ] `eslint.config.mjs` defines `boundaries/elements` and enforces directional `element-types`
- [ ] `prefer-object-params` is enabled (off only for test files)
- [ ] Server/client separation is enforced via `no-server-imports` and `import/no-nodejs-modules` on client globs
- [ ] Every enforcement rule is `'error'`, not `'warn'`
- [ ] CI fails on any ESLint error
- [ ] Migration of existing violations has a tracked plan (codemod or incremental fix), with the rule already on for new code
