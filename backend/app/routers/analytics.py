"""Analytics router — team summaries, heatmaps, trends, individual reports."""
import uuid
from datetime import date, timedelta

from fastapi import APIRouter, Depends, Query
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.core.dependencies import require_manager
from app.models.attendance import AttendanceRecord
from app.models.user import User
from app.services.analytics_service import (
    compute_punctuality_score,
    compute_streaks,
    working_days_in_range,
)

router = APIRouter()


# ─── Team Summary (today) ─────────────────────────────────────────────────────

@router.get("/team/summary", summary="Today's attendance summary for the whole team")
async def team_summary(
    manager: User = Depends(require_manager),
    db: AsyncSession = Depends(get_db),
):
    today = date.today()

    # Total active employees
    emp_result = await db.execute(
        select(func.count(User.id)).where(
            User.org_id == manager.org_id,
            User.role == "employee",
            User.is_active == True,
        )
    )
    total = emp_result.scalar() or 0

    # Present today (have a check_in)
    present_result = await db.execute(
        select(func.count(AttendanceRecord.id)).where(
            AttendanceRecord.org_id == manager.org_id,
            AttendanceRecord.date == today,
            AttendanceRecord.check_in.isnot(None),
        )
    )
    present = present_result.scalar() or 0

    # Fully checked out today
    complete_result = await db.execute(
        select(func.count(AttendanceRecord.id)).where(
            AttendanceRecord.org_id == manager.org_id,
            AttendanceRecord.date == today,
            AttendanceRecord.check_out.isnot(None),
        )
    )
    complete = complete_result.scalar() or 0

    return {
        "date": today.isoformat(),
        "total_employees": total,
        "present": present,
        "absent": total - present,
        "checked_out": complete,
        "still_in_office": present - complete,
        "attendance_rate": round(present / total * 100, 1) if total else 0,
    }


# ─── Team Heatmap ─────────────────────────────────────────────────────────────

@router.get("/team/heatmap", summary="Attendance matrix: employee × date")
async def team_heatmap(
    days: int = Query(30, ge=7, le=90),
    manager: User = Depends(require_manager),
    db: AsyncSession = Depends(get_db),
):
    start = date.today() - timedelta(days=days - 1)

    # All employees
    emp_result = await db.execute(
        select(User.id, User.full_name, User.username).where(
            User.org_id == manager.org_id,
            User.role == "employee",
            User.is_active == True,
        ).order_by(User.full_name)
    )
    employees = emp_result.all()

    # All records in range
    rec_result = await db.execute(
        select(AttendanceRecord).where(
            AttendanceRecord.org_id == manager.org_id,
            AttendanceRecord.date >= start,
        )
    )
    records = rec_result.scalars().all()

    # Build lookup: user_id → {date_str: status}
    lookup: dict[uuid.UUID, dict[str, str]] = {}
    for r in records:
        uid = r.user_id
        if uid not in lookup:
            lookup[uid] = {}
        lookup[uid][r.date.isoformat()] = r.status

    # Build date list
    dates = [(start + timedelta(days=i)).isoformat() for i in range(days)]

    return {
        "dates": dates,
        "employees": [
            {
                "id": str(eid),
                "name": ename or euname,
                "data": {d: lookup.get(eid, {}).get(d, "absent") for d in dates},
            }
            for eid, ename, euname in employees
        ],
    }


# ─── Team Trends ─────────────────────────────────────────────────────────────

@router.get("/team/trends", summary="Daily attendance count over time (line chart data)")
async def team_trends(
    days: int = Query(30, ge=7, le=90),
    manager: User = Depends(require_manager),
    db: AsyncSession = Depends(get_db),
):
    start = date.today() - timedelta(days=days - 1)

    result = await db.execute(
        select(AttendanceRecord.date, func.count(AttendanceRecord.id))
        .where(
            AttendanceRecord.org_id == manager.org_id,
            AttendanceRecord.date >= start,
            AttendanceRecord.check_in.isnot(None),
        )
        .group_by(AttendanceRecord.date)
        .order_by(AttendanceRecord.date)
    )
    rows = {str(d): c for d, c in result.all()}

    # Fill missing dates with 0
    all_dates = [(start + timedelta(days=i)) for i in range(days)]
    return [{"date": d.isoformat(), "present": rows.get(d.isoformat(), 0)} for d in all_dates]


# ─── Team Method Breakdown ────────────────────────────────────────────────────

@router.get("/team/methods", summary="Breakdown of attendance methods used")
async def team_method_breakdown(
    days: int = Query(30, ge=7, le=90),
    manager: User = Depends(require_manager),
    db: AsyncSession = Depends(get_db),
):
    start = date.today() - timedelta(days=days - 1)
    result = await db.execute(
        select(AttendanceRecord.method, func.count(AttendanceRecord.id))
        .where(
            AttendanceRecord.org_id == manager.org_id,
            AttendanceRecord.date >= start,
            AttendanceRecord.method.isnot(None),
        )
        .group_by(AttendanceRecord.method)
    )
    return {method: count for method, count in result.all()}


# ─── Leaderboard ─────────────────────────────────────────────────────────────

@router.get("/team/leaderboard", summary="Employee attendance rate leaderboard")
async def leaderboard(
    days: int = Query(30, ge=7, le=90),
    manager: User = Depends(require_manager),
    db: AsyncSession = Depends(get_db),
):
    start = date.today() - timedelta(days=days - 1)
    working_days = working_days_in_range(start, date.today())

    emp_result = await db.execute(
        select(User.id, User.full_name, User.username).where(
            User.org_id == manager.org_id,
            User.role == "employee",
            User.is_active == True,
        )
    )
    employees = emp_result.all()

    rec_result = await db.execute(
        select(AttendanceRecord).where(
            AttendanceRecord.org_id == manager.org_id,
            AttendanceRecord.date >= start,
            AttendanceRecord.check_in.isnot(None),
        )
    )
    records = rec_result.scalars().all()

    # Group records by employee
    by_emp: dict[uuid.UUID, list[AttendanceRecord]] = {}
    for r in records:
        by_emp.setdefault(r.user_id, []).append(r)

    board = []
    for eid, ename, euname in employees:
        emp_records = by_emp.get(eid, [])
        present = len(emp_records)
        total_min = sum(r.duration_minutes or 0 for r in emp_records)
        board.append({
            "employee_id": str(eid),
            "name": ename or euname,
            "present_days": present,
            "attendance_rate": round(present / working_days * 100, 1) if working_days else 0,
            "total_hours": round(total_min / 60, 1),
            "punctuality_score": compute_punctuality_score(emp_records),
        })

    board.sort(key=lambda x: x["attendance_rate"], reverse=True)
    for i, item in enumerate(board):
        item["rank"] = i + 1

    return board


# ─── Individual Employee Report ───────────────────────────────────────────────

@router.get("/employee/{employee_id}/report", summary="Full report for one employee")
async def employee_report(
    employee_id: uuid.UUID,
    days: int = Query(30, ge=7, le=365),
    manager: User = Depends(require_manager),
    db: AsyncSession = Depends(get_db),
):
    start = date.today() - timedelta(days=days - 1)
    working_days = working_days_in_range(start, date.today())

    # Verify employee belongs to this org
    emp_result = await db.execute(
        select(User).where(User.id == employee_id, User.org_id == manager.org_id)
    )
    emp = emp_result.scalar_one_or_none()
    if not emp:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Employee not found")

    result = await db.execute(
        select(AttendanceRecord).where(
            AttendanceRecord.user_id == employee_id,
            AttendanceRecord.date >= start,
        ).order_by(AttendanceRecord.date)
    )
    records = result.scalars().all()

    present_records = [r for r in records if r.check_in]
    total_minutes = sum(r.duration_minutes or 0 for r in present_records)
    current_streak, longest_streak = compute_streaks(records, start)

    return {
        "employee_id": str(employee_id),
        "full_name": emp.full_name or emp.username,
        "period_days": days,
        "working_days": working_days,
        "present_days": len(present_records),
        "absent_days": working_days - len(present_records),
        "attendance_rate": round(len(present_records) / working_days * 100, 1) if working_days else 0,
        "total_hours": round(total_minutes / 60, 2),
        "avg_daily_hours": round(total_minutes / 60 / len(present_records), 2) if present_records else 0,
        "punctuality_score": compute_punctuality_score(present_records),
        "current_streak": current_streak,
        "longest_streak": longest_streak,
        "records": [
            {
                "date": r.date.isoformat(),
                "status": r.status,
                "method": r.method,
                "check_in": r.check_in.strftime("%H:%M") if r.check_in else None,
                "check_out": r.check_out.strftime("%H:%M") if r.check_out else None,
                "duration_minutes": r.duration_minutes,
            }
            for r in records
        ],
    }


# ─── Weekly Avg Hours Chart ───────────────────────────────────────────────────

@router.get("/employee/{employee_id}/hours-chart", summary="Weekly average hours chart data")
async def hours_chart(
    employee_id: uuid.UUID,
    weeks: int = Query(8, ge=2, le=26),
    manager: User = Depends(require_manager),
    db: AsyncSession = Depends(get_db),
):
    today = date.today()
    # Start from Monday of `weeks` ago
    monday = today - timedelta(days=today.weekday())
    start = monday - timedelta(weeks=weeks - 1)

    result = await db.execute(
        select(AttendanceRecord).where(
            AttendanceRecord.user_id == employee_id,
            AttendanceRecord.org_id == manager.org_id,
            AttendanceRecord.date >= start,
            AttendanceRecord.duration_minutes.isnot(None),
        ).order_by(AttendanceRecord.date)
    )
    records = result.scalars().all()

    # Group by ISO week
    weekly: dict[str, list[int]] = {}
    for r in records:
        iso = r.date.isocalendar()
        key = f"{iso.year}-W{iso.week:02d}"
        weekly.setdefault(key, []).append(r.duration_minutes or 0)

    return [
        {
            "week": week_key,
            "avg_hours": round(sum(mins) / 60 / len(mins), 2),
            "total_hours": round(sum(mins) / 60, 2),
            "days_present": len(mins),
        }
        for week_key, mins in sorted(weekly.items())
    ]
