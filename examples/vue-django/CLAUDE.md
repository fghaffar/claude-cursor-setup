# CLAUDE.md

**Living Document** - Last Updated: 2025-01-15

This file provides guidance to Claude Code for this Vue 3 + Django project.

## Claude Code Infrastructure

This project uses Claude Code Infrastructure for enhanced development workflow.

**Key Features**:
- **Auto-Activating Skills**: Guidelines load automatically based on context
- **Build Checking Hooks**: Catches errors immediately after changes
- **Dev Docs Workflow**: Context preservation across sessions

## Quick Start

### Initial Setup
```bash
# Frontend (Vue 3 + Vite)
cd frontend
npm install
npm run dev

# Backend (Django)
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

### Common Commands
```bash
# Run tests
cd frontend && npm run test
cd backend && python manage.py test

# Code quality
cd frontend && npm run lint
cd backend && ruff check . && mypy .

# Database migrations
cd backend && python manage.py makemigrations
cd backend && python manage.py migrate
```

## Architecture Overview

### System Components
```
┌─────────────────────────────────────────────────────────────┐
│                    Frontend (Vue 3 + Vite)                   │
│  - TypeScript + Composition API                              │
│  - Pinia (state management)                                  │
│  - Vue Router + TailwindCSS                                  │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│              Backend API (Django + DRF)                      │
│  - Django REST Framework                                     │
│  - JWT Authentication                                        │
│  - Django ORM                                                │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    Database & Services                       │
│  - PostgreSQL                                                │
│  - Redis (caching, Celery broker)                            │
│  - Celery (background tasks)                                 │
└─────────────────────────────────────────────────────────────┘
```

## Environment Configuration

### Required Environment Variables
```bash
# Frontend (.env)
VITE_API_URL=http://localhost:8000/api

# Backend (.env)
DEBUG=True
SECRET_KEY=your-secret-key
DATABASE_URL=postgresql://user:pass@localhost:5432/dbname
SENTRY_DSN=https://your-dsn@sentry.io/project
ALLOWED_HOSTS=localhost,127.0.0.1
```

## Development Guidelines

### Code Style
- **Python**: Black (88 chars), Ruff, mypy
- **TypeScript/Vue**: ESLint + Prettier
- **Imports**: Absolute paths preferred

### Backend Patterns

#### Django Model
```python
from django.db import models
from django.contrib.auth import get_user_model

User = get_user_model()

class Item(models.Model):
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='items')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return self.title
```

#### DRF Serializer
```python
from rest_framework import serializers
from .models import Item

class ItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = Item
        fields = ['id', 'title', 'description', 'created_at', 'updated_at']
        read_only_fields = ['id', 'created_at', 'updated_at']
```

#### DRF ViewSet
```python
from rest_framework import viewsets, permissions
from .models import Item
from .serializers import ItemSerializer

class ItemViewSet(viewsets.ModelViewSet):
    serializer_class = ItemSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Item.objects.filter(user=self.request.user)

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)
```

### Frontend Patterns

#### Vue Component (Composition API)
```vue
<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useItemStore } from '@/stores/item'

interface Props {
  itemId: string
}

const props = defineProps<Props>()
const store = useItemStore()

const item = computed(() => store.getItemById(props.itemId))
const isLoading = ref(true)

onMounted(async () => {
  await store.fetchItem(props.itemId)
  isLoading.value = false
})
</script>

<template>
  <div v-if="isLoading" class="loading">Loading...</div>
  <div v-else-if="item" class="item-detail">
    <h1>{{ item.title }}</h1>
    <p>{{ item.description }}</p>
  </div>
</template>
```

#### Pinia Store
```typescript
import { defineStore } from 'pinia'
import { api } from '@/lib/api'

interface Item {
  id: string
  title: string
  description: string
}

export const useItemStore = defineStore('items', {
  state: () => ({
    items: [] as Item[],
    loading: false,
  }),

  getters: {
    getItemById: (state) => (id: string) => {
      return state.items.find(item => item.id === id)
    },
  },

  actions: {
    async fetchItems() {
      this.loading = true
      try {
        this.items = await api.get('/items/')
      } finally {
        this.loading = false
      }
    },
  },
})
```

### Error Handling
```python
# Backend - DRF exception handler
import logging
import sentry_sdk
from rest_framework.views import exception_handler

logger = logging.getLogger(__name__)

def custom_exception_handler(exc, context):
    response = exception_handler(exc, context)

    if response is None:
        logger.error("Unhandled exception", exc_info=exc)
        sentry_sdk.capture_exception(exc)

    return response
```

## Pre-Commit Checklist

### Frontend
- [ ] `npm run lint` passes
- [ ] `npm run type-check` passes
- [ ] No `any` types
- [ ] Tests pass

### Backend
- [ ] `ruff check .` passes
- [ ] `mypy .` passes
- [ ] `python manage.py test` passes
- [ ] Migrations created if models changed

### General
- [ ] No secrets committed
- [ ] Environment variables documented
