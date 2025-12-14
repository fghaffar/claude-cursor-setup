---
description: Backend development guidelines for FastAPI + Python with PostgreSQL/pgvector and async patterns
trigger_keywords: ["backend", "fastapi", "api", "endpoint", "router", "database", "postgresql"]
---

# Backend Development Guidelines

## Tech Stack

- **Framework**: FastAPI
- **Language**: Python 3.11+
- **Database**: PostgreSQL with pgvector (vector search)
- **ORM**: SQLAlchemy 2.0 (async)
- **Validation**: Pydantic v2
- **Task Queue**: Celery + Redis (optional)
- **Caching**: Redis
- **Monitoring**: Sentry
- **Testing**: pytest + pytest-asyncio

## Project Structure

```
backend/
├── api/
│   ├── main.py                 # FastAPI application entry
│   ├── config.py               # Settings and configuration
│   ├── routers/               # API route handlers
│   │   ├── __init__.py
│   │   ├── users.py
│   │   └── items.py
│   ├── schemas/               # Pydantic models (request/response)
│   │   ├── __init__.py
│   │   ├── users.py
│   │   └── items.py
│   ├── models/                # SQLAlchemy models
│   │   ├── __init__.py
│   │   └── base.py
│   ├── services/              # Business logic layer
│   │   └── user_service.py
│   ├── repositories/          # Data access layer
│   │   └── user_repository.py
│   ├── dependencies/          # FastAPI dependencies
│   │   ├── auth.py
│   │   └── database.py
│   ├── middleware/            # Custom middleware
│   └── utils/                 # Utility functions
├── tests/
│   ├── conftest.py
│   └── routers/
└── requirements.txt
```

## Router Patterns

### Basic Router Structure

```python
from fastapi import APIRouter, Depends, HTTPException, status
from typing import Annotated

from schemas.items import ItemCreate, ItemResponse, ItemList
from services.item_service import ItemService
from dependencies.auth import get_current_user
from dependencies.database import get_db

router = APIRouter(prefix="/items", tags=["items"])

@router.get("", response_model=ItemList)
async def list_items(
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
    skip: int = 0,
    limit: int = 100,
):
    """List all items for the current user."""
    service = ItemService(db)
    items = await service.get_items(user_id=current_user.id, skip=skip, limit=limit)
    return ItemList(items=items, total=len(items))


@router.post("", response_model=ItemResponse, status_code=status.HTTP_201_CREATED)
async def create_item(
    item_data: ItemCreate,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Create a new item."""
    service = ItemService(db)
    item = await service.create_item(user_id=current_user.id, data=item_data)
    return item


@router.get("/{item_id}", response_model=ItemResponse)
async def get_item(
    item_id: str,
    db: Annotated[AsyncSession, Depends(get_db)],
    current_user: Annotated[User, Depends(get_current_user)],
):
    """Get a specific item by ID."""
    service = ItemService(db)
    item = await service.get_item(item_id=item_id, user_id=current_user.id)
    if not item:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Item {item_id} not found"
        )
    return item
```

## Pydantic Schemas

### Request/Response Models

```python
from pydantic import BaseModel, Field, ConfigDict
from datetime import datetime
from typing import Optional

# Base model with common config
class BaseSchema(BaseModel):
    model_config = ConfigDict(from_attributes=True)

# Request schema (what client sends)
class ItemCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=1000)
    price: float = Field(..., gt=0)

# Response schema (what API returns)
class ItemResponse(BaseSchema):
    id: str
    title: str
    description: Optional[str]
    price: float
    created_at: datetime
    updated_at: datetime

# List response with pagination
class ItemList(BaseModel):
    items: list[ItemResponse]
    total: int
    page: int = 1
    page_size: int = 100

# Update schema (partial updates)
class ItemUpdate(BaseModel):
    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=1000)
    price: Optional[float] = Field(None, gt=0)
```

## SQLAlchemy Models

### Model Definition

```python
from sqlalchemy import Column, String, Float, DateTime, ForeignKey, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from pgvector.sqlalchemy import Vector

from models.base import Base

class Item(Base):
    __tablename__ = "items"

    id = Column(String, primary_key=True, default=lambda: str(uuid4()))
    title = Column(String(200), nullable=False, index=True)
    description = Column(Text, nullable=True)
    price = Column(Float, nullable=False)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)

    # Vector embedding for semantic search
    embedding = Column(Vector(1536), nullable=True)

    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    user = relationship("User", back_populates="items")
```

## Service Layer

### Business Logic

```python
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import Optional

from models.item import Item
from schemas.items import ItemCreate, ItemUpdate

class ItemService:
    def __init__(self, db: AsyncSession):
        self.db = db

    async def get_items(
        self,
        user_id: str,
        skip: int = 0,
        limit: int = 100
    ) -> list[Item]:
        query = (
            select(Item)
            .where(Item.user_id == user_id)
            .offset(skip)
            .limit(limit)
        )
        result = await self.db.execute(query)
        return result.scalars().all()

    async def get_item(
        self,
        item_id: str,
        user_id: str
    ) -> Optional[Item]:
        query = select(Item).where(
            Item.id == item_id,
            Item.user_id == user_id
        )
        result = await self.db.execute(query)
        return result.scalar_one_or_none()

    async def create_item(
        self,
        user_id: str,
        data: ItemCreate
    ) -> Item:
        item = Item(
            user_id=user_id,
            **data.model_dump()
        )
        self.db.add(item)
        await self.db.commit()
        await self.db.refresh(item)
        return item

    async def update_item(
        self,
        item: Item,
        data: ItemUpdate
    ) -> Item:
        update_data = data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(item, field, value)
        await self.db.commit()
        await self.db.refresh(item)
        return item
```

## Error Handling

### Custom Exception Handler

```python
import logging
import sentry_sdk
from fastapi import Request, HTTPException
from fastapi.responses import JSONResponse

logger = logging.getLogger(__name__)

async def exception_handler(request: Request, exc: Exception):
    # Log the error with context
    logger.error(
        "Unhandled exception",
        extra={
            "path": request.url.path,
            "method": request.method,
            "error": str(exc),
        },
        exc_info=True
    )

    # Capture in Sentry
    sentry_sdk.capture_exception(exc)

    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error"}
    )

# Register in main.py
app.add_exception_handler(Exception, exception_handler)
```

### Service-Level Error Handling

```python
async def create_item(self, user_id: str, data: ItemCreate) -> Item:
    try:
        item = Item(user_id=user_id, **data.model_dump())
        self.db.add(item)
        await self.db.commit()
        await self.db.refresh(item)
        return item
    except IntegrityError as e:
        await self.db.rollback()
        logger.error("Database integrity error", extra={"error": str(e)})
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Item already exists"
        )
    except Exception as e:
        await self.db.rollback()
        logger.error("Failed to create item", extra={"error": str(e)}, exc_info=True)
        sentry_sdk.capture_exception(e)
        raise
```

## Dependencies

### Database Session

```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from typing import AsyncGenerator

from config import settings

engine = create_async_engine(settings.database_url, echo=settings.debug)
AsyncSessionLocal = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()
```

### Authentication

```python
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Annotated

security = HTTPBearer()

async def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials, Depends(security)],
    db: Annotated[AsyncSession, Depends(get_db)],
) -> User:
    token = credentials.credentials
    try:
        payload = decode_token(token)
        user_id = payload.get("sub")
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token"
            )
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token"
        )

    user = await UserService(db).get_user(user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found"
        )
    return user
```

## Vector Search with pgvector

```python
from pgvector.sqlalchemy import Vector
from sqlalchemy import select

class ItemService:
    async def search_similar(
        self,
        embedding: list[float],
        limit: int = 10
    ) -> list[Item]:
        """Find items similar to the given embedding."""
        query = (
            select(Item)
            .order_by(Item.embedding.cosine_distance(embedding))
            .limit(limit)
        )
        result = await self.db.execute(query)
        return result.scalars().all()
```

## Testing

### pytest Setup

```python
# conftest.py
import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession

from main import app
from dependencies.database import get_db

@pytest.fixture
async def db_session():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    async with AsyncSession(engine) as session:
        yield session

@pytest.fixture
async def client(db_session):
    async def override_get_db():
        yield db_session

    app.dependency_overrides[get_db] = override_get_db
    async with AsyncClient(app=app, base_url="http://test") as client:
        yield client
    app.dependency_overrides.clear()
```

### Test Example

```python
import pytest

@pytest.mark.asyncio
async def test_create_item(client, auth_headers):
    response = await client.post(
        "/items",
        json={"title": "Test Item", "price": 19.99},
        headers=auth_headers
    )
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == "Test Item"
    assert data["price"] == 19.99
```

## Best Practices

1. **Always use async**: Use `async/await` for database operations
2. **Type hints**: Add type hints to all functions
3. **Validation**: Use Pydantic for request/response validation
4. **Error handling**: Catch and log all exceptions
5. **Logging**: Use structured logging with context
6. **Testing**: Write tests for all endpoints
7. **Security**: Never expose internal errors to clients

---

**CUSTOMIZE THIS FILE** for your specific database, authentication, and project conventions.
