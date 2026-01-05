---
name: storybook-journeys
description: Create Storybook "user journey" storyboards for React apps (page/screen stories, MSW API mocking, interaction play functions, and optional Storybook test-runner setup). Use when the user wants Storybook demos of flows (not just atomic components), e.g., signup/login/checkout, with mocked APIs and scripted interactions.
version: 1.0.0
libraries: ["msw", "@storybook/test", "@storybook/addon-interactions", "storybook"]
---

# Storybook Journeys (React + Storybook + MSW)

You are a specialist in turning React apps into **Storybook storyboards** that demonstrate **end-to-end user journeys** inside Storybook:
- “Screen/page” stories (not just small components)
- **Mocked APIs** per story using MSW
- **Interactive flows** using Storybook's `play` function (click/type/wait/assert)
- Optional CI coverage via Storybook Test Runner

## Core principles

1. **Treat journeys as products, not demos.**
   - Prefer **real page/screen composition** + providers (router, query client, auth context) rather than a fake composite.
   - Keep stories deterministic: stable data, stable timers, stable network responses.

2. **Storybook is the "stage", MSW is the "world", play is the "script".**
   - MSW: simulate REST/GraphQL/network states per story (`parameters.msw.handlers`).
   - `play`: simulate user interactions after render.

3. **Each journey needs at least 3 states**
   - Happy path (success)
   - Validation/client error (form errors)
   - Server error / empty state / edge case
   - If the user asks for “storyboard”, structure it as multiple steps or variants.

## When this skill should activate

Use this skill when the user asks for any of:
- “storybook storyboards”
- “user journey stories”
- “flows / journeys in storybook”
- “demo login/signup/checkout inside storybook”
- “MSW fake API in storybook”
- “interaction tests with play function”
- "show a whole page/screen in storybook"

## WRONG vs CORRECT patterns

### WRONG — Testing atomic components in isolation

```tsx
// Button.stories.tsx — misses the journey context
export const Primary: Story = {
  args: { label: 'Submit', variant: 'primary' }
}

export const Loading: Story = {
  args: { label: 'Submit', loading: true }
}
```

This only tests the button's appearance, not how it behaves in a real flow.

### CORRECT — Journey covers the full user flow

```tsx
// SignupJourney.stories.tsx
export const HappyPath: Story = {
  parameters: {
    msw: {
      handlers: [
        http.post('/api/signup', () => HttpResponse.json({ success: true }))
      ]
    }
  },
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement)

    await userEvent.type(canvas.getByLabelText('Email'), 'user@example.com')
    await userEvent.type(canvas.getByLabelText('Password'), 'SecurePass123!')
    await userEvent.click(canvas.getByRole('button', { name: 'Sign Up' }))

    await waitFor(() => {
      expect(canvas.getByText('Welcome!')).toBeInTheDocument()
    })
  }
}
```

### WRONG — Hardcoded test data scattered everywhere

```tsx
// Mocks inline, duplicated across stories
export const Success: Story = {
  parameters: {
    msw: {
      handlers: [
        http.get('/api/user', () => HttpResponse.json({
          id: '123', name: 'John', email: 'john@test.com', role: 'admin'
        }))
      ]
    }
  }
}
```

### CORRECT — Centralized fixtures with typed data

```tsx
// fixtures.ts
export const mockUser: User = {
  id: '123',
  name: 'John Doe',
  email: 'john@example.com',
  role: 'admin'
}

// ProfileJourney.stories.tsx
import { mockUser } from './fixtures'

export const ViewProfile: Story = {
  parameters: {
    msw: {
      handlers: [
        http.get('/api/user', () => HttpResponse.json(mockUser))
      ]
    }
  }
}
```

### WRONG — Brittle CSS selectors

```tsx
play: async ({ canvasElement }) => {
  const submitBtn = canvasElement.querySelector('.btn-primary.submit-form')
  await userEvent.click(submitBtn!)
}
```

### CORRECT — Accessible role/label queries

```tsx
play: async ({ canvasElement }) => {
  const canvas = within(canvasElement)
  await userEvent.click(canvas.getByRole('button', { name: 'Submit' }))
}
```

---

## Minimal discovery (don't get stuck)

If not provided, make best-effort assumptions and proceed, but quickly ask for missing details *only if required to implement*:
- Storybook version and framework (`@storybook/react-vite`, `@storybook/nextjs`, etc.)
- Router (React Router, Next router, none)
- Data client (fetch, axios, RTK Query, TanStack Query, Apollo)
- Whether MSW is already set up

If unknown, default to:
- React
- Storybook CSF (`*.stories.tsx`)
- MSW addon pattern via `parameters.msw.handlers`
- `play` function using `userEvent`, `canvas` queries

## Output expectations

When implementing, produce:
1. One or more Storybook story files for the journey (page-level).
2. MSW handlers per story state (success/fail/edge).
3. A `play` function for at least the happy path.
4. A “Journey Harness” wrapper if needed (providers, router, query client).
5. (Optional) A docs/MDX storyboard page laying out steps in sequence.
6. (Optional) Test-runner wiring so journeys can run in CI.

---

## Recommended folder & naming conventions

Use one of these patterns (pick whichever matches the repo style):

### Option A: Dedicated journeys folder
- `src/stories/journeys/<JourneyName>/<JourneyName>.stories.tsx`
- `src/stories/journeys/<JourneyName>/mocks.ts`
- `src/stories/journeys/<JourneyName>/fixtures.ts`

### Option B: Co-locate with pages
- `src/pages/<RouteOrPage>.journey.stories.tsx`
- `src/pages/<RouteOrPage>.mocks.ts`

Story titles:
- `Journeys/Auth/Signup`
- `Journeys/Checkout/HappyPath`
- `Journeys/Settings/Profile`

Always use `layout: 'fullscreen'` for page journeys unless the user requests otherwise.

---

## Implementation workflow

### Step 1 — Identify the journey boundary

Define:
- Entry screen
- Key actions (click/type/submit/nav)
- Success criteria (what should appear / what route / what API calls)
- Error states to include

If the user provides acceptance criteria, mirror them in story names.

### Step 2 — Build the "Journey Harness" (if needed)

Create a wrapper that can mount the page like the real app:
- Router context (MemoryRouter / Next Router mocks)
- Providers (Theme, Auth, i18n, QueryClient/Apollo)
- Feature flags defaults

Keep the harness reusable and minimal.

### Step 3 — MSW mocks per story

Use Storybook MSW integration via story parameters:
- `parameters: { msw: { handlers: [...] } }`
- Prefer small handler sets per story, avoid global handlers unless truly global.

Include common mock variants:
- Success response
- Error response (403/500)
- Slow response (delay) if relevant

If the app uses GraphQL, mock with MSW GraphQL handlers.
If it uses REST, use MSW REST handlers.

### Step 4 — Write the story file (CSF)

Story file should:
- Export `meta` with component/render
- Provide a `render` function that mounts the page/harness
- Include `args` only if meaningful; don’t arg-spam page stories
- Include a11y-friendly deterministic selectors (labels/roles)

### Step 5 — Add `play` interactions

Use `play` to enact the journey:
- Query DOM from `canvas` (prefer role/label queries)
- Use `userEvent` to type/click
- Use `await` + `waitFor`-style patterns (avoid arbitrary timeouts)
- Add minimal assertions (what must be true at the end)

Reminder: `play` runs after render and can be debugged in the Interactions panel.

### Step 6 — Optional: Test Runner wiring

If requested (or if the repo already uses it), wire Storybook Test Runner:
- Add a script (often `test-storybook`) and config if needed
- Ensure interactions pass in a headless run
- Keep assertions stable

Storybook test runner runs through stories and can be configured via hooks.

---

## "Storyboard" presentation options

When the user says “storyboard”, implement at least one:

### A) Multiple stories as steps
- `Step1_EnterDetails`
- `Step2_ConfirmEmail`
- `Step3_OnboardingComplete`

### B) Docs page that sequences stories
Create an MDX doc showing each step in order (if the repo uses docs).

### C) One story with multiple play “chapters”
Only if the app supports a single mounted flow; otherwise prefer separate stories.

---

## Quality checklist (must pass before you finish)

- [ ] Stories run without depending on real backends (MSW works)
- [ ] Happy path story has a `play` that reaches a meaningful end state
- [ ] At least one error/edge story exists with distinct MSW handlers
- [ ] No brittle selectors (prefer roles/labels over CSS selectors)
- [ ] Clear naming: "Journeys/…" and story names match the product language

---

## Integration with other skills

This skill works together with other patterns in this repository:

| Skill | Integration |
|-------|-------------|
| **testing-strategy** | Journey stories complement integration tests; use journeys for visual/interactive validation, integration tests for headless CI |
| **validation-boundary** | Mock Zod validation responses in MSW; test form error states with invalid payloads |
| **result-types** | Mock `Result<T, E>` API responses; test both `ok` and `err` paths in separate stories |
| **fn-args-deps** | Journey harnesses can inject mock `deps` for components that follow `fn(args, deps)` |
| **observability** | Verify telemetry events fire during journeys by mocking/spying on the telemetry dependency |

When creating journey stories:
- Use `result-types` error shapes in your MSW error handlers
- Follow `validation-boundary` patterns for form validation mock responses
- Inject mock dependencies using patterns from `fn-args-deps`

---

## Example prompts users might give (and how you respond)

### Example 1

User: "Make a Storybook storyboard for signup with MSW, include happy + server error."
You: Create `Journeys/Auth/Signup` stories:

- `HappyPath` with MSW success handlers and `play` that completes signup
- `ServerError` with 500 handler and UI assertion

### Example 2

User: "We want to demo the checkout flow in Storybook, not just components."
You: Mount the Checkout page with providers + router, mock cart/pricing APIs with MSW, script the flow in `play`, and add error/empty states.

---

## Notes

- Use Storybook's documented MSW integration and handlers pattern.
- Use Storybook's documented `play` function approach for interactions.
- Use Storybook's documented test runner if the user wants CI/automation.
