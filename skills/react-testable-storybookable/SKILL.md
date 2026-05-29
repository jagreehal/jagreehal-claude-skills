---
name: react-testable-storybookable
description: Makes React components testable and storybookable by enforcing one property: components depend only on props and injectable context, never on API, router, or globals, so a story and a test come almost for free. Use when building or refactoring a component and you want a matching story and test, setting up renderWithProviders or a test-only provider, sharing one MSW handler/fixture set across Vitest + Storybook + dev, or writing React Query hooks with a key factory that surface explicit status.
version: 1.0.0
libraries: ["@tanstack/react-query", "msw", "@storybook/test", "@testing-library/react", "vitest"]
---

# React Testable & Storybookable

## Overview

Testability and storybookability are **the same property, not two chores.** A component that depends only on its props and on context you can inject is both: a test passes props (or wraps it in a provider) and asserts output; a story passes the same props (or the same provider decorator) and renders it in isolation. The moment a component reaches for the network, the router, or a global store you cannot override, it stops being either.

So the work is never "add tests and stories" after the fact. You keep one rule while you build, then the test and the story fall out of it. This skill is the concrete recipe: prop-driven components, hooks that surface explicit status, one MSW handler set shared everywhere, a `renderWithProviders` helper, a test-only provider for forcing states, and the file trio that ties them together.

## When to Use

- Building or refactoring a React component you want to test and demo in Storybook
- Setting up the test harness: `renderWithProviders`, a test-only provider, shared MSW handlers + fixtures
- Writing React Query hooks (a key factory, query/mutation hooks) that surface `loading`/`error`/`success`
- Making an existing component testable when it currently imports the API or router directly
- Scaffolding the `Component.tsx` + `Component.stories.tsx` + `Component.test.tsx` trio

**When NOT to use:** Page-level *flow* demos (signup → checkout) belong in [storybook-journeys](../storybook-journeys/SKILL.md). Visual/spacing/type decisions belong in [ui-design-principles](../ui-design-principles/SKILL.md). The broader portability/Container-View architecture is [react-development](../react-development/SKILL.md); this skill is the per-component testing+story recipe that sits on top of it.

**Related:** [react-development](../react-development/SKILL.md) (Container/View split and DI this builds on), [storybook-journeys](../storybook-journeys/SKILL.md) (flow-level stories), [result-types](../result-types/SKILL.md) (the `Result<T>` the hooks return), [testing-strategy](../testing-strategy/SKILL.md) (where these tests sit in the pyramid), [validation-boundary](../validation-boundary/SKILL.md) (parsing API responses).

**Vercel alignment:** the injectable context here uses the generic `state`/`actions`/`meta` contract from `vercel-composition-patterns` (so any provider, real or test, implements one interface). Once a component is testable and storybookable, run the performance pass with `vercel-react-best-practices` (waterfalls, bundle size, re-renders). Prefer explicit variant components over boolean props, per `vercel-composition-patterns`.

Full copy-paste boilerplate for every harness file lives in [SCAFFOLD.md](SCAFFOLD.md). A generator for the file trio is bundled at `scripts/scaffold-component.sh`.

## The Core Rule

> A component may depend on **props** and on **context you can inject in a test or story**. It may not depend on the network, the router, or a global store you cannot override.

Everything below follows from this one rule.

## Component Tiers

| Tier | Depends on | Test with | Story with |
|------|-----------|-----------|-----------|
| **Leaf / presentational** | props only | props + assert output/events | `args` (use `fn()` for handlers) |
| **Container** | hooks/context + props | `renderWithProviders` + MSW (real hooks) | `withProviders` + `withMSW` decorators |
| **Provider / boundary** | children + injected value | wrap in the provider, assert children | decorator that supplies the value |

The leaf tier is where most components should live. Push data-fetching up into a thin container so the part that renders stays prop-driven.

## Prop-Driven Components

Keep API and router out of the component. Pass data and callbacks in.

```tsx
// WRONG — fetches and navigates itself: can't render in Storybook, needs a backend to test
function TodoList() {
  const { data } = useTodosQuery();          // network
  const navigate = useNavigate();            // router
  return <ul>{data?.map((t) => <li key={t.id} onClick={() => navigate(`/todo/${t.id}`)}>{t.title}</li>)}</ul>;
}

// CORRECT — props in, callbacks out: a story passes args, a test passes props
export interface TodoListProps {
  todos: Todo[];
  onToggle: (id: string, completed: boolean) => void | Promise<unknown>;
  onDelete: (id: string) => void | Promise<unknown>;
  updatingId?: string | null;
  errorById?: Record<string, string> | null;
}

export function TodoList({ todos, onToggle, onDelete, updatingId, errorById }: TodoListProps) {
  return (
    <ul role="list" aria-label="Todo list">
      {todos.map((todo) => (
        <TodoItem key={todo.id} todo={todo} onToggle={onToggle} onDelete={onDelete}
          isUpdating={updatingId === todo.id} error={errorById?.[todo.id]} />
      ))}
    </ul>
  );
}
```

The container that owns the data is thin and lives next to it. See [react-development](../react-development/SKILL.md) for the Container/View split.

## State Hooks: Explicit Status

Hooks surface an explicit status union so every consumer can render loading, error, empty, and success deterministically, with no implicit "data is undefined, probably loading".

```tsx
export type ListStatus = "idle" | "loading" | "success" | "error";
```

With React Query, let the key factory own cache identity and let the hook throw on a failed `Result` so Query owns the error state:

```ts
// keys.ts — one source of truth for cache keys and invalidation
export const todoKeys = {
  all: ["todos"] as const,
  lists: () => [...todoKeys.all, "list"] as const,
  list: (page: number, limit: number) => [...todoKeys.lists(), { page, limit }] as const,
};

// useTodosQuery.ts — thin: unwrap the Result, throw on error, return data
export function useTodosQuery(page = 1, limit = 100) {
  return useQuery({
    queryKey: todoKeys.list(page, limit),
    queryFn: async () => {
      const result = await fetchTodosOffset(page, limit);   // returns Result<T> — see result-types
      if (!result.ok) throw new Error(result.error.message);
      return result.data;
    },
  });
}

// mutations invalidate through the same factory
export function useAddTodoMutation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (title: string) => addTodo(title),
    onSuccess: () => qc.invalidateQueries({ queryKey: todoKeys.all }),
  });
}
```

The data layer returns `Result<T>` ([result-types](../result-types/SKILL.md)); the hook is the one place that converts a failed Result into a thrown error for React Query. A Context-based hook (no React Query) surfaces the *same* `ListStatus` shape, so components don't care which strategy backs them.

## One MSW Set, Shared Everywhere

Define handlers and fixtures **once**. The same set backs Vitest, Storybook, and the dev server, so a "loading" or "error" state looks identical in all three.

- `msw/fixtures.ts`: `defaultTodos` and a `createTodo(overrides)` factory. **Stories and tests import these same fixtures**, so they never drift.
- `msw/handlers.ts`: handlers over a resettable in-memory store, with **failure injection** so error states are first-class:

```ts
// trigger a failure from a story/test without separate handlers:
//   GET /api/todos?fail=list      → 500
//   header x-mock-error: update   → 500
//   createTodoHandlers({ scenario: "deleteError" })
```

Reset the store between tests (`resetTodoStore()`), so each test starts from the same baseline. Full handler/fixture/server/browser files are in [SCAFFOLD.md](SCAFFOLD.md).

## renderWithProviders (test harness)

One helper wraps the tree in the providers a real component needs: theme, router, and a `QueryClient` with retries off (so error tests fail fast and deterministically):

```tsx
const queryClient = new QueryClient({
  defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
});

function AllTheProviders({ children }: { children: React.ReactNode }) {
  return (
    <ThemeProvider attribute="class" defaultTheme="light">
      <QueryClientProvider client={queryClient}>
        <BrowserRouter>{children}</BrowserRouter>
      </QueryClientProvider>
    </ThemeProvider>
  );
}

export function renderWithProviders(ui: ReactElement, options?: Omit<RenderOptions, "wrapper">) {
  return render(ui, { wrapper: AllTheProviders, ...options });
}
export * from "@testing-library/react";   // re-export screen, within, etc.
```

A leaf test then needs no providers at all; it passes props:

```tsx
it("renders the todos", () => {
  renderWithProviders(<TodoList todos={defaultTodos} onToggle={() => {}} onDelete={() => {}} />);
  expect(screen.getByRole("list")).toBeInTheDocument();
  expect(screen.getByText("Learn React")).toBeInTheDocument();
});
```

## Test-Only Provider (force states)

For components that read from context, a test-only provider lets you force `loading`/`error`/`success` and capture actions without a network round-trip. It implements the **same context interface** as the real provider but takes its state from props.

Define that interface once as a generic `state` / `actions` / `meta` contract (the dependency-injection shape from `vercel-composition-patterns`), so the compiler guarantees the real and test providers never drift:

```ts
export interface TodoContextValue {
  state: { todos: Todo[]; status: ListStatus; error: { message: string } | null };
  actions: { addTodo: (p: { title: string }) => Promise<Result<Todo>>; deleteTodo: (id: string) => Promise<Result<void>> };
  meta: { isRefetching: boolean };
}
```

Both providers implement `TodoContextValue`; the test one fills it from props:

```tsx
<TodoTestProvider initialTodos={defaultTodos} isLoading>      {/* force loading */}
  <TodoScreen />
</TodoTestProvider>

<TodoTestProvider error="Failed to load">                    {/* force error  */}
  <TodoScreen />
</TodoTestProvider>
```

Use this for stories and tests of containers/screens; use real hooks + MSW when you want to exercise the fetch path. Full implementation in [SCAFFOLD.md](SCAFFOLD.md).

## The Component Trio

Every component ships as three files in one folder. Stories and tests import the **same fixtures**, so a change to the data shape breaks both at once.

```
TodoList.tsx            # prop-driven component
TodoList.stories.tsx    # Default + Empty + Error/Loading states; fn() for handlers
TodoList.test.tsx       # renderWithProviders, assert output and events
```

```tsx
// TodoList.stories.tsx — states are stories, handlers are spies
import type { Meta, StoryObj } from "@storybook/react";
import { fn } from "@storybook/test";
import { TodoList, type TodoListProps } from "./TodoList";
import { defaultTodos } from "@/msw/fixtures";

// Type the stories from the component's EXPORTED props type — not `typeof TodoList`.
// One Story alias, reused by every state. Cleaner, and it surfaces the real
// prop contract instead of an inferred component shape.
const meta: Meta<TodoListProps> = { title: "Todo/TodoList", component: TodoList };
export default meta;

type Story = StoryObj<TodoListProps>;

export const Default: Story = { args: { todos: defaultTodos, onToggle: fn(), onDelete: fn() } };
export const Empty: Story = { args: { ...Default.args, todos: [] } };
export const WithError: Story = { args: { ...Default.args, errorById: { "2": "Failed to save" } } };
```

**Export the props type, type the stories from it.** Every component exports its `Props` interface; stories and tests import that exported type and reference it (`Meta<TodoListProps>`, `StoryObj<TodoListProps>`) rather than `typeof Component`. The prop contract is the source of truth; `typeof` only re-derives it indirectly.

Scaffold the trio with: `scripts/scaffold-component.sh <ComponentName> [target-dir]`.

## Storybook Setup

`preview.tsx` applies the same providers and MSW globally, so individual stories stay clean:

```tsx
const preview: Preview = {
  decorators: [withMSW, withProviders],   // start MSW worker; wrap in theme + QueryClient
  parameters: { controls: { matcher: /^on[A-Z]|^aria/ } },
};
```

Add `@storybook/addon-a11y` so every story is also an accessibility check. Decorator source in [SCAFFOLD.md](SCAFFOLD.md).

## Red Flags

- A component imports the API client, `fetch`, `useNavigate`/`useRouter`, or a global store directly
- A story can't be written without "first I need a running backend"
- Tests mock `fetch`/modules per file instead of sharing one MSW handler set
- Stories and tests define their own inline data instead of importing shared fixtures
- No error or loading story for a component that fetches, so error paths only show up in production
- `QueryClient` in tests left with retries on (error tests hang or take seconds)
- The test-only provider drifts from the real provider's context shape (only one implements a field)
- A "loading" state that looks different in Storybook than in the app (separate mock paths)

## Verification

For each component:

- [ ] Component depends only on props + injectable context (no API/router/global imports in the leaf)
- [ ] Hook surfaces explicit `idle/loading/success/error` status; React Query hooks use the key factory
- [ ] `Component.tsx` + `Component.stories.tsx` + `Component.test.tsx` all present
- [ ] Stories cover Default, Empty, Loading, and Error; handlers use `fn()`
- [ ] Stories and tests import the **same** `fixtures`
- [ ] Container tests use `renderWithProviders` + shared MSW; error states use failure injection
- [ ] `QueryClient` in the test harness has `retry: false`
- [ ] `resetTodoStore()` (or equivalent) runs between tests
- [ ] Storybook `preview` wires MSW + providers + a11y addon
