"""Tests for manager routes."""
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_list_employees(client: AsyncClient, manager_user, employee_user):
    _, token = manager_user
    resp = await client.get("/v1/manager/employees", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)
    assert len(resp.json()) >= 1  # at least one employee exists from fixture


@pytest.mark.asyncio
async def test_create_employee(client: AsyncClient, manager_user):
    _, token = manager_user
    resp = await client.post(
        "/v1/manager/employees",
        headers={"Authorization": f"Bearer {token}"},
        json={"username": "newstaff", "password": "Pass@1234", "full_name": "New Staff"},
    )
    assert resp.status_code == 201
    assert resp.json()["username"] == "newstaff"


@pytest.mark.asyncio
async def test_create_duplicate_employee(client: AsyncClient, manager_user, employee_user):
    _, token = manager_user
    emp, _ = employee_user
    resp = await client.post(
        "/v1/manager/employees",
        headers={"Authorization": f"Bearer {token}"},
        json={"username": emp.username, "password": "Pass@1234"},
    )
    assert resp.status_code == 409


@pytest.mark.asyncio
async def test_get_employee(client: AsyncClient, manager_user, employee_user):
    _, token = manager_user
    emp, _ = employee_user
    resp = await client.get(
        f"/v1/manager/employees/{emp.id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    assert resp.json()["id"] == str(emp.id)


@pytest.mark.asyncio
async def test_deactivate_employee(client: AsyncClient, manager_user, db):
    from app.core.security import hash_password
    from app.models.user import User
    from sqlalchemy import select
    _, token = manager_user
    manager, _ = manager_user

    # Create a throwaway employee to deactivate
    result = await db.execute(select(User).where(User.username == "manager", User.org_id == manager.org_id))
    mgr = result.scalar_one()
    emp = User(
        org_id=mgr.org_id,
        username="todeactivate",
        password_hash=hash_password("x"),
        role="employee",
    )
    db.add(emp)
    await db.commit()

    resp = await client.delete(
        f"/v1/manager/employees/{emp.id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    assert resp.json()["status"] == "deactivated"


@pytest.mark.asyncio
async def test_get_settings(client: AsyncClient, manager_user):
    _, token = manager_user
    resp = await client.get("/v1/manager/settings", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    data = resp.json()
    assert "allowed_methods" in data
    assert isinstance(data["allowed_methods"], list)


@pytest.mark.asyncio
async def test_update_settings_valid(client: AsyncClient, manager_user):
    _, token = manager_user
    resp = await client.put(
        "/v1/manager/settings",
        headers={"Authorization": f"Bearer {token}"},
        json={"allowed_methods": ["qr", "geo"]},
    )
    assert resp.status_code == 200
    assert "qr" in resp.json()["allowed_methods"]
    assert "geo" in resp.json()["allowed_methods"]


@pytest.mark.asyncio
async def test_update_settings_invalid_method(client: AsyncClient, manager_user):
    _, token = manager_user
    resp = await client.put(
        "/v1/manager/settings",
        headers={"Authorization": f"Bearer {token}"},
        json={"allowed_methods": ["qr", "invalid_method"]},
    )
    assert resp.status_code == 422


@pytest.mark.asyncio
async def test_set_geofence(client: AsyncClient, manager_user):
    _, token = manager_user
    resp = await client.put(
        "/v1/manager/settings",
        headers={"Authorization": f"Bearer {token}"},
        json={"geofence": {"lat": 28.6139, "lng": 77.2090, "radius_meters": 200}},
    )
    assert resp.status_code == 200
    assert resp.json()["geofence"]["radius_meters"] == 200


@pytest.mark.asyncio
async def test_employee_cannot_access_manager_routes(client: AsyncClient, employee_user):
    _, token = employee_user
    resp = await client.get("/v1/manager/employees", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 403


@pytest.mark.asyncio
async def test_attendance_view(client: AsyncClient, manager_user):
    _, token = manager_user
    resp = await client.get("/v1/manager/attendance", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


@pytest.mark.asyncio
async def test_manager_profile(client: AsyncClient, manager_user):
    _, token = manager_user
    resp = await client.get("/v1/manager/profile", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    assert resp.json()["role"] == "manager"
