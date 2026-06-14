---
name: react-development
description: Builds portable, testable React applications using Container/View separation, dependency injection, and framework-agnostic architecture. Use when creating or refactoring React components, wiring data fetching with React Query, parsing URL state with Zod, handling forms with react-hook-form, or when components mix framework imports (next/navigation, useRouter, useParams) with presentation. Use when output must be Storybook-friendly, accessible, and survive a framework migration.
version: 1.3.0
libraries: ["@tanstack/react-query", "react-hook-form", "zod", "msw", "class-variance-authority", "nuqs"]
---

# React Development

## Overview

Build frontend applications that are portable, testable, and user-focused. The principle: **frameworks are adapters, not architectures.** Your business logic and presentation should work with any React framework. Container/View patterns keep rendering portable, dependency injection keeps side effects mockable, and Storybook-first development catches UX issues before backends exist. User experience wins over developer convenience.

The payoff: presentational code renders in Storybook with no framework, tests mock handlers instead of routers, and a framework migration only rewrites the thin Container layer.

## When to Use

- Creating new React components, pages, or features
- Refactoring components that mix framework imports with rendering
- Wiring data fetching, caching, and mutations with React Query
- Parsing URL/search-param state at a boundary with Zod or nuqs
- Building forms with react-hook-form + Zod validation
- Setting up ESLint boundary rules to enforce portability

**When NOT to use:** for a throwaway spike or design exploration where the architecture is the question, prototype first. For pure visual/spacing/typography decisions, use [ui-design-principles](../ui-design-principles/SKILL.md). For end-to-end flow demos (signup/checkout), use [storybook-journeys](../storybook-journeys/SKILL.md).

**Related:** [storybook-journeys](../storybook-journeys/SKILL.md) (page-level flow stories), [ui-design-principles](../ui-design-principles/SKILL.md) (visual design), [agent-browser](../agent-browser/SKILL.md) (browser verification), [testing-strategy](../testing-strategy/SKILL.md) (test pyramid), [validation-boundary](../validation-boundary/SKILL.md) (Zod at boundaries).

## Deep-Dive References

This SKILL.md is the focused core. Detailed patterns live one level deep:

- [PATTERNS.md](PATTERNS.md): React Query (keys, mutations, optimistic, staleTime), URL state with Zod, React 19 (`useTransition`, `useOptimistic`, `useActionState`), forms, custom hooks, folder structure, ESLint boundaries.
- [INTERACTIONS.md](INTERACTIONS.md): Web Interface Guidelines: keyboard, targets, forms, feedback, animation, layout, content/accessibility, performance, theming, hydration, design (MUST/SHOULD/NEVER rules).
- [STORYBOOK.md](STORYBOOK.md): Storybook-first development: stories per component, MSW for data-fetching states, play functions, testing philosophy.

## Critical Rules

| Rule | Enforcement |
|------|-------------|
| No `any`, no `as` | Type-safe solutions always exist |
| No framework imports in components/hooks/lib/queries | ESLint boundary rules (see [PATTERNS.md](PATTERNS.md)) |
| Test what pays | Domain logic, critical flows, not snapshots |
| Accessibility required | ~15% of users have disabilities; legal requirement in many regions |
| Handle all states | Loading, error, empty, offline |

## Container/View Pattern

Separate data orchestration (Container) from presentation (View). The View is pure, prop-driven, and framework-free; the Container is the thin boundary that touches the framework.

### WRONG: Coupled Component

```tsx
// UserProfile.tsx - Does everything, untestable, can't render in Storybook
function UserProfile() {
  const { id } = useParams();  // Framework-specific
  const router = useRouter();   // Framework-specific
  const { data, isLoading } = useQuery(['user', id], () => fetchUser(id));

  if (isLoading) return <Spinner />;

  return (
    <div>
      <h1>{data.name}</h1>
      <button onClick={() => router.push(`/users/${id}/edit`)}>Edit</button>
    </div>
  );
}
```

### CORRECT: Container/View Split

```tsx
// UserProfileView.tsx - Pure presentation, portable, Storybook-friendly
type UserProfileViewProps = {
  user: User;
  handlers: {
    onEdit: () => void;
    onDelete: () => void;
  };
};

export function UserProfileView({ user, handlers }: UserProfileViewProps) {
  return (
    <div>
      <h1>{user.name}</h1>
      <button onClick={handlers.onEdit}>Edit</button>
      <button onClick={handlers.onDelete}>Delete</button>
    </div>
  );
}

// UserProfileContainer.tsx - Framework boundary
'use client';
import { useParams, useRouter } from 'next/navigation';

export function UserProfileContainer() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const { data: user, isLoading, error } = useUserQuery(id);

  const handlers = {
    onEdit: () => router.push(`/users/${id}/edit`),
    onDelete: () => deleteUserMutation.mutate(id),
  };

  if (isLoading) return <UserProfileSkeleton />;
  if (error) return <ErrorState error={error} />;
  if (!user) return <EmptyState message="User not found" />;

  return <UserProfileView user={user} handlers={handlers} />;
}
```

### Why This Matters

| Benefit | How |
|---------|-----|
| Storybook works | View has no framework imports |
| Testing is easy | Mock handlers, not routers |
| Framework migration | Only rewrite Containers |
| Type safety | Props are explicit contracts |

## Dependency Injection: handlers vs deps

Two distinct prop types for two distinct purposes. Both keep the View pure.

| Prop Type | Purpose | Example |
|-----------|---------|---------|
| `handlers` | User-initiated actions | `onEdit`, `onDelete`, `onSubmit` |
| `deps` | Platform/environment capabilities | `getInitialValue`, `storage`, `analytics` |

```tsx
type ProductCardProps = {
  product: Product;
  handlers: {
    onAddToCart: () => void;
    onViewDetails: () => void;
  };
  deps?: {
    trackEvent?: (name: string) => void;  // Optional analytics
  };
};

function ProductCard({ product, handlers, deps }: ProductCardProps) {
  const handleAddToCart = () => {
    deps?.trackEvent?.('add_to_cart');
    handlers.onAddToCart();
  };

  return (
    <article>
      <h2>{product.name}</h2>
      <button onClick={handleAddToCart}>Add to Cart</button>
      <button onClick={handlers.onViewDetails}>View Details</button>
    </article>
  );
}
```

## State Decision Guide

Choose the simplest mechanism that fits the data's lifetime and scope. Full React 19 patterns in [PATTERNS.md](PATTERNS.md).

| Need | Solution |
|------|----------|
| Server state (fetch, cache, sync) | React Query |
| Non-blocking UI updates | `useTransition` |
| Optimistic UI | `useOptimistic` |
| Form submission state | `useActionState` |
| Local component state | `useState` / `useReducer` |
| Shareable UI (filters, tabs, pagination) | URL state (Zod / nuqs) |
| Shared within a feature subtree | React Context |
| Proven cross-tree sync | Zustand (only after measuring) |

**Avoid prop drilling deeper than 3 levels.** If you pass props through components that don't use them, introduce context or restructure the tree.

## Accessibility (WCAG 2.1 AA baseline)

| Requirement | Implementation |
|-------------|----------------|
| Keyboard nav | Tab, Enter, Escape, Arrow keys per WAI-ARIA APG |
| Focus management | Trap in modals, restore on close |
| ARIA labels | When semantic HTML isn't enough |
| Color contrast | WCAG AA 4.5:1 for text; prefer APCA |
| Error association | `aria-invalid`, `aria-describedby` |
| Loading states | `aria-busy`, polite `aria-live` announcements |

### WRONG

```tsx
<div onClick={handleAction}>Click me</div>
```

### CORRECT

```tsx
<button onClick={handleAction} aria-label="Add item to cart">
  Add to Cart
</button>
```

Full interaction, animation, performance, and theming rules: [INTERACTIONS.md](INTERACTIONS.md).

## Red Flags

- Framework imports (`next/navigation`, `next/router`) inside `components/`, `hooks/`, `lib/`, or `queries/`
- A component both fetches data and renders presentation with no Container/View split
- `<div onClick>` used for navigation or actions (use `<a>`/`<Link>` and `<button>`)
- `any` or `as` casts to silence the type checker
- Missing loading, error, or empty states (blank screens on slow networks)
- Color as the sole indicator of state (red/green with no text or icon)
- Components over ~200 lines, or a single "kitchen sink" hook doing 20 things
- `transition: all` or animating layout props (`top`, `left`, `width`, `height`)
- Query keys built inline as raw arrays instead of a key factory

## Verification

Before shipping a React feature:

- [ ] Presentational components have no framework imports (ESLint boundary rules pass)
- [ ] Container/View split: data orchestration separated from rendering
- [ ] URL state parsed once at the boundary with Zod (or nuqs)
- [ ] Data fetching via React Query with a stable key factory
- [ ] DI `handlers`/`deps` used for side effects; no routers in Views
- [ ] Loading, error, empty, and dense states implemented; skeletons match final layout
- [ ] Keyboard-operable flows with visible `:focus-visible` rings
- [ ] Hit targets ≥24px desktop, ≥44px mobile; links for nav, buttons for actions
- [ ] Icon-only buttons have `aria-label`; form controls have labels
- [ ] `prefers-reduced-motion` respected; no `transition: all`
- [ ] Storybook stories cover the main variants ([STORYBOOK.md](STORYBOOK.md))
- [ ] Tests only where they add value (domain logic, critical flows)

## Integration

| Skill | Relationship |
|-------|--------------|
| [strict-typescript](../strict-typescript/SKILL.md) | TypeScript config and type patterns |
| [fn-args-deps](../fn-args-deps/SKILL.md) | Function signature pattern behind `deps` |
| [validation-boundary](../validation-boundary/SKILL.md) | Zod schemas at boundaries |
| [testing-strategy](../testing-strategy/SKILL.md) | Test pyramid approach |
| [ui-design-principles](../ui-design-principles/SKILL.md) | Visual design patterns |
| [storybook-journeys](../storybook-journeys/SKILL.md) | Page-level flow stories |
| [agent-browser](../agent-browser/SKILL.md) | Browser verification of rendered UI |
