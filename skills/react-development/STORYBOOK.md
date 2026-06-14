# Storybook-First Development

Build UIs before backends exist so stakeholders give feedback before integration. Supports [react-development](SKILL.md). For full page-level user-journey storyboards (signup/checkout flows), see [storybook-journeys](../storybook-journeys/SKILL.md).

## Required: Every Component Has Stories

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

## MSW for Data-Fetching Stories

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

## Play Functions for Interaction Testing

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
