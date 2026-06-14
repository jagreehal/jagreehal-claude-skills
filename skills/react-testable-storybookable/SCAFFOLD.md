# Scaffold: Harness Boilerplate

Copy-paste setup files for the [react-testable-storybookable](SKILL.md) recipe. Create these once per project; everything else is per-component. Paths assume a `@/` alias to `src/`.

## `src/test/utils.tsx`: renderWithProviders

```tsx
import { render } from "@testing-library/react";
import { BrowserRouter } from "react-router-dom";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { RenderOptions } from "@testing-library/react";
import type { ReactElement } from "react";
import { ThemeProvider } from "@/providers/ThemeProvider";

// retries off so error tests fail fast and deterministically
const queryClient = new QueryClient({
  defaultOptions: { queries: { retry: false }, mutations: { retry: false } },
});

function AllTheProviders({ children }: { children: React.ReactNode }) {
  return (
    <ThemeProvider attribute="class" defaultTheme="light" storageKey="app-theme">
      <QueryClientProvider client={queryClient}>
        <BrowserRouter>{children}</BrowserRouter>
      </QueryClientProvider>
    </ThemeProvider>
  );
}

export function renderWithProviders(
  ui: ReactElement,
  options?: Omit<RenderOptions, "wrapper">,
) {
  return render(ui, { wrapper: AllTheProviders, ...options });
}

// re-export RTL so tests import everything from one place
export * from "@testing-library/react";
```

## `src/msw/fixtures.ts`: shared data

```ts
import type { Todo } from "@/types";

// imported by BOTH stories and tests — single source of truth for sample data
export const defaultTodos: Todo[] = [
  { id: "1", title: "Learn React", completed: true,  createdAt: "2024-01-01T00:00:00Z" },
  { id: "2", title: "Build app",   completed: false, createdAt: "2024-01-02T00:00:00Z" },
  { id: "3", title: "Write tests", completed: false, createdAt: "2024-01-03T00:00:00Z" },
];

export function createTodo(overrides: Partial<Todo> = {}): Todo {
  const now = new Date().toISOString();
  return {
    id: overrides.id ?? `td-${Date.now()}-${Math.random().toString(36).slice(2, 9)}`,
    title: overrides.title ?? "New todo",
    completed: overrides.completed ?? false,
    createdAt: overrides.createdAt ?? now,
    ...overrides,
  };
}
```

## `src/msw/handlers.ts`: handlers with failure injection

```ts
import { HttpResponse, delay, http } from "msw";
import { createTodo, defaultTodos } from "./fixtures";
import type { Todo } from "@/types";

const API = "/api";

// resettable in-memory store, so each test/story starts from a known baseline
let store: Todo[] = [...defaultTodos];
export function resetTodoStore() { store = [...defaultTodos]; }
export function setTodoStore(todos: Todo[]) { store = [...todos]; }

type Scenario = "default" | "listError" | "addError" | "updateError" | "deleteError";

// Force a failure WITHOUT writing separate handlers:
//   GET /api/todos?fail=list         → 500
//   request header x-mock-error: add → 500
//   createTodoHandlers({ scenario: "updateError" })
function shouldFail(req: Request, key: string, scenario: Scenario): boolean {
  const url = new URL(req.url);
  return url.searchParams.get("fail") === key
    || req.headers.get("x-mock-error") === key
    || scenario === `${key}Error`;
}

export function createTodoHandlers(opts?: { delayMs?: number; scenario?: Scenario }) {
  const scenario = opts?.scenario ?? "default";
  const wait = () => delay(opts?.delayMs ?? 100);

  return [
    http.get(`${API}/todos`, async ({ request }) => {
      await wait();
      if (shouldFail(request, "list", scenario))
        return HttpResponse.json({ error: { message: "Failed to load" } }, { status: 500 });
      return HttpResponse.json({ items: store, total: store.length });
    }),
    http.post(`${API}/todos`, async ({ request }) => {
      await wait();
      if (shouldFail(request, "add", scenario))
        return HttpResponse.json({ error: { message: "Failed to add" } }, { status: 500 });
      const { title } = (await request.json()) as { title: string };
      const todo = createTodo({ title });
      store = [...store, todo];
      return HttpResponse.json(todo, { status: 201 });
    }),
    http.patch(`${API}/todos/:id`, async ({ request, params }) => {
      await wait();
      if (shouldFail(request, "update", scenario))
        return HttpResponse.json({ error: { message: "Failed to update" } }, { status: 500 });
      const i = store.findIndex((t) => t.id === params.id);
      if (i === -1) return HttpResponse.json({ error: { message: "Not found" } }, { status: 404 });
      const patch = (await request.json()) as Partial<Todo>;
      store = store.map((t) => (t.id === params.id ? { ...t, ...patch } : t));
      return HttpResponse.json(store[i]);
    }),
    http.delete(`${API}/todos/:id`, async ({ request, params }) => {
      await wait();
      if (shouldFail(request, "delete", scenario))
        return HttpResponse.json({ error: { message: "Failed to delete" } }, { status: 500 });
      store = store.filter((t) => t.id !== params.id);
      return new HttpResponse(null, { status: 204 });
    }),
  ];
}

export const todoHandlers = createTodoHandlers();
```

## `src/msw/server.ts` and `browser.ts`

```ts
// server.ts — Node (Vitest)
import { setupServer } from "msw/node";
import { todoHandlers } from "./handlers";
export const server = setupServer(...todoHandlers);

// browser.ts — browser (Storybook + dev)
import { setupWorker } from "msw/browser";
import { todoHandlers } from "./handlers";
export const worker = setupWorker(...todoHandlers);
```

## `src/test/setup.ts`: Vitest global setup

```ts
import "@testing-library/jest-dom/vitest";
import { afterAll, afterEach, beforeAll } from "vitest";
import { server } from "@/msw/server";
import { resetTodoStore } from "@/msw/handlers";

beforeAll(() => server.listen({ onUnhandledRequest: "error" }));
afterEach(() => { server.resetHandlers(); resetTodoStore(); });
afterAll(() => server.close());
```

Wire it in `vitest.config.ts`: `test: { environment: "jsdom", setupFiles: ["src/test/setup.ts"] }`.

## `.storybook/preview.tsx`: global decorators

```tsx
import type { Preview } from "@storybook/react";
import { useEffect } from "react";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { ThemeProvider } from "@/providers/ThemeProvider";

const queryClient = new QueryClient();

function withMSW(Story: () => React.ReactNode) {
  useEffect(() => {
    import("@/msw/browser").then(({ worker }) =>
      worker.start({ onUnhandledRequest: "bypass", quiet: true }),
    );
  }, []);
  return <Story />;
}

function withProviders(Story: () => React.ReactNode) {
  return (
    <ThemeProvider attribute="class" defaultTheme="light" storageKey="app-theme">
      <QueryClientProvider client={queryClient}>
        <Story />
      </QueryClientProvider>
    </ThemeProvider>
  );
}

const preview: Preview = {
  decorators: [withMSW, withProviders],
  parameters: { controls: { matcher: /^on[A-Z]|^aria/ } },
};
export default preview;
```

## Test-Only Provider

When a component reads from a context, implement the **same context interface** as the real provider but drive it from props. This lets stories and tests force any state without a network call.

Define the contract once as a generic `state` / `actions` / `meta` interface (the DI shape from `vercel-composition-patterns`). Both the real provider and the test provider implement it, so the compiler (not discipline) guarantees they never drift:

```tsx
import { useCallback } from "react";
import { TodoContextProvider } from "./TodoContext";
import type { ReactNode } from "react";
import type { Todo } from "@/types";
import type { ListStatus } from "@/state/noReactQuery/useTodos";
import type { Result } from "@/types"; // ok/error union — see result-types

// The one contract. Export from TodoContext and have BOTH providers implement it.
export interface TodoContextValue {
  state: { todos: Todo[]; status: ListStatus; error: { message: string } | null };
  actions: {
    addTodo: (p: { title: string }) => Promise<Result<Todo>>;
    deleteTodo: (id: string) => Promise<Result<void>>;
  };
  meta: { isRefetching: boolean };
}

export interface TodoTestProviderProps {
  children: ReactNode;
  initialTodos?: Todo[];
  isLoading?: boolean;
  error?: string | null;
  actions?: {           // spies for asserting interactions (pass fn() in stories)
    addTodo?: (p: { title: string }) => void;
    deleteTodo?: (id: string) => void;
  };
}

export function TodoTestProvider({
  children, initialTodos = [], isLoading = false, error = null, actions,
}: TodoTestProviderProps) {
  const addTodo = useCallback(async (p: { title: string }) => {
    actions?.addTodo?.(p);
    return { ok: true as const, data: { id: `mock-${Date.now()}`, ...p, completed: false } };
  }, [actions]);

  const deleteTodo = useCallback(async (id: string) => {
    actions?.deleteTodo?.(id);
    return { ok: true as const, data: undefined };
  }, [actions]);

  // typed against the shared contract — a missing field is a compile error, not a runtime surprise
  const value: TodoContextValue = {
    state: {
      todos: initialTodos,
      status: (isLoading ? "loading" : error ? "error" : "success") as ListStatus,
      error: error ? { message: error } : null,
    },
    actions: { addTodo, deleteTodo },
    meta: { isRefetching: false },
  };

  return <TodoContextProvider value={value}>{children}</TodoContextProvider>;
}
```

**Why the shared interface matters:** if the test provider's value shape drifts from the real one, components render fine in stories/tests but break in production (or vice versa). Typing both against one `TodoContextValue` makes drift a compile error.

## Container test against real hooks + MSW

When you want to exercise the actual fetch path rather than force state:

```tsx
import { renderWithProviders, screen, waitFor } from "@/test/utils";

it("loads and shows todos from the API", async () => {
  renderWithProviders(<TodoListContainer />);          // uses real useTodosQuery
  await waitFor(() => expect(screen.getByText("Learn React")).toBeInTheDocument());
});

it("shows the error state when the list request fails", async () => {
  // failure injection: point the container's fetch at the failing scenario,
  // or override the handler for this test
  server.use(...createTodoHandlers({ scenario: "listError" }));
  renderWithProviders(<TodoListContainer />);
  await waitFor(() => expect(screen.getByRole("alert")).toBeInTheDocument());
});
```
