# React Patterns: Data, State, Forms, Structure

Deep-dive patterns for [react-development](SKILL.md). Covers React Query, URL state, React 19 hooks, forms, custom hooks, folder structure, and ESLint boundary enforcement.

## React Query Patterns

### Key Factories

Organize query keys systematically so invalidation stays predictable:

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

Choose `staleTime` based on UX needs:

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

### Form Interaction Rules

| Rule | Implementation |
|------|----------------|
| Enter submits | Single text input: Enter submits form |
| Textarea behavior | `⌘/⌃+Enter` submits; `Enter` inserts newline |
| Labels everywhere | Every control has `<label>` or `aria-label` |
| Label activation | Clicking label focuses associated control |
| Submit always enabled | Disable only during in-flight request |
| Don't block input | Allow any input, show validation feedback (don't block keystrokes) |
| No dead zones | Checkbox/radio labels share hit target with control |
| Error placement | Show errors next to fields; focus first error on submit |
| Warn unsaved changes | Confirm before navigation when data could be lost |

### Input Attributes

```tsx
// Correct types and input modes
<input
  type="email"
  inputMode="email"
  autoComplete="email"
  spellCheck={false}
  placeholder="user@example.com"
/>

<input
  type="tel"
  inputMode="tel"
  autoComplete="tel"
  placeholder="+1 (123) 456-7890"
/>

// Numeric input
<input
  type="text"
  inputMode="numeric"
  pattern="[0-9]*"
  placeholder="0123456789"
/>
```

### Avoid Password Manager Triggers

```tsx
// ❌ WRONG: Triggers password manager for non-auth fields
<input name="password" type="password" />

// ✅ CORRECT: Prevent password manager for OTP
<input
  name="verification-code"
  type="text"
  inputMode="numeric"
  autoComplete="one-time-code"
/>

// ✅ CORRECT: Prevent for search fields
<input
  name="search-query"
  type="search"
  autoComplete="off"
/>
```

### Windows `<select>` Fix

```css
/* Avoid dark-mode contrast bugs on Windows */
select {
  background-color: var(--bg-primary);
  color: var(--text-primary);
}
```

### Textarea with Keyboard Submit

```tsx
function TextareaWithSubmit({ onSubmit }: { onSubmit: (value: string) => void }) {
  const handleKeyDown = (e: React.KeyboardEvent<HTMLTextAreaElement>) => {
    if ((e.metaKey || e.ctrlKey) && e.key === 'Enter') {
      e.preventDefault();
      onSubmit(e.currentTarget.value);
    }
  };

  return (
    <textarea
      onKeyDown={handleKeyDown}
      placeholder="Press ⌘+Enter to submit…"
    />
  );
}
```

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
