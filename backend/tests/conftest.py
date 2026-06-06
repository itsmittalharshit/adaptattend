"""
Shared test fixtures.

Uses an in-memory SQLite database (aiosqlite) so no external DB is needed.
Redis is mocked via unittest.mock to avoid requiring a real Redis instance.
"""
import asyncio
import uuid
from datetime import datetime, timezone
from typing import AsyncGenerator
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker

from app.database import Base, get_db
from app.main import app
from app.core.security import hash_password, create_access_token
from app.models.organization import Organization
from app.models.user import User
from app.models.guest import GuestAccount
from app.models.attendance import AttendanceRecord
from app.services.key_service import generate_guest_key, generate_manager_key, hash_key

# ── In-memory SQLite engine for tests ────────────────────────────────────────

TEST_DB_URL = "sqlite+aiosqlite:///:memory:"
test_engine = create_async_engine(TEST_DB_URL, echo=False)
TestSession = async_sessionmaker(test_engine, expire_on_commit=False)


async def override_get_db() -> AsyncGenerator[AsyncSession, None]:
    async with TestSession() as session:
        yield session


app.dependency_overrides[get_db] = override_get_db


# ── Fixtures ──────────────────────────────────────────────────────────────────

@pytest_asyncio.fixture(scope="session")
def event_loop():
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest_asyncio.fixture(scope="session", autouse=True)
async def create_tables():
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture
async def db() -> AsyncGenerator[AsyncSession, None]:
    async with TestSession() as session:
        yield session


@pytest_asyncio.fixture
async def org(db: AsyncSession) -> Organization:
    org = Organization(
        name="Test Org",
        is_demo=True,
        settings={"allowed_methods": ["qr", "geo", "face"], "geofence": None, "office_hours": {"start": "09:00", "end": "18:00"}},
    )
    db.add(org)
    await db.commit()
    await db.refresh(org)
    return org


@pytest_asyncio.fixture
async def manager_user(db: AsyncSession, org: Organization) -> tuple[User, str]:
    mgr_key = generate_manager_key()
    user = User(
        org_id=org.id,
        username="testmanager",
        password_hash=hash_password("password123"),
        role="manager",
        full_name="Test Manager",
        email="manager@test.com",
        manager_key_hash=hash_key(mgr_key),
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    token = create_access_token({
        "sub": str(user.id),
        "role": "manager",
        "org_id": str(org.id),
    })
    # Return user, JWT token, and the plain manager_key for tests that need it
    user._plain_manager_key = mgr_key  # attach for test access
    return user, token


@pytest_asyncio.fixture
async def employee_user(db: AsyncSession, org: Organization) -> tuple[User, str]:
    user = User(
        org_id=org.id,
        username="testemployee",
        password_hash=hash_password("password123"),
        role="employee",
        full_name="Test Employee",
    )
    db.add(user)
    await db.commit()
    await db.refresh(user)
    token = create_access_token({
        "sub": str(user.id),
        "role": "employee",
        "org_id": str(org.id),
    })
    return user, token


@pytest_asyncio.fixture
async def guest_account(db: AsyncSession, org: Organization) -> tuple[GuestAccount, str]:
    key = generate_guest_key()
    guest = GuestAccount(
        email="guest@test.com",
        key_hash=hash_key(key),
        org_id=org.id,
        expires_at=datetime(2099, 1, 1, tzinfo=timezone.utc),
    )
    db.add(guest)
    await db.commit()
    await db.refresh(guest)
    return guest, key


@pytest_asyncio.fixture
async def client() -> AsyncGenerator[AsyncClient, None]:
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as ac:
        yield ac


# ── Mock Redis globally ───────────────────────────────────────────────────────

@pytest.fixture(autouse=True)
def mock_redis():
    mock = AsyncMock()
    mock.setex = AsyncMock(return_value=True)
    mock.get = AsyncMock(return_value=None)
    mock.exists = AsyncMock(return_value=0)
    mock.delete = AsyncMock(return_value=1)
    with patch("app.core.redis_client._redis", mock):
        with patch("app.core.redis_client.get_redis", return_value=AsyncMock(return_value=mock)):
            yield mock
