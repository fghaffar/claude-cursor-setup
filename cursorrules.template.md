# Cursor Rules Template

> **Usage**: Copy this file to `.cursorrules` in your project root and customize the placeholders.
> Cursor reads this file automatically to provide context-aware AI assistance.

---

# Project: [YOUR_PROJECT_NAME]

## Tech Stack

### Frontend
- **Framework**: [Next.js 15 / React 18 / Vue 3 / Angular 17]
- **Language**: TypeScript
- **Styling**: [Tailwind CSS / CSS Modules / styled-components]
- **UI Library**: [shadcn/ui / Radix UI / MUI / Ant Design]
- **State**: [TanStack Query / Zustand / Redux / Pinia]
- **Forms**: [React Hook Form + Zod / Formik / VeeValidate]

### Backend
- **Framework**: [FastAPI / Express / Django / NestJS]
- **Language**: [Python 3.11+ / TypeScript / Go]
- **Database**: [PostgreSQL / MongoDB / MySQL]
- **ORM**: [SQLAlchemy / Prisma / TypeORM / Django ORM]
- **Validation**: [Pydantic / Zod / class-validator]
- **Task Queue**: [Celery / BullMQ / Django-Q] (optional)

### Infrastructure
- **Cloud**: [Azure / AWS / GCP]
- **Auth**: [Keycloak / Auth0 / Clerk / NextAuth]
- **Monitoring**: [Sentry / Datadog / New Relic]
- **CI/CD**: [GitHub Actions / GitLab CI / Azure DevOps]

---

## Project Structure

```
[YOUR_PROJECT_NAME]/
├── frontend/                    # [YOUR_FRONTEND_FRAMEWORK] application
│   ├── src/
│   │   ├── app/                 # App Router pages (Next.js) / routes
│   │   ├── components/          # Reusable UI components
│   │   │   ├── ui/              # Base UI components
│   │   │   └── features/        # Feature-specific components
│   │   ├── lib/                 # Utilities and helpers
│   │   │   ├── api/             # API client functions
│   │   │   └── utils/           # General utilities
│   │   ├── hooks/               # Custom React hooks
│   │   └── types/               # TypeScript type definitions
│   └── public/                  # Static assets
│
├── backend/                     # [YOUR_BACKEND_FRAMEWORK] application
│   ├── api/                     # Main API service
│   │   ├── routers/             # Route handlers
│   │   ├── services/            # Business logic
│   │   ├── schemas/             # Request/response models
│   │   ├── models/              # Database models
│   │   └── dependencies/        # Dependency injection
│   └── [functions/workers/]     # Background tasks (optional)
│
└── [shared/common/]             # Shared types/utilities (optional)
```

---

## Code Style Guidelines

### General Principles
- Write clean, readable, self-documenting code
- Use meaningful variable and function names
- Keep functions small and focused (single responsibility)
- Avoid premature optimization
- Don't add features not requested (YAGNI)

### TypeScript/JavaScript
- Use strict TypeScript mode
- Avoid `any` type - use `unknown` with type guards instead
- Prefer `interface` for object shapes, `type` for unions/intersections
- Use async/await over raw Promises
- Always handle errors appropriately

### [Python - if applicable]
- Follow PEP 8 with 100 char line limit
- Use type hints on all function signatures
- Use async/await for database and I/O operations
- Always use structured logging with context

---

## Frontend Patterns

### Component Structure
```typescript
'use client'; // Only if using hooks, state, or browser APIs

import { useState } from 'react';
// External imports first
// Internal imports second
// Types last

interface ComponentNameProps {
  // Props interface
}

export function ComponentName({ prop }: ComponentNameProps) {
  // 1. Hooks
  // 2. Derived state
  // 3. Handlers
  // 4. Effects
  // 5. Return JSX
}
```

### Data Fetching Pattern
```typescript
// Use TanStack Query for server state
const { data, isLoading, error } = useQuery({
  queryKey: ['resource', id],
  queryFn: () => fetchResource(id),
});

// Handle loading and error states
if (isLoading) return <LoadingSkeleton />;
if (error) return <ErrorMessage error={error} />;
```

### Form Pattern
```typescript
// Use React Hook Form + Zod
const schema = z.object({
  field: z.string().min(1, 'Required'),
});

const form = useForm<z.infer<typeof schema>>({
  resolver: zodResolver(schema),
});
```

### Styling Pattern
```typescript
// Use Tailwind with cn() utility for conditional classes
import { cn } from '@/lib/utils';

<div className={cn(
  'base-classes',
  condition && 'conditional-classes',
  className
)} />
```

---

## Backend Patterns

### Router Structure
```python
# [FastAPI example - adapt for your framework]
from fastapi import APIRouter, Depends, HTTPException, status

router = APIRouter(prefix="/resource", tags=["resource"])

@router.get("", response_model=ResourceList)
async def list_resources(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """List all resources for the current user."""
    service = ResourceService(db)
    return await service.get_all(user_id=current_user.id)
```

### Service Layer Pattern
```python
class ResourceService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_all(self, user_id: str) -> list[Resource]:
        # Business logic here
        pass

    async def create(self, user_id: str, data: ResourceCreate) -> Resource:
        # Validation and creation logic
        pass
```

### Error Handling Pattern
```python
import logging
import sentry_sdk

logger = logging.getLogger(__name__)

try:
    result = await service.operation()
except SpecificError as e:
    logger.warning("Expected error", extra={"error": str(e)})
    raise HTTPException(status_code=400, detail=str(e))
except Exception as e:
    logger.error("Unexpected error", extra={"error": str(e)}, exc_info=True)
    sentry_sdk.capture_exception(e)
    raise HTTPException(status_code=500, detail="Internal server error")
```

---

## Common Commands

```bash
# Frontend
cd frontend
[pnpm/npm/yarn] dev          # Start development server
[pnpm/npm/yarn] build        # Build for production
[pnpm/npm/yarn] lint         # Run ESLint
[pnpm/npm/yarn] type-check   # Run TypeScript check

# Backend
cd backend/api
source .venv/bin/activate    # Activate virtual environment
uvicorn main:app --reload    # Start development server
pytest                       # Run tests
ruff check .                 # Run linting
mypy .                       # Run type checking

# Background Workers (if applicable)
celery -A celery_app worker --loglevel=info
```

---

## Project-Specific Quirks

> **IMPORTANT**: Document any non-obvious patterns or gotchas here

### [Example Quirks - Replace with your project's]
1. **[Quirk Name]**: [Description of the quirk and why it exists]
2. **[Another Quirk]**: [Description]

---

## Pre-Commit Checklist

Before committing:
- [ ] Code compiles without errors
- [ ] Linting passes (`pnpm lint` / `ruff check .`)
- [ ] Type checking passes
- [ ] Tests pass (if applicable)
- [ ] No secrets or credentials in code
- [ ] Error handling includes logging and Sentry capture

---

## Don't Do

- Don't use `any` type in TypeScript
- Don't commit `.env` files or secrets
- Don't use `console.log` in production code (use proper logging)
- Don't catch errors without logging them
- Don't add features not explicitly requested
- Don't refactor code unrelated to the current task

---

> **Note**: This file works with Cursor's Claude models. For full Claude Code
> functionality (hooks, skills, commands), use the `.claude/` directory setup.
