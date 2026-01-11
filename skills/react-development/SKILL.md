---
name: react-development
description: "Modern React architecture patterns. Container/View split, framework adapters, React Query, dependency injection, Storybook-first development, accessibility. User experience over developer convenience."
version: 1.1.0
libraries: ["@tanstack/react-query", "react-hook-form", "zod", "msw", "class-variance-authority"]
---

# React Development

Build frontend applications that are portable, testable, and user-focused.

## Core Principle

**Frameworks are adapters, not architectures.** Your business logic should work with any React framework. Container/View patterns keep rendering portable. Storybook-first development catches UX issues before backends exist.

## Critical Rules

| Rule | Enforcement |
|------|-------------|
| No `any`, no `as` | Type-safe solutions always exist |
| No framework imports in components | ESLint boundary rules |
| Test what pays | Domain logic, critical flows, not snapshots |
| Accessibility required | 15% of users have disabilities |
| Handle all states | Loading, error, empty, offline |

---

## Container/View Pattern

Separate data orchestration (Container) from presentation (View).

### WRONG - Coupled Component

```tsx
// UserProfile.tsx - Does everything, untestable
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

### CORRECT - Container/View Split

```tsx
// UserProfileView.tsx - Pure presentation, portable
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

---

## Dependency Injection: handlers vs deps

Two distinct prop types for different purposes:

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

---

## React Query Patterns

### Key Factories

Organize query keys systematically:

```typescript
// queries/userKeys.ts
export const userKeys = {
  all: ['users'] as const,
  lists: () => [...userKeys.all, 'list'] as const,
  list: (filters: UserFilters) => [...userKeys.lists(), filters] as const,
  details: () => [...userKeys.all, 'detail'] as const,
  detail: (id: string) => [...userKeys.details(), id] as const,
};

// Usage
const { data } = useQuery({
  queryKey: userKeys.detail(userId),
  queryFn: () => fetchUser(userId),
});

// Invalidation
queryClient.invalidateQueries({ queryKey: userKeys.lists() });
```

### Mutation Pattern

```typescript
export function useUpdateUserMutation() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: UpdateUserData) => updateUser(data),
    onSuccess: (updatedUser) => {
      // Update cache directly
      queryClient.setQueryData(
        userKeys.detail(updatedUser.id),
        updatedUser
      );
      // Invalidate list views
      queryClient.invalidateQueries({ queryKey: userKeys.lists() });
    },
  });
}
```

### Optimistic Updates

```typescript
useMutation({
  mutationFn: toggleLike,
  onMutate: async (postId) => {
    await queryClient.cancelQueries({ queryKey: postKeys.detail(postId) });
    const previous = queryClient.getQueryData(postKeys.detail(postId));
    queryClient.setQueryData(postKeys.detail(postId), (old: Post) => ({
      ...old,
      isLiked: !old.isLiked,
      likeCount: old.isLiked ? old.likeCount - 1 : old.likeCount + 1,
    }));
    return { previous };
  },
  onError: (_err, postId, context) => {
    queryClient.setQueryData(postKeys.detail(postId), context?.previous);
  },
});
```

### Loading State Policies

Choose strategically based on UX needs:

| staleTime | Behavior | Use When |
|-----------|----------|----------|
| `0` (default) | Always refetch | Real-time data (stock prices) |
| `30_000` | Cache 30s | User profiles, product details |
| `Infinity` | Never refetch | Static reference data |

```typescript
const { data } = useQuery({
  queryKey: userKeys.detail(userId),
  queryFn: () => fetchUser(userId),
  staleTime: 30_000,  // 30 seconds
  gcTime: 5 * 60 * 1000,  // Keep in cache 5 minutes
});
```

---

## URL State with Zod

Parse URL parameters once at the boundary, pass typed data down:

```typescript
// lib/url-state.ts
import { z } from 'zod';

export const searchParamsSchema = z.object({
  page: z.coerce.number().positive().default(1),
  sort: z.enum(['name', 'date', 'price']).default('name'),
  direction: z.enum(['asc', 'desc']).default('asc'),
  search: z.string().optional(),
});

export type SearchParams = z.infer<typeof searchParamsSchema>;

export function parseSearchParams(params: URLSearchParams): SearchParams {
  const raw = Object.fromEntries(params.entries());
  const result = searchParamsSchema.safeParse(raw);
  return result.success ? result.data : searchParamsSchema.parse({});
}
```

```tsx
// Container parses once
function ProductListContainer() {
  const searchParams = useSearchParams();
  const parsed = parseSearchParams(searchParams);

  return <ProductListView filters={parsed} />;
}
```

---

## React 19 Patterns

### useTransition for Non-Blocking Updates

```tsx
function ProductSearch() {
  const [searchTerm, setSearchTerm] = useState('');
  const [isPending, startTransition] = useTransition();

  const handleSearch = (value: string) => {
    setSearchTerm(value);  // High priority - update input immediately
    startTransition(() => {
      updateFilters({ search: value });  // Low priority - won't block typing
    });
  };

  return (
    <div className="relative">
      <input
        value={searchTerm}
        onChange={(e) => handleSearch(e.target.value)}
        placeholder="Search..."
      />
      {isPending && <Spinner className="absolute right-2 top-2" size="sm" />}
    </div>
  );
}
```

### useOptimistic for Instant Feedback

```tsx
function LikeButton({ postId, initialLikes, isLiked }: LikeButtonProps) {
  const [optimisticState, addOptimistic] = useOptimistic(
    { likes: initialLikes, isLiked },
    (state, action: 'like' | 'unlike') => ({
      likes: action === 'like' ? state.likes + 1 : Math.max(0, state.likes - 1),
      isLiked: action === 'like',
    })
  );

  const toggleLike = async () => {
    const action = optimisticState.isLiked ? 'unlike' : 'like';
    addOptimistic(action);  // Update UI immediately
    await fetch(`/api/posts/${postId}/like`, {
      method: optimisticState.isLiked ? 'DELETE' : 'POST',
    });
  };

  return (
    <button onClick={toggleLike}>
      <HeartIcon filled={optimisticState.isLiked} />
      <span>{optimisticState.likes}</span>
    </button>
  );
}
```

### State Library Decision Tree

| Need | Solution |
|------|----------|
| Server state (fetch, cache, sync) | React Query |
| Non-blocking UI updates | `useTransition` |
| Optimistic UI | `useOptimistic` |
| Form submission state | `useActionState` |
| Local component state | `useState` / `useReducer` |
| Shared within feature subtree | React Context |
| Proven cross-tree sync | Zustand (only after measuring) |

---

## Form Handling

React Hook Form + Zod for type-safe validation:

```tsx
// schemas/contact.ts
import { z } from 'zod';

export const contactFormSchema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters'),
  email: z.string().email('Invalid email address'),
  message: z.string().min(10, 'Message must be at least 10 characters'),
});

export type ContactFormData = z.infer<typeof contactFormSchema>;
```

```tsx
// ContactForm.tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';

export function ContactForm({ onSubmit }: { onSubmit: (data: ContactFormData) => Promise<void> }) {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<ContactFormData>({
    resolver: zodResolver(contactFormSchema),
  });

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate>
      <div>
        <label htmlFor="name">Name</label>
        <input id="name" {...register('name')} aria-invalid={!!errors.name} />
        {errors.name && <span role="alert">{errors.name.message}</span>}
      </div>

      <div>
        <label htmlFor="email">Email</label>
        <input id="email" type="email" {...register('email')} aria-invalid={!!errors.email} />
        {errors.email && <span role="alert">{errors.email.message}</span>}
      </div>

      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Sending...' : 'Send'}
      </button>
    </form>
  );
}
```

---

## Storybook-First Development

Build UIs before backends exist. Stakeholder feedback before integration.

### Required: Every Component Has Stories

```tsx
// UserCard.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import { fn } from '@storybook/test';
import { UserCard } from './UserCard';

const meta: Meta<typeof UserCard> = {
  title: 'Components/UserCard',
  component: UserCard,
  args: {
    handlers: { onEdit: fn(), onDelete: fn() },
  },
};

export default meta;
type Story = StoryObj<typeof UserCard>;

export const Default: Story = {
  args: {
    user: { id: '1', name: 'Alice', email: 'alice@example.com' },
  },
};

export const LongName: Story = {
  args: {
    user: { id: '2', name: 'Alexandria Bartholomew Constantine III', email: 'a@example.com' },
  },
};
```

### MSW for Data-Fetching Stories

```tsx
// UserProfile.stories.tsx
import { http, HttpResponse, delay } from 'msw';

export const Loading: Story = {
  parameters: {
    msw: {
      handlers: [
        http.get('/api/users/:id', async () => {
          await delay('infinite');
          return HttpResponse.json({});
        }),
      ],
    },
  },
};

export const Error: Story = {
  parameters: {
    msw: {
      handlers: [
        http.get('/api/users/:id', () => {
          return HttpResponse.json({ error: 'Not found' }, { status: 404 });
        }),
      ],
    },
  },
};
```

### Play Functions for Interaction Testing

```tsx
export const SubmissionFlow: Story = {
  play: async ({ canvasElement, args }) => {
    const canvas = within(canvasElement);

    await userEvent.type(canvas.getByLabelText(/email/i), 'user@example.com');
    await userEvent.type(canvas.getByLabelText(/password/i), 'password123');
    await userEvent.click(canvas.getByRole('button', { name: /sign in/i }));

    await expect(args.onSubmit).toHaveBeenCalledWith({
      email: 'user@example.com',
      password: 'password123',
    });
  },
};
```

---

## Custom Hooks Organization

### Primitive Hooks (Reusable)

```typescript
// hooks/useDebounce.ts
export function useDebounce<T>(value: T, delay: number): T {
  const [debouncedValue, setDebouncedValue] = useState(value);

  useEffect(() => {
    const timer = setTimeout(() => setDebouncedValue(value), delay);
    return () => clearTimeout(timer);
  }, [value, delay]);

  return debouncedValue;
}
```

### State Machine Hooks

```typescript
// hooks/useDialogState.ts
type DialogState<T> =
  | { type: 'closed' }
  | { type: 'open'; data: T };

export function useDialogState<T>() {
  const [state, setState] = useState<DialogState<T>>({ type: 'closed' });

  const open = useCallback((data: T) => setState({ type: 'open', data }), []);
  const close = useCallback(() => setState({ type: 'closed' }), []);

  return {
    isOpen: state.type === 'open',
    data: state.type === 'open' ? state.data : null,
    open,
    close,
  };
}
```

### Anti-Pattern: Kitchen Sink Hooks

```tsx
// ❌ BAD: Hook does too much
function useUserPage(userId: string) {
  const user = useUserQuery(userId);
  const posts = useUserPostsQuery(userId);
  const [isEditing, setIsEditing] = useState(false);
  const [selectedTab, setSelectedTab] = useState('posts');
  // ... 20 more things
}

// ✅ GOOD: Compose focused hooks in component
function UserPage({ userId }: { userId: string }) {
  const { data: user } = useUserQuery(userId);
  const { data: posts } = useUserPostsQuery(userId);
  const editDialog = useDialogState<User>();
  const [selectedTab, setSelectedTab] = useState<Tab>('posts');
}
```

---

## Folder Structure

```
src/
├── app/                  # Framework boundary (Next.js/Remix)
│   └── users/
│       └── [id]/
│           └── page.tsx  # Container: reads params, wires handlers
├── components/           # Presentational UI (NO framework imports)
│   ├── Button.tsx
│   ├── Button.stories.tsx
│   └── UserProfileView.tsx
├── hooks/                # Reusable hooks (NO framework imports)
├── queries/              # React Query hooks and keys
│   ├── userKeys.ts
│   └── useUserQuery.ts
├── lib/                  # Pure utilities, types, schemas
├── features/             # Feature modules (when code grows)
│   └── users/
│       ├── components/
│       ├── queries/
│       └── index.ts
└── mocks/                # MSW handlers
```

**Policy:** Only `app/` can import framework APIs. Everything else must be portable.

---

## ESLint Boundary Rules

Enforce framework portability:

```javascript
// eslint.config.mjs
{
  files: ['src/components/**', 'src/hooks/**', 'src/lib/**', 'src/queries/**'],
  rules: {
    'no-restricted-imports': ['error', {
      paths: [
        { name: 'next/navigation', message: 'Use DI, not framework imports' },
        { name: 'next/router', message: 'Use DI, not framework imports' },
      ],
    }],
  },
}
```

---

## Accessibility Checklist

| Requirement | Implementation |
|-------------|----------------|
| Keyboard nav | Tab, Enter, Escape, Arrow keys |
| Focus management | Trap in modals, restore on close |
| ARIA labels | When semantic HTML isn't enough |
| Color contrast | WCAG AA: 4.5:1 for text |
| Error association | `aria-invalid`, `aria-describedby` |
| Loading states | `aria-busy`, screen reader announcements |

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

---

## Testing Philosophy

Test only what pays:

| Test Level | When |
|------------|------|
| Unit | Pure domain logic, heavily |
| Component | Complex UI logic, high-risk flows |
| Storybook | Visual variants, interaction tests |
| E2E | Critical user journeys only |

### Avoid

- Snapshot spam
- Tests that duplicate type checking
- Testing implementation details

---

## Definition of Done

Before shipping a React feature:

- [ ] Presentational components have no framework imports
- [ ] URL state parsed once at boundary with Zod
- [ ] Data fetching via React Query with stable keys
- [ ] Loading, error, and empty states implemented
- [ ] DI handlers used for side effects
- [ ] Storybook stories for main variants
- [ ] Tests only where they add value
- [ ] ESLint boundary rules prevent drift
- [ ] Accessibility requirements met

## Integration

| Skill | Relationship |
|-------|--------------|
| `strict-typescript` | TypeScript config and type patterns |
| `fn-args-deps` | Function signature pattern |
| `validation-boundary` | Zod schemas at boundaries |
| `testing-strategy` | Test pyramid approach |
| `design-principles` | Component design decisions |
