---
name: storybook-journeys
description: Creates Storybook "user journey" storyboards that demonstrate end-to-end React flows (page/screen stories, MSW API mocking, interaction play functions, optional test-runner CI wiring). Use when the user wants Storybook demos of whole flows rather than atomic components, e.g. signup/login/checkout/onboarding, with mocked APIs and scripted interactions, or mentions "storybook storyboard", "user journey stories", "MSW fake API in storybook", "play function", or "show a whole page in storybook".
version: 1.1.0
libraries: ["msw", "@storybook/test", "@storybook/addon-interactions", "storybook"]
---

# Storybook Journeys

## Overview

Turn a React app into Storybook **storyboards** that demonstrate end-to-end **user journeys**: not isolated components, but whole screens flowing through real interactions with mocked APIs. The principle: **treat journeys as products, not demos.** Compose the real page/screen with its real providers (router, query client, auth context) rather than faking a composite, and keep every story deterministic with stable data, timers, and network responses.

The mental model: **Storybook is the stage, MSW is the world, `play` is the script.** MSW simulates REST/GraphQL network states per story; `play` simulates the user clicking, typing, waiting, and asserting after render. This catches UX issues (broken flows, missing error states, dead ends) before a backend exists and before integration.

## When to Use

- Demoing a full flow in Storybook: signup, login, checkout, onboarding, settings
- Showing a whole page/screen story, not just a `<Button>`
- Mocking REST or GraphQL APIs per story with MSW (success / error / slow / empty)
- Scripting interactions with `play` (type, click, wait, assert)
- Wiring journeys into CI via the Storybook Test Runner

**When NOT to use:** for atomic component stories (variants, sizes, single-prop states) or general component architecture, use [react-development](../react-development/SKILL.md) and its [STORYBOOK.md](../react-development/STORYBOOK.md). For headless integration/E2E coverage, use [testing-strategy](../testing-strategy/SKILL.md). For driving a real running browser, use [agent-browser](../agent-browser/SKILL.md).

**Related:** [react-development](../react-development/SKILL.md) (Container/View + per-component stories), [validation-boundary](../validation-boundary/SKILL.md) (Zod error shapes to mock), [testing-strategy](../testing-strategy/SKILL.md) (where journeys fit the pyramid), [ui-design-principles](../ui-design-principles/SKILL.md) (visual states), [agent-browser](../agent-browser/SKILL.md) (browser verification).

## Each Journey Needs At Least 3 States

A journey is not complete with only a happy path. Cover, at minimum:

| State | Purpose |
|-------|---------|
| Happy path (success) | The flow completes; assert the meaningful end state |
| Validation / client error | Form errors, invalid input surfaced inline |
| Server error / empty / edge | 403/500 response, empty list, slow network |

If the user asks for a "storyboard", structure it as multiple steps or variants (see Storyboard Presentation below).

## WRONG vs CORRECT Patterns

### WRONG: Testing atomic components in isolation

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

### CORRECT: Journey covers the full user flow

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

### WRONG: Hardcoded test data scattered everywhere

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

### CORRECT: Centralized fixtures with typed data

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

### WRONG: Brittle CSS selectors

```tsx
play: async ({ canvasElement }) => {
  const submitBtn = canvasElement.querySelector('.btn-primary.submit-form')
  await userEvent.click(submitBtn!)
}
```

### CORRECT: Accessible role/label queries

```tsx
play: async ({ canvasElement }) => {
  const canvas = within(canvasElement)
  await userEvent.click(canvas.getByRole('button', { name: 'Submit' }))
}
```

## Minimal Discovery (don't get stuck)

If not provided, make best-effort assumptions and proceed, but quickly ask for missing details *only if required to implement*:

- Storybook version and framework (`@storybook/react-vite`, `@storybook/nextjs`, etc.)
- Router (React Router, Next router, none)
- Data client (fetch, axios, RTK Query, TanStack Query, Apollo)
- Whether MSW is already set up

If unknown, default to: React, Storybook CSF (`*.stories.tsx`), MSW addon via `parameters.msw.handlers`, and `play` using `userEvent` + `canvas` queries.

## Output Expectations

When implementing, produce:

1. One or more page-level Storybook story files for the journey.
2. MSW handlers per story state (success / fail / edge).
3. A `play` function for at least the happy path.
4. A "Journey Harness" wrapper if needed (providers, router, query client).
5. (Optional) A docs/MDX storyboard page sequencing the steps.
6. (Optional) Test-runner wiring so journeys run in CI.

## Folder & Naming Conventions

Pick whichever matches the repo style:

**Option A: Dedicated journeys folder**
- `src/stories/journeys/<JourneyName>/<JourneyName>.stories.tsx`
- `src/stories/journeys/<JourneyName>/mocks.ts`
- `src/stories/journeys/<JourneyName>/fixtures.ts`

**Option B: Co-locate with pages**
- `src/pages/<RouteOrPage>.journey.stories.tsx`
- `src/pages/<RouteOrPage>.mocks.ts`

Story titles use product language: `Journeys/Auth/Signup`, `Journeys/Checkout/HappyPath`, `Journeys/Settings/Profile`. Always use `layout: 'fullscreen'` for page journeys unless the user requests otherwise.

## Implementation Workflow

### Step 1: Identify the journey boundary

Define the entry screen, key actions (click/type/submit/nav), success criteria (what appears / what route / what API calls fire), and error states to include. If the user gives acceptance criteria, mirror them in story names.

### Step 2: Build the "Journey Harness" (if needed)

Create a reusable, minimal wrapper that mounts the page like the real app: router context (MemoryRouter / Next router mocks), providers (Theme, Auth, i18n, QueryClient/Apollo), and feature-flag defaults.

### Step 3: MSW mocks per story

Use Storybook MSW integration via `parameters: { msw: { handlers: [...] } }`. Prefer small handler sets per story; avoid global handlers unless truly global. Include common variants: success, error (403/500), and slow (delay) where relevant. Use MSW GraphQL handlers for GraphQL apps, REST handlers for REST.

### Step 4: Write the story file (CSF)

Export `meta` with component/render, provide a `render` function that mounts the page/harness, include `args` only if meaningful (don't arg-spam page stories), and use a11y-friendly deterministic selectors (labels/roles).

### Step 5: Add `play` interactions

Query the DOM from `canvas` (prefer role/label queries), use `userEvent` to type/click, use `await` + `waitFor`-style patterns (avoid arbitrary timeouts), and add minimal assertions for what must be true at the end. `play` runs after render and is debuggable in the Interactions panel.

### Step 6 (optional): Test Runner wiring

If requested (or already used in the repo), wire the Storybook Test Runner: add a `test-storybook` script and config, ensure interactions pass headless, and keep assertions stable.

## Storyboard Presentation Options

When the user says "storyboard", implement at least one:

| Option | Shape |
|--------|-------|
| A) Multiple stories as steps | `Step1_EnterDetails`, `Step2_ConfirmEmail`, `Step3_OnboardingComplete` |
| B) Docs page sequencing stories | An MDX doc showing each step in order (if the repo uses docs) |
| C) One story, multiple play "chapters" | Only if the app supports a single mounted flow; otherwise prefer separate stories |

## Red Flags

- Story tests an atomic component, not a flow (belongs in [react-development](../react-development/SKILL.md))
- Happy path only, with no validation or server-error story
- MSW handlers duplicated inline across stories instead of shared fixtures
- Brittle CSS selectors (`.btn-primary`) instead of role/label queries
- Arbitrary `setTimeout`/fixed delays in `play` instead of `waitFor`
- Stories depend on a real backend or live network
- Global MSW handlers leaking between unrelated stories
- Generic story names (`Test1`) instead of product-language `Journeys/...`

## Verification

- [ ] Stories run without depending on real backends (MSW works)
- [ ] Happy path story has a `play` that reaches a meaningful end state
- [ ] At least one error/edge story exists with distinct MSW handlers
- [ ] No brittle selectors (roles/labels over CSS selectors)
- [ ] Clear naming: `Journeys/…` and story names match product language
- [ ] Fixtures centralized and typed; no duplicated inline mock data
- [ ] `layout: 'fullscreen'` for page journeys (unless requested otherwise)
- [ ] (If requested) Test Runner passes headless in CI

## Integration

| Skill | Integration |
|-------|-------------|
| [react-development](../react-development/SKILL.md) | Journeys mount Container/View pages; per-component stories live there |
| [testing-strategy](../testing-strategy/SKILL.md) | Journeys complement integration tests: visual/interactive validation vs headless CI |
| [validation-boundary](../validation-boundary/SKILL.md) | Mock Zod validation responses in MSW; test form error states with invalid payloads |
| [result-types](../result-types/SKILL.md) | Mock `Result<T, E>` API responses; test both `ok` and `err` paths in separate stories |
| [fn-args-deps](../fn-args-deps/SKILL.md) | Journey harnesses inject mock `deps` for components following `fn(args, deps)` |
| [observability](../observability/SKILL.md) | Verify telemetry events fire during journeys by spying on the telemetry dependency |

## Example Prompts

**"Make a Storybook storyboard for signup with MSW, include happy + server error."**
Create `Journeys/Auth/Signup` stories: `HappyPath` with MSW success handlers and a `play` that completes signup; `ServerError` with a 500 handler and a UI assertion.

**"We want to demo the checkout flow in Storybook, not just components."**
Mount the Checkout page with providers + router, mock cart/pricing APIs with MSW, script the flow in `play`, and add error/empty states.
