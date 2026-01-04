---
description: Initialize a TypeScript project with jagreehal-claude-skills patterns (tsconfig, eslint, dependencies)
---

Set up a TypeScript project following jagreehal-claude-skills patterns.

## Steps

### 1. Install Core Dependencies

```bash
# TypeScript and type utilities
npm install -D typescript @types/node
npm install -D @total-typescript/ts-reset type-fest

# Testing
npm install -D vitest vitest-mock-extended @faker-js/faker

# Linting
npm install -D eslint @eslint/js @typescript-eslint/eslint-plugin @typescript-eslint/parser
npm install -D eslint-plugin-prefer-object-params globals

# Build tools
npm install -D dotenv vite-tsconfig-paths

# Runtime dependencies
npm install zod
npm install @jagreehal/workflow autotel pino node-env-resolver
```

### 2. Create tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2024",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "verbatimModuleSyntax": true,
    "erasableSyntaxOnly": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedSideEffectImports": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "outDir": "dist",
    "rootDir": "src"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### 3. Create reset.d.ts

```typescript
import "@total-typescript/ts-reset";
```

### 4. Create eslint.config.mjs

```javascript
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
      'no-restricted-imports': ['error', {
        patterns: [{
          group: ['**/infra/**'],
          message: 'Domain code must not import from infra.',
        }],
      }],
      'prefer-object-params/prefer-object-params': 'error',
      '@typescript-eslint/no-unused-vars': ['error', { argsIgnorePattern: '^_' }],
      'prefer-const': 'error',
      'no-var': 'error',
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

### 5. Create vitest.config.ts

```typescript
import { defineConfig } from 'vitest/config';
import tsconfigPaths from 'vite-tsconfig-paths';

export default defineConfig({
  plugins: [tsconfigPaths()],
  test: {
    globals: true,
    environment: 'node',
    setupFiles: ['./vitest.setup.ts'],
    include: ['src/**/*.test.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
    },
  },
});
```

### 6. Create vitest.setup.ts

```typescript
import { beforeAll, afterEach, vi } from 'vitest';

// Database guardrails - prevent tests hitting production
const DB_URL = process.env.DATABASE_URL || '';
if (DB_URL && !DB_URL.includes('localhost') && !DB_URL.includes('127.0.0.1')) {
  throw new Error(`Tests must use localhost database. Got: ${DB_URL}`);
}

// Reset mocks between tests
afterEach(() => {
  vi.clearAllMocks();
});
```

### 7. Create Directory Structure

```
project-root/
├── src/
│   ├── domain/         # Business logic (pure functions)
│   ├── infra/          # Infrastructure (db, http, cache)
│   ├── api/            # HTTP handlers (composition root)
│   ├── workflows/      # Workflow compositions
│   └── shared/         # Shared types and utilities
├── reset.d.ts          # ts-reset types
├── vitest.config.ts    # Test configuration
├── vitest.setup.ts     # Test setup
├── tsconfig.json
└── eslint.config.mjs
```

### 8. Add npm Scripts

```json
{
  "scripts": {
    "build": "tsc",
    "type-check": "tsc --noEmit",
    "lint": "eslint src",
    "lint:fix": "eslint src --fix",
    "test": "vitest run",
    "test:watch": "vitest"
  }
}
```
