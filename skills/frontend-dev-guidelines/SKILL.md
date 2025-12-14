---
description: Frontend development guidelines for Next.js 15 + React 19 + TypeScript with Tailwind CSS and TanStack Query
trigger_keywords: ["component", "frontend", "react", "nextjs", "tailwind", "tanstack"]
---

# Frontend Development Guidelines

## Tech Stack

- **Framework**: Next.js 15 with App Router
- **UI Library**: React 19
- **Language**: TypeScript (strict mode)
- **Styling**: Tailwind CSS
- **Data Fetching**: TanStack Query (React Query)
- **State Management**: Zustand (client state) + TanStack Query (server state)
- **Forms**: React Hook Form + Zod validation
- **UI Components**: [ADD YOUR COMPONENT LIBRARY - shadcn/ui, Radix, MUI, etc.]

## Project Structure

```
frontend/
├── src/
│   ├── app/                    # Next.js App Router pages
│   │   ├── (auth)/            # Route groups
│   │   ├── api/               # API routes
│   │   ├── layout.tsx         # Root layout
│   │   └── page.tsx           # Home page
│   ├── components/
│   │   ├── ui/                # Base UI components
│   │   ├── forms/             # Form components
│   │   └── features/          # Feature-specific components
│   ├── hooks/                 # Custom React hooks
│   ├── lib/
│   │   ├── api/              # API client functions
│   │   ├── utils/            # Utility functions
│   │   └── validations/      # Zod schemas
│   ├── providers/            # Context providers
│   ├── stores/               # Zustand stores
│   └── types/                # TypeScript type definitions
├── public/                   # Static assets
└── tailwind.config.ts       # Tailwind configuration
```

## Component Patterns

### Server vs Client Components

```tsx
// Server Component (default in Next.js 15)
// - No 'use client' directive
// - Can use async/await directly
// - Can access server-only resources
export default async function ServerComponent() {
  const data = await fetchData(); // Direct data fetching
  return <div>{data.title}</div>;
}

// Client Component
// - Requires 'use client' directive at TOP of file
// - Can use hooks, event handlers, browser APIs
'use client';

import { useState } from 'react';

export function ClientComponent() {
  const [count, setCount] = useState(0);
  return <button onClick={() => setCount(c => c + 1)}>{count}</button>;
}
```

### Component Structure

```tsx
'use client';

import { useState, useCallback } from 'react';
import { useQuery } from '@tanstack/react-query';

// Types at top
interface ComponentProps {
  id: string;
  onSuccess?: () => void;
}

// Component
export function MyComponent({ id, onSuccess }: ComponentProps) {
  // 1. Hooks first
  const [state, setState] = useState<string>('');
  const { data, isLoading, error } = useQuery({
    queryKey: ['item', id],
    queryFn: () => fetchItem(id),
  });

  // 2. Callbacks
  const handleClick = useCallback(() => {
    // handle click
    onSuccess?.();
  }, [onSuccess]);

  // 3. Early returns for loading/error states
  if (isLoading) return <LoadingSpinner />;
  if (error) return <ErrorMessage error={error} />;

  // 4. Main render
  return (
    <div className="flex flex-col gap-4">
      {/* JSX */}
    </div>
  );
}
```

## Data Fetching with TanStack Query

### Query Setup

```tsx
// lib/api/items.ts
export async function fetchItems(): Promise<Item[]> {
  const response = await fetch('/api/items');
  if (!response.ok) {
    throw new Error('Failed to fetch items');
  }
  return response.json();
}

// In component
const { data, isLoading, error, refetch } = useQuery({
  queryKey: ['items'],
  queryFn: fetchItems,
  staleTime: 5 * 60 * 1000, // 5 minutes
});
```

### Mutations

```tsx
const mutation = useMutation({
  mutationFn: createItem,
  onSuccess: () => {
    queryClient.invalidateQueries({ queryKey: ['items'] });
    toast.success('Item created!');
  },
  onError: (error) => {
    toast.error(error.message);
  },
});
```

## Styling with Tailwind

### Best Practices

```tsx
// Use semantic class groupings
<div className={cn(
  // Layout
  "flex flex-col gap-4",
  // Sizing
  "w-full max-w-md",
  // Spacing
  "p-4 m-2",
  // Colors
  "bg-white dark:bg-gray-900",
  // Typography
  "text-sm font-medium",
  // Borders
  "border rounded-lg",
  // Conditional
  isActive && "ring-2 ring-blue-500"
)}>
```

### Utility Function for Class Names

```tsx
// lib/utils.ts
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
```

## Form Handling

```tsx
'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const formSchema = z.object({
  email: z.string().email('Invalid email'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
});

type FormData = z.infer<typeof formSchema>;

export function LoginForm() {
  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<FormData>({
    resolver: zodResolver(formSchema),
  });

  const onSubmit = async (data: FormData) => {
    // Handle form submission
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      <input {...register('email')} />
      {errors.email && <span>{errors.email.message}</span>}

      <input type="password" {...register('password')} />
      {errors.password && <span>{errors.password.message}</span>}

      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Loading...' : 'Submit'}
      </button>
    </form>
  );
}
```

## Error Handling

### Error Boundary

```tsx
'use client';

import { ErrorBoundary } from 'react-error-boundary';

function ErrorFallback({ error, resetErrorBoundary }) {
  return (
    <div role="alert" className="p-4 bg-red-50 border border-red-200 rounded">
      <h2>Something went wrong</h2>
      <pre className="text-sm">{error.message}</pre>
      <button onClick={resetErrorBoundary}>Try again</button>
    </div>
  );
}

// Usage
<ErrorBoundary FallbackComponent={ErrorFallback}>
  <MyComponent />
</ErrorBoundary>
```

### API Error Handling

```tsx
// lib/api/client.ts
export async function apiClient<T>(url: string, options?: RequestInit): Promise<T> {
  const response = await fetch(url, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...options?.headers,
    },
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({}));
    throw new ApiError(response.status, error.message || 'Request failed');
  }

  return response.json();
}

class ApiError extends Error {
  constructor(public status: number, message: string) {
    super(message);
    this.name = 'ApiError';
  }
}
```

## TypeScript Best Practices

### Type Definitions

```tsx
// types/index.ts
export interface User {
  id: string;
  email: string;
  name: string;
  createdAt: Date;
}

// Partial types for updates
export type UserUpdate = Partial<Pick<User, 'email' | 'name'>>;

// API response types
export interface ApiResponse<T> {
  data: T;
  meta?: {
    total: number;
    page: number;
  };
}
```

### Avoid These

```tsx
// BAD
const data: any = await fetch(...);
const items = data as Item[];

// GOOD
const response = await fetch<ApiResponse<Item[]>>(...);
const items = response.data;
```

## Performance Optimization

### Code Splitting

```tsx
// Dynamic imports for heavy components
import dynamic from 'next/dynamic';

const HeavyChart = dynamic(() => import('@/components/HeavyChart'), {
  loading: () => <ChartSkeleton />,
  ssr: false,
});
```

### Memoization

```tsx
// Memoize expensive computations
const processedData = useMemo(() => {
  return expensiveComputation(data);
}, [data]);

// Memoize callbacks passed to children
const handleClick = useCallback(() => {
  // handler logic
}, [dependencies]);

// Memoize components that receive object/array props
const MemoizedComponent = memo(MyComponent);
```

## Common Patterns

### Loading States

```tsx
// Use Suspense for loading
import { Suspense } from 'react';

<Suspense fallback={<LoadingSkeleton />}>
  <AsyncComponent />
</Suspense>
```

### Conditional Rendering

```tsx
// Prefer early returns
if (!data) return null;
if (isLoading) return <Loading />;
if (error) return <Error />;

return <Content data={data} />;
```

---

**CUSTOMIZE THIS FILE** for your specific component library, design system, and project conventions.
