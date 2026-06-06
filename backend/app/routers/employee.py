"""Employee router — profile, attendance history, time report."""
import csv
import io
from datetime import date, datetime, timedelta, timezone

from fastapi import APIRouter, Depends, Query
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.core.dependencies import get_current_user
from app.models.attendance import AttendanceRecord
from app.models.user import User

router = APIRouter()


# ─── Profile ──────────────────────────────────────────────────────────────────

@router.get("/profile", summary="Get employee profile")
async def profile(user: User = Depends(get_current_user)):
    return {
        "id": str(user.id),
        "username": user.username,
        "full_name": user.full_name,
        "email": user.email,
        "role": user.role,
        "org_id": str(user.org_id),
    }


# ─── Attendance History ───────────────────────────────────────────────────────

@router.get("/history", summary="Paginated attendance history")
async def history(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    month: int | None = Query(None, ge=1, le=12),
    year: int | None = Query(None, ge=2020),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    filters = [AttendanceRecord.user_id == user.id]
    if year and month:
        start = date(year, month, 1)
        end = date(year, month + 1, 1) if month < 12 else date(year + 1, 1, 1)
        filters += [AttendanceRecord.date >= start, AttendanceRecord.date < end]

    offset = (page - 1) * per_page
    result = await db.execute(
        select(AttendanceRecord)
        .where(and_(*filters))
        .order_by(AttendanceRecord.date.desc())
        .offset(offset)
        .limit(per_page)
    )
    records = result.scalars().all()

    # Total count for pagination
    count_result = await db.execute(
        select(func.count(AttendanceRecord.id)).where(and_(*filters))
    )
    total = count_result.scalar()

    return {
        "total": total,
        "page": page,
        "per_page": per_page,
        "records": [_format_record(r) for r in records],
    }


# ─── Time Report ──────────────────────────────────────────────────────────────

@router.get("/report", summary="Weekly/monthly time summary")
async def report(
    period: str = Query("month", pattern="^(week|month)$"),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    today = date.today()
    if period == "week":
        start = today - timedelta(days=today.weekday())  # Monday
    else:
        start = today.replace(day=1)

    result = await db.execute(
        select(AttendanceRecord).where(
            AttendanceRecord.user_id == user.id,
            AttendanceRecord.date >= start,
            AttendanceRecord.date <= today,
        ).order_by(AttendanceRecord.date)
    )
    records = result.scalars().all()

    present_days = len([r for r in records if r.check_in])
    total_minutes = sum(r.duration_minutes or 0 for r in records)
    complete_days = len([r for r in records if r.check_out])
    incomplete_days = len([r for r in records if r.check_in and not r.check_out])

    working_days = _working_days_in_range(start, today)

    return {
        "period": period,
        "start_date": start.isoformat(),
        "end_date": today.isoformat(),
        "working_days": working_days,
        "present_days": present_days,
        "complete_days": complete_days,
        "incomplete_days": incomplete_days,
        "absent_days": max(0, working_days - present_days),
        "total_hours": round(total_minutes / 60, 2),
        "avg_daily_hours": round(total_minutes / 60 / present_days, 2) if present_days else 0,
        "attendance_rate": round(present_days / working_days * 100, 1) if working_days else 0,
        "daily_breakdown": [_format_record(r) for r in records],
    }


# ─── Calendar View ────────────────────────────────────────────────────────────

@router.get("/calendar", summary="Calendar view for a given month")
async def calendar_view(
    year: int = Query(..., ge=2020),
    month: int = Query(..., ge=1, le=12),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    start = date(year, month, 1)
    end = date(year, month + 1, 1) if month < 12 else date(year + 1, 1, 1)

    result = await db.execute(
        select(AttendanceRecord).where(
            AttendanceRecord.user_id == user.id,
            AttendanceRecord.date >= start,
            AttendanceRecord.date < end,
        )
    )
    records = {r.date: r for r in result.scalars().all()}

    calendar_data = {}
    current = start
    while current < end:
        r = records.get(current)
        calendar_data[current.isoformat()] = {
            "status": r.status if r else ("weekend" if current.weekday() >= 5 else "absent"),
            "method": r.method if r else None,
            "check_in": r.check_in.strftime("%H:%M") if (r and r.check_in) else None,
            "check_out": r.check_out.strftime("%H:%M") if (r and r.check_out) else None,
            "duration_minutes": r.duration_minutes if r else None,
        }
        current += timedelta(days=1)

    return {
        "year": year,
        "month": month,
        "days": calendar_data,
    }


# ─── Export CSV ───────────────────────────────────────────────────────────────

@router.get("/history/export", summary="Export own attendance as CSV")
async def export_history(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(AttendanceRecord)
        .where(AttendanceRecord.user_id == user.id)
        .order_by(AttendanceRecord.date.desc())
    )
    records = result.scalars().all()

    output = io.StringIO()
    writer = csv.DictWriter(output, fieldnames=[
        "Date", "Status", "Method", "Check-In", "Check-Out", "Duration (min)", "Hours",
    ])
    writer.writeheader()
    for r in records:
        writer.writerow({
            "Date": r.date.isoformat(),
            "Status": r.status,
            "Method": r.method or "",
            "Check-In": r.check_in.strftime("%H:%M") if r.check_in else "",
            "Check-Out": r.check_out.strftime("%H:%M") if r.check_out else "",
            "Duration (min)": r.duration_minutes or "",
            "Hours": round(r.duration_minutes / 60, 2) if r.duration_minutes else "",
        })

    output.seek(0)
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": 'attachment; filename="my_attendance.csv"'},
    )


# ─── Helpers ──────────────────────────────────────────────────────────────────

def _format_record(r: AttendanceRecord) -> dict:
    return {
        "id": str(r.id),
        "date": r.date.isoformat(),
        "status": r.status,
        "method": r.method,
        "check_in": r.check_in.strftime("%H:%M") if r.check_in else None,
        "check_out": r.check_out.strftime("%H:%M") if r.check_out else None,
        "duration_minutes": r.duration_minutes,
        "hours": round(r.duration_minutes / 60, 2) if r.duration_minutes else None,
    }


def _working_days_in_range(start: date, end: date) -> int:
    count = 0
    current = start
    while current <= end:
        if current.weekday() < 5:  # Mon–Fri
            count += 1
        current += timedelta(days=1)
    return count
