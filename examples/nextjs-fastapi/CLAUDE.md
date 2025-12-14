# CLAUDE.md

**Living Document** - Last Updated: 2025-01-15

This file provides global guidance to Claude Code when working with this Next.js + FastAPI project.

## Claude Code Infrastructure

This project uses the **Claude Code Infrastructure System** for enhanced development workflow.

**Key Features**:
- **Auto-Activating Skills**: Frontend/backend guidelines load automatically
- **Build Checking Hooks**: Catches TypeScript/Python errors immediately
- **Dev Docs Workflow**: Never lose context across long sessions

## Quick Start

### Initial Setup
```bash
# Frontend
cd frontend
pnpm install
pnpm dev

# Backend
cd backend/api
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --reload

# Background Workers (if applicable)
cd backend/functions
source .venv/bin/activate
celery -A celery_app worker --loglevel=info
```

### Common Commands
```bash
# Run tests
cd frontend && pnpm test
cd backend/api && pytest

# Code quality
cd frontend && pnpm lint
cd backend/api && ruff check . && mypy .
```

## Architecture Overview

### System Components
```
┌─────────────────────────────────────────────────────────────┐
│                    Frontend (Next.js 15)                     │
│  - React 19 + TypeScript                                    │
│  - TanStack Query + Zustand                                 │
│  - Tailwind CSS + shadcn/ui                                 │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│              Backend API (FastAPI + Python 3.11)             │
│  - REST endpoints with JWT auth                              │
│  - Pydantic v2 validation                                    │
│  - Async/await patterns                                      │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Database & Services                       │
│  - PostgreSQL / MongoDB                                      │
│  - Redis (caching, task queue)                               │
│  - Celery (background tasks)                                 │
└─────────────────────────────────────────────────────────────┘
```

## Environment Configuration

### Required Environment Variables
```bash
# Frontend (.env.local)
NEXT_PUBLIC_API_URL=http://localhost:8000

# Backend (.env)
DATABASE_URL=postgresql://user:pass@localhost:5432/dbname
SECRET_KEY=your-secret-key
SENTRY_DSN=https://your-dsn@sentry.io/project
```

## Development Guidelines

### Code Style
- **Python**: Black (100 chars), Ruff, mypy strict
- **TypeScript**: ESLint + Prettier, strict mode
- **Imports**: Absolute imports (`@/components` not `../../components`)

### Error Handling Patterns
```python
# Backend: Always use structured logging
logger.error("Failed to process", extra={
    "item_id": item_id,
    "error": str(e),
})
sentry_sdk.capture_exception(e)

# Frontend: Parse API errors
if (!response.ok) {
  const error = await response.json();
  throw new Error(error.detail || 'Unknown error');
}
```

## Project Quirks & Gotchas

### Backend Quirks

#### 1. Always import datetime with timedelta
```python
# Wrong
from datetime import datetime
expiry = datetime.utcnow() + timedelta(hours=1)  # NameError!

# Correct
from datetime import datetime, timedelta
expiry = datetime.utcnow() + timedelta(hours=1)
```

#### 2. Activate venv before running Python
```bash
cd backend/api
source .venv/bin/activate
python scripts/some_script.py
```

### Frontend Quirks

#### 3. 'use client' must be first line
```typescript
// Wrong
import { useState } from 'react';
'use client';

// Correct
'use client';
import { useState } from 'react';
```

#### 4. Round durations to integers for API calls
```typescript
// Backend expects integer seconds
setDuration(Math.round(audio.duration));
```

## Pre-Commit Checklist

### Frontend
- [ ] `pnpm lint` - No ESLint errors
- [ ] `pnpm type-check` - No TypeScript errors
- [ ] No `any` types in new code
- [ ] 'use client' first line if using hooks

### Backend
- [ ] `source .venv/bin/activate` active
- [ ] `ruff check .` - No linting errors
- [ ] `mypy .` - No type errors
- [ ] `pytest` - All tests pass
- [ ] Structured logging with `extra={}` context

### General
- [ ] No secrets committed
- [ ] Environment variables documented
- [ ] CLAUDE.md updated if patterns changed

## Additional Documentation

- **Claude Code Skills**: [.claude/skills/](.claude/skills/)
- **Dev Docs**: [dev/active/](dev/active/)
