# CLAUDE.md

**Living Document** - Last Updated: 2025-01-15

This file provides guidance to Claude Code for this React + Express.js project.

## Claude Code Infrastructure

This project uses Claude Code Infrastructure for enhanced development workflow.

**Key Features**:
- **Auto-Activating Skills**: Guidelines load automatically based on context
- **Build Checking Hooks**: Catches errors immediately after changes
- **Dev Docs Workflow**: Context preservation across sessions

## Quick Start

### Initial Setup
```bash
# Frontend (React + Vite)
cd client
npm install
npm run dev

# Backend (Express)
cd server
npm install
npm run dev
```

### Common Commands
```bash
# Run tests
cd client && npm test
cd server && npm test

# Code quality
cd client && npm run lint
cd server && npm run lint

# Build
cd client && npm run build
```

## Architecture Overview

### System Components
```
┌─────────────────────────────────────────────────────────────┐
│                    Frontend (React + Vite)                   │
│  - TypeScript + React 18                                    │
│  - TanStack Query / Redux Toolkit                           │
│  - Tailwind CSS / styled-components                         │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                Backend API (Express + Node.js)               │
│  - TypeScript + Express                                      │
│  - JWT Authentication                                        │
│  - Prisma / Mongoose ORM                                     │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Database & Services                       │
│  - PostgreSQL / MongoDB                                      │
│  - Redis (sessions, caching)                                 │
│  - Bull/BullMQ (job queue)                                   │
└─────────────────────────────────────────────────────────────┘
```

## Environment Configuration

### Required Environment Variables
```bash
# Client (.env)
VITE_API_URL=http://localhost:3001

# Server (.env)
DATABASE_URL=postgresql://user:pass@localhost:5432/dbname
JWT_SECRET=your-secret-key
SENTRY_DSN=https://your-dsn@sentry.io/project
PORT=3001
```

## Development Guidelines

### Code Style
- **TypeScript**: ESLint + Prettier, strict mode
- **Imports**: Absolute paths (`@/components` not `../../components`)
- **Naming**: PascalCase components, camelCase functions

### Backend Patterns

#### Express Router
```typescript
import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import { ItemController } from '../controllers/item.controller';

const router = Router();
const controller = new ItemController();

router.get('/', authenticate, controller.getAll);
router.post('/', authenticate, controller.create);
router.get('/:id', authenticate, controller.getById);
router.put('/:id', authenticate, controller.update);
router.delete('/:id', authenticate, controller.delete);

export default router;
```

#### Controller Pattern
```typescript
import { Request, Response, NextFunction } from 'express';
import { ItemService } from '../services/item.service';

export class ItemController {
  private service = new ItemService();

  getAll = async (req: Request, res: Response, next: NextFunction) => {
    try {
      const items = await this.service.findAll(req.user.id);
      res.json(items);
    } catch (error) {
      next(error);
    }
  };
}
```

### Frontend Patterns

#### Component Structure
```typescript
import { useState, useEffect } from 'react';
import { useQuery } from '@tanstack/react-query';

interface Props {
  id: string;
}

export function ItemDetail({ id }: Props) {
  const { data, isLoading, error } = useQuery({
    queryKey: ['item', id],
    queryFn: () => fetchItem(id),
  });

  if (isLoading) return <Loading />;
  if (error) return <Error error={error} />;

  return <div>{data.name}</div>;
}
```

### Error Handling
```typescript
// Backend - Global error handler
app.use((err: Error, req: Request, res: Response, next: NextFunction) => {
  logger.error('Unhandled error', { error: err.message, stack: err.stack });
  Sentry.captureException(err);
  res.status(500).json({ error: 'Internal server error' });
});

// Frontend - API error handling
const fetchItem = async (id: string) => {
  const response = await fetch(`/api/items/${id}`);
  if (!response.ok) {
    throw new Error(`Failed to fetch item: ${response.statusText}`);
  }
  return response.json();
};
```

## Pre-Commit Checklist

### Frontend
- [ ] `npm run lint` passes
- [ ] `npm run type-check` passes
- [ ] No `any` types
- [ ] Tests pass

### Backend
- [ ] `npm run lint` passes
- [ ] `npm run type-check` passes
- [ ] All routes have error handling
- [ ] Tests pass

### General
- [ ] No secrets committed
- [ ] Environment variables documented
