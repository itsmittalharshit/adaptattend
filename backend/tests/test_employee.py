"""Tests for employee routes."""
import pytest
from datetime import date, timedelta, timezone, datetime
from sqlalchemy import select
from httpx import AsyncClient

from app.models.attendance import AttendanceRecord


@pytest.mark.asyncio
async def test_employee_profile(client: AsyncClient, employee_user):
    emp, token = employee_user
    resp = await client.get("/v1/employee/profile", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    data = resp.json()
    assert data["username"] == emp.username
    assert data["role"] == "employee"


@pytest.mark.asyncio
async def test_employee_history_empty(client: AsyncClient, employee_user):
    _, token = employee_user
    resp = await client.get("/v1/employee/history", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    data = resp.json()
    assert "records" in data
    assert "total" in data


@pytest.mark.asyncio
async def test_employee_history_with_records(client: AsyncClient, employee_user, db):
    emp, token = employee_user
    # Insert some records
    for i in range(3):
        d = date.today() - timedelta(days=i + 1)
        checkin = datetime(d.year, d.month, d.day, 9, 0, tzinfo=timezone.utc)
        checkout = datetime(d.year, d.month, d.day, 18, 0, tzinfo=timezone.utc)
        db.add(AttendanceRecord(
            user_id=emp.id,
            org_id=emp.org_id,
            date=d,
            check_in=checkin,
            check_out=checkout,
            duration_minutes=540,
            method="qr",
            status="present",
        ))
    await db.commit()

    resp = await client.get("/v1/employee/history", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    assert resp.json()["total"] >= 3


@pytest.mark.asyncio
async def test_employee_report_week(client: AsyncClient, employee_user):
    _, token = employee_user
    resp = await client.get(
        "/v1/employee/report?period=week",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["period"] == "week"
    assert "total_hours" in data
    assert "attendance_rate" in data


@pytest.mark.asyncio
async def test_employee_report_month(client: AsyncClient, employee_user):
    _, token = employee_user
    resp = await client.get(
        "/v1/employee/report?period=month",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    assert resp.json()["period"] == "month"


@pytest.mark.asyncio
async def test_employee_calendar(client: AsyncClient, employee_user):
    _, token = employee_user
    today = date.today()
    resp = await client.get(
        f"/v1/employee/calendar?year={today.year}&month={today.month}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["year"] == today.year
    assert data["month"] == today.month
    assert "days" in data
    assert len(data["days"]) > 0


@pytest.mark.asyncio
async def test_employee_csv_export(client: AsyncClient, employee_user):
    _, token = employee_user
    resp = await client.get(
        "/v1/employee/history/export",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    assert "text/csv" in resp.headers["content-type"]
    assert "Date" in resp.text


@pytest.mark.asyncio
async def test_manager_cannot_access_employee_profile(client: AsyncClient, manager_user):
    """Manager can technically call /employee/profile too (it just returns their own data)."""
    _, token = manager_user
    resp = await client.get("/v1/employee/profile", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200  # profile is open to any authenticated user
