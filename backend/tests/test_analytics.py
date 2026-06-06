"""Tests for analytics routes and analytics service."""
import pytest
from datetime import date, timedelta, timezone, datetime
from httpx import AsyncClient

from app.services.analytics_service import (
    compute_punctuality_score,
    compute_streaks,
    working_days_in_range,
)


# ─── Analytics service unit tests ─────────────────────────────────────────────

def test_punctuality_score_empty():
    assert compute_punctuality_score([]) == 0.0


def test_punctuality_score_on_time():
    """Check-in at 08:55 → 100 points."""
    class FakeRecord:
        check_in = datetime(2024, 1, 15, 8, 55, tzinfo=timezone.utc)
    assert compute_punctuality_score([FakeRecord()]) == 100.0


def test_punctuality_score_very_late():
    """Check-in at 11:00 → 0 points."""
    class FakeRecord:
        check_in = datetime(2024, 1, 15, 11, 0, tzinfo=timezone.utc)
    assert compute_punctuality_score([FakeRecord()]) == 0.0


def test_punctuality_score_mixed():
    class FakeRecord:
        def __init__(self, hour, minute):
            self.check_in = datetime(2024, 1, 15, hour, minute, tzinfo=timezone.utc)
    records = [FakeRecord(8, 55), FakeRecord(11, 0)]  # 100 + 0 = avg 50
    assert compute_punctuality_score(records) == 50.0


def test_working_days_full_week():
    monday = date(2024, 1, 8)
    friday = date(2024, 1, 12)
    assert working_days_in_range(monday, friday) == 5


def test_working_days_includes_weekend():
    monday = date(2024, 1, 8)
    sunday = date(2024, 1, 14)
    assert working_days_in_range(monday, sunday) == 5  # only Mon–Fri counted


def test_streaks_all_present():
    today = date.today()
    class FakeRecord:
        def __init__(self, d):
            self.date = d
            self.check_in = True
    # 5 consecutive weekdays
    weekdays = []
    d = today - timedelta(days=today.weekday())  # Monday
    for i in range(5):
        weekdays.append(FakeRecord(d + timedelta(days=i)))
    current, longest = compute_streaks(weekdays, today - timedelta(days=6))
    assert longest >= 5


def test_streaks_empty():
    current, longest = compute_streaks([], date.today())
    assert current == 0
    assert longest == 0


# ─── Analytics route tests ────────────────────────────────────────────────────

@pytest.mark.asyncio
async def test_team_summary(client: AsyncClient, manager_user):
    _, token = manager_user
    resp = await client.get("/v1/analytics/team/summary", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    data = resp.json()
    assert "present" in data
    assert "total_employees" in data
    assert "attendance_rate" in data


@pytest.mark.asyncio
async def test_team_heatmap(client: AsyncClient, manager_user):
    _, token = manager_user
    resp = await client.get("/v1/analytics/team/heatmap?days=7", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    data = resp.json()
    assert "dates" in data
    assert "employees" in data
    assert len(data["dates"]) == 7


@pytest.mark.asyncio
async def test_team_trends(client: AsyncClient, manager_user):
    _, token = manager_user
    resp = await client.get("/v1/analytics/team/trends?days=14", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    data = resp.json()
    assert isinstance(data, list)
    assert len(data) == 14
    assert "date" in data[0]
    assert "present" in data[0]


@pytest.mark.asyncio
async def test_leaderboard(client: AsyncClient, manager_user):
    _, token = manager_user
    resp = await client.get("/v1/analytics/team/leaderboard", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    data = resp.json()
    assert isinstance(data, list)
    if data:
        assert "rank" in data[0]
        assert "attendance_rate" in data[0]


@pytest.mark.asyncio
async def test_employee_report(client: AsyncClient, manager_user, employee_user):
    _, token = manager_user
    emp, _ = employee_user
    resp = await client.get(
        f"/v1/analytics/employee/{emp.id}/report?days=30",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 200
    data = resp.json()
    assert data["employee_id"] == str(emp.id)
    assert "attendance_rate" in data
    assert "punctuality_score" in data
    assert "records" in data


@pytest.mark.asyncio
async def test_method_breakdown(client: AsyncClient, manager_user):
    _, token = manager_user
    resp = await client.get("/v1/analytics/team/methods", headers={"Authorization": f"Bearer {token}"})
    assert resp.status_code == 200
    assert isinstance(resp.json(), dict)


@pytest.mark.asyncio
async def test_employee_not_in_org_returns_404(client: AsyncClient, manager_user):
    import uuid
    _, token = manager_user
    fake_id = uuid.uuid4()
    resp = await client.get(
        f"/v1/analytics/employee/{fake_id}/report",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 404
