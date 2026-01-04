---
argument-hint: <function-name> [description]
description: Scaffold a new function following the fn(args, deps) pattern with Result types
---

Create a new TypeScript function named `$ARGUMENTS` following the jagreehal-claude-skills patterns.

## Instructions

Replace the following placeholders in all generated files:
- `FUNCTION_NAME` → The function name in camelCase (e.g., `getUser`)
- `FunctionName` → The function name in PascalCase (e.g., `GetUser`)
- `function-name` → The function name in kebab-case (e.g., `get-user`)

## Files to Generate

### 1. Function File (`src/domain/function-name.ts`)

```typescript
import type { Result } from '@jagreehal/workflow';
import { ok, err } from '@jagreehal/workflow';

// Args: per-call input data
export type FunctionNameArgs = {
  // TODO: Define args based on function purpose
  id: string;
};

// Deps: injected collaborators (things you'd mock in tests)
export type FunctionNameDeps = {
  // TODO: Define deps (db, logger, external services)
  db: Database;
  logger: Logger;
};

// Explicit error types in the signature
export type FunctionNameError = 'NOT_FOUND' | 'DB_ERROR';

export async function FUNCTION_NAME(
  args: FunctionNameArgs,
  deps: FunctionNameDeps
): Promise<Result<unknown, FunctionNameError>> {
  deps.logger.debug('FUNCTION_NAME called', { args });

  try {
    // TODO: Implement business logic
    const result = await deps.db.find(args.id);

    if (!result) {
      return err('NOT_FOUND');
    }

    return ok(result);
  } catch (error) {
    deps.logger.error('FUNCTION_NAME failed', {
      args,
      error: error instanceof Error ? error.message : String(error),
    });
    return err('DB_ERROR');
  }
}
```

### 2. Test File (`src/domain/function-name.test.ts`)

```typescript
import { describe, it, expect } from 'vitest';
import { mock } from 'vitest-mock-extended';
import { FUNCTION_NAME, type FunctionNameDeps } from './function-name';

describe('FUNCTION_NAME', () => {
  it('returns ok with result when found', async () => {
    // Arrange
    const mockResult = { id: '123', name: 'Test' };
    const deps = mock<FunctionNameDeps>();
    deps.db.find.mockResolvedValue(mockResult);

    // Act
    const result = await FUNCTION_NAME({ id: '123' }, deps);

    // Assert
    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.value).toEqual(mockResult);
    }
  });

  it('returns err NOT_FOUND when not found', async () => {
    // Arrange
    const deps = mock<FunctionNameDeps>();
    deps.db.find.mockResolvedValue(null);

    // Act
    const result = await FUNCTION_NAME({ id: '123' }, deps);

    // Assert
    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.error).toBe('NOT_FOUND');
    }
  });

  it('returns err DB_ERROR on database failure', async () => {
    // Arrange
    const deps = mock<FunctionNameDeps>();
    deps.db.find.mockRejectedValue(new Error('Connection failed'));

    // Act
    const result = await FUNCTION_NAME({ id: '123' }, deps);

    // Assert
    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.error).toBe('DB_ERROR');
    }
  });
});
```

## Patterns to Follow

- **fn(args, deps)** - Two parameters: per-call data and injected collaborators
- **Result<T, E>** - Never throw for expected failures, return err()
- **Explicit deps type** - Each function declares only what it needs
- **import type** - Use type-only imports for interfaces
- **vitest-mock-extended** - Use `mock<DepsType>()` for typed mocks

## After Scaffolding

1. Update the deps type to match actual dependencies
2. Update the args type for function parameters
3. Update error types to match domain failures
4. Implement the actual business logic
5. Run tests: `npm test`
