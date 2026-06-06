"""Tests for attendance routes."""
import pytest
from datetime import date
from unittest.mock import AsyncMock, patch, MagicMock
from httpx import AsyncClient

from app.models.attendance import AttendanceRecord
from app.models.user import User


@pytest.mark.asyncio
async def test_get_allowed_methods(client: AsyncClient, employee_user):
    _, token = employee_user
    resp = await client.get(
        "/v1/attendance/methods",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert "allowed_methods" in data
    assert isinstance(data["allowed_methods"], list)


@pytest.mark.asyncio
async def test_generate_qr_as_manager(client: AsyncClient, manager_user):
    _, token = manager_user
    with patch("app.routers.attendance.qr_service.generate_qr_token", new_callable=AsyncMock, return_value="test.jwt.token"):
        resp = await client.get(
            "/v1/attendance/qr/generate",
            headers={"Authorization": f"Bearer {token}"},
        )
    assert resp.status_code == 200
    assert "qr_jwt" in resp.json()


@pytest.mark.asyncio
async def test_generate_qr_as_employee_forbidden(client: AsyncClient, employee_user):
    _, token = employee_user
    resp = await client.get(
        "/v1/attendance/qr/generate",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 403


@pytest.mark.asyncio
async def test_qr_verify_invalid(client: AsyncClient, employee_user):
    _, token = employee_user
    with patch("app.routers.attendance.qr_service.verify_qr_token", new_callable=AsyncMock, return_value=False):
        resp = await client.post(
            "/v1/attendance/qr/verify",
            headers={"Authorization": f"Bearer {token}"},
            json={"qr_jwt": "invalid.jwt.token"},
        )
    assert resp.status_code == 400


@pytest.mark.asyncio
async def test_qr_checkin_and_checkout(client: AsyncClient, employee_user, db):
    employee, token = employee_user

    # Check-in
    with patch("app.routers.attendance.qr_service.verify_qr_token", new_callable=AsyncMock, return_value=True):
        resp = await client.post(
            "/v1/attendance/qr/verify",
            headers={"Authorization": f"Bearer {token}"},
            json={"qr_jwt": "valid.jwt"},
        )
    assert resp.status_code == 200
    assert resp.json()["action"] == "check_in"

    # Check-out
    resp = await client.post(
        "/v1/attendance/checkout",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    assert "duration_minutes" in resp.json()
    assert resp.json()["duration_minutes"] >= 0


@pytest.mark.asyncio
async def test_double_checkin_same_day(client: AsyncClient, employee_user):
    employee, token = employee_user
    headers = {"Authorization": f"Bearer {token}"}

    with patch("app.routers.attendance.qr_service.verify_qr_token", new_callable=AsyncMock, return_value=True):
        # First check-in
        await client.post("/v1/attendance/qr/verify", headers=headers, json={"qr_jwt": "valid"})
        # Second check-in should return check-out action (or error if already checked out)
        resp2 = await client.post("/v1/attendance/qr/verify", headers=headers, json={"qr_jwt": "valid"})
    # Second mark = checkout (action: check_out) OR 400 if already done
    assert resp2.status_code in [200, 400]


@pytest.mark.asyncio
async def test_geo_checkin_outside_fence(client: AsyncClient, employee_user, org, db):
    from sqlalchemy import select
    from app.models.organization import Organization
    # Set a geofence far from the test location
    result = await db.execute(select(Organization).where(Organization.id == org.id))
    o = result.scalar_one()
    o.settings = {**o.settings, "geofence": {"lat": 0.0, "lng": 0.0, "radius_meters": 100}}
    await db.commit()

    _, token = employee_user
    resp = await client.post(
        "/v1/attendance/geo/mark",
        headers={"Authorization": f"Bearer {token}"},
        json={"lat": 28.6139, "lng": 77.2090},  # New Delhi — far from 0,0
    )
    assert resp.status_code == 400
    assert "geofence" in resp.json()["detail"]


@pytest.mark.asyncio
async def test_geo_checkin_inside_fence(client: AsyncClient, employee_user, org, db):
    from sqlalchemy import select
    from app.models.organization import Organization
    result = await db.execute(select(Organization).where(Organization.id == org.id))
    o = result.scalar_one()
    o.settings = {**o.settings, "geofence": {"lat": 28.6139, "lng": 77.2090, "radius_meters": 500}}
    await db.commit()

    _, token = employee_user
    resp = await client.post(
        "/v1/attendance/geo/mark",
        headers={"Authorization": f"Bearer {token}"},
        json={"lat": 28.6140, "lng": 77.2091},  # ~15m away — inside fence
    )
    assert resp.status_code == 200
    assert resp.json()["action"] in ["check_in", "check_out"]


@pytest.mark.asyncio
async def test_today_no_record(client: AsyncClient, employee_user):
    _, token = employee_user
    resp = await client.get(
        "/v1/attendance/today",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    # Either not_marked or an existing record
    data = resp.json()
    assert "status" in data or "date" in data


@pytest.mark.asyncio
async def test_history_pagination(client: AsyncClient, employee_user):
    _, token = employee_user
    resp = await client.get(
        "/v1/attendance/history?page=1&per_page=10",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


@pytest.mark.asyncio
async def test_face_challenge(client: AsyncClient, employee_user):
    _, token = employee_user
    with patch("app.routers.attendance.face_service.create_challenge", new_callable=AsyncMock,
               return_value={"challenge_id": "test-uuid", "motions": ["blink_twice", "smile"]}):
        resp = await client.post(
            "/v1/attendance/face/challenge",
            headers={"Authorization": f"Bearer {token}"},
        )
    assert resp.status_code == 200
    data = resp.json()
    assert "challenge_id" in data
    assert "motions" in data
    assert len(data["motions"]) == 2


@pytest.mark.asyncio
async def test_unauthorized_without_token(client: AsyncClient):
    resp = await client.get("/v1/attendance/today")
    assert resp.status_code == 403
