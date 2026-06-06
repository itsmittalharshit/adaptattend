"""Tests for auth routes — no OTP, no Gmail, manager_key second factor."""
import pytest
from httpx import AsyncClient

from app.models.organization import Organization
from app.models.user import User


@pytest.mark.asyncio
async def test_demo_info(client: AsyncClient):
    """Public demo info should return credentials without any auth."""
    resp = await client.get("/v1/auth/demo/info")
    assert resp.status_code == 200
    data = resp.json()
    assert data["guest_key"] == "AAS-DEMO-DEMO-0001"
    assert data["manager"]["manager_key"] == "MGR-DEMO-DEMO-0001"
    assert len(data["employees"]) == 5


@pytest.mark.asyncio
async def test_register_creates_org(client: AsyncClient):
    """POST /auth/register returns guest_key and manager_key immediately."""
    resp = await client.post("/v1/auth/register", json={
        "org_name": "Test Company",
        "manager_username": "boss",
        "manager_password": "SecurePass@1",
    })
    assert resp.status_code == 200
    data = resp.json()
    assert data["guest_key"].startswith("AAS-")
    assert data["manager_key"].startswith("MGR-")
    assert data["org_name"] == "Test Company"
    assert "expires_at" in data


@pytest.mark.asyncio
async def test_login_invalid_key(client: AsyncClient):
    """Invalid guest key returns 401."""
    resp = await client.post("/v1/auth/login", json={
        "guest_key": "AAS-XXXX-YYYY-ZZZZ",
        "username": "anyuser",
        "password": "anypass",
    })
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_login_employee_success(client: AsyncClient, guest_account, employee_user):
    """Employee logs in with guest_key + username + password only."""
    _, key = guest_account
    employee, _ = employee_user
    resp = await client.post("/v1/auth/login", json={
        "guest_key": key,
        "username": employee.username,
        "password": "password123",
    })
    assert resp.status_code == 200
    data = resp.json()
    assert "access_token" in data
    assert data["role"] == "employee"


@pytest.mark.asyncio
async def test_login_wrong_password(client: AsyncClient, guest_account, employee_user):
    """Wrong password returns 401."""
    _, key = guest_account
    employee, _ = employee_user
    resp = await client.post("/v1/auth/login", json={
        "guest_key": key,
        "username": employee.username,
        "password": "wrongpassword",
    })
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_login_manager_without_key_fails(client: AsyncClient, guest_account, manager_user):
    """Manager login without manager_key should fail."""
    _, key = guest_account
    manager, _ = manager_user
    resp = await client.post("/v1/auth/login", json={
        "guest_key": key,
        "username": manager.username,
        "password": "password123",
        # no manager_key
    })
    assert resp.status_code == 401
    assert "manager_key" in resp.json()["detail"].lower()


@pytest.mark.asyncio
async def test_login_manager_success(client: AsyncClient, guest_account, manager_user):
    """Manager logs in with guest_key + username + password + manager_key."""
    _, key = guest_account
    manager, _ = manager_user
    resp = await client.post("/v1/auth/login", json={
        "guest_key": key,
        "username": manager.username,
        "password": "password123",
        "manager_key": manager._plain_manager_key,
    })
    assert resp.status_code == 200
    data = resp.json()
    assert "access_token" in data
    assert data["role"] == "manager"


@pytest.mark.asyncio
async def test_login_manager_wrong_key(client: AsyncClient, guest_account, manager_user):
    """Wrong manager_key returns 401."""
    _, key = guest_account
    manager, _ = manager_user
    resp = await client.post("/v1/auth/login", json={
        "guest_key": key,
        "username": manager.username,
        "password": "password123",
        "manager_key": "MGR-FAKE-FAKE-FAKE",
    })
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_logout(client: AsyncClient):
    """Logout returns success (client-side token discard)."""
    resp = await client.post("/v1/auth/logout")
    assert resp.status_code == 200
    assert "Logged out" in resp.json()["message"]
