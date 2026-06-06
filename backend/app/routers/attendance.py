"""Attendance router — QR, Geo, Face check-in/check-out."""
import uuid
from datetime import datetime, date, timezone

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.core.dependencies import get_current_user, require_manager
from app.models.attendance import AttendanceRecord
from app.models.face_data import FaceData
from app.models.organization import Organization
from app.models.user import User
from app.services import qr_service, face_service, geo_service

router = APIRouter()


# ── QR ──────────────────────────────────────────────────────────────────────

@router.get("/qr/generate")
async def generate_qr(manager: User = Depends(require_manager)):
    token_jwt = await qr_service.generate_qr_token(manager.org_id)
    return {"qr_jwt": token_jwt, "refresh_seconds": 10}


class QRVerifyRequest(BaseModel):
    qr_jwt: str


@router.post("/qr/verify")
async def verify_qr(
    body: QRVerifyRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    valid = await qr_service.verify_qr_token(body.qr_jwt, user.org_id)
    if not valid:
        raise HTTPException(status_code=400, detail="Invalid or expired QR code")
    return await _mark_attendance(db, user, method="qr")


# ── Geolocation ──────────────────────────────────────────────────────────────

class GeoRequest(BaseModel):
    lat: float
    lng: float
    accuracy: float | None = None


@router.post("/geo/mark")
async def geo_mark(
    body: GeoRequest,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Fetch org separately to avoid async lazy-load
    result = await db.execute(select(Organization).where(Organization.id == user.org_id))
    org = result.scalar_one_or_none()
    geofence = (org.settings or {}).get("geofence") if org else None

    if geofence:
        in_zone = geo_service.is_within_geofence(
            body.lat, body.lng,
            geofence["lat"], geofence["lng"],
            geofence["radius_meters"],
        )
        if not in_zone:
            raise HTTPException(status_code=400, detail="You are outside the office geofence")

    location = {"lat": body.lat, "lng": body.lng, "accuracy": body.accuracy}
    return await _mark_attendance(db, user, method="geo", location=location)


# ── Face ──────────────────────────────────────────────────────────────────────

@router.post("/face/challenge")
async def face_challenge(user: User = Depends(get_current_user)):
    challenge = await face_service.create_challenge(user.org_id, user.id)
    return challenge


@router.post("/face/verify")
async def face_verify(
    challenge_id: str,
    frame: UploadFile = File(...),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Check liveness challenge was completed
    challenge_ok = await face_service.verify_challenge(challenge_id)
    if not challenge_ok:
        raise HTTPException(status_code=400, detail="Liveness challenge expired or not found")

    # Load stored face embedding
    result = await db.execute(select(FaceData).where(FaceData.user_id == user.id))
    face_data = result.scalar_one_or_none()
    if not face_data:
        raise HTTPException(status_code=400, detail="No face enrolled for this employee")

    image_bytes = await frame.read()
    match = face_service.verify_face(image_bytes, face_data.encrypted_embedding)
    if not match:
        raise HTTPException(status_code=401, detail="Face not recognized")

    return await _mark_attendance(db, user, method="face")


# ── Check-Out ────────────────────────────────────────────────────────────────

@router.post("/checkout")
async def checkout(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    today = date.today()
    result = await db.execute(
        select(AttendanceRecord).where(
            AttendanceRecord.user_id == user.id,
            AttendanceRecord.date == today,
        )
    )
    record = result.scalar_one_or_none()
    if not record or not record.check_in:
        raise HTTPException(status_code=400, detail="No check-in found for today")
    if record.check_out:
        raise HTTPException(status_code=400, detail="Already checked out today")

    now = datetime.now(timezone.utc)
    record.check_out = now
    record.duration_minutes = int((now - record.check_in).total_seconds() / 60)
    record.status = "present"
    await db.commit()
    await db.refresh(record)
    return {
        "check_out": now.isoformat(),
        "duration_minutes": record.duration_minutes,
        "hours": round(record.duration_minutes / 60, 2),
    }


# ── Today / History ──────────────────────────────────────────────────────────

@router.get("/today")
async def today_record(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(AttendanceRecord).where(
            AttendanceRecord.user_id == user.id,
            AttendanceRecord.date == date.today(),
        )
    )
    record = result.scalar_one_or_none()
    if not record:
        return {"status": "not_marked", "date": date.today().isoformat()}

    data = {
        "id": str(record.id),
        "date": record.date.isoformat(),
        "status": record.status,
        "method": record.method,
        "check_in": record.check_in.isoformat() if record.check_in else None,
        "check_out": record.check_out.isoformat() if record.check_out else None,
        "duration_minutes": record.duration_minutes,
    }
    # If checked in but not out, compute running duration
    if record.check_in and not record.check_out:
        running = int((datetime.now(timezone.utc) - record.check_in).total_seconds() / 60)
        data["running_minutes"] = running
    return data


@router.get("/history")
async def history(
    page: int = 1,
    per_page: int = 20,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    offset = (page - 1) * per_page
    result = await db.execute(
        select(AttendanceRecord)
        .where(AttendanceRecord.user_id == user.id)
        .order_by(AttendanceRecord.date.desc())
        .offset(offset)
        .limit(per_page)
    )
    records = result.scalars().all()
    return [
        {
            "id": str(r.id),
            "date": r.date.isoformat(),
            "status": r.status,
            "method": r.method,
            "check_in": r.check_in.isoformat() if r.check_in else None,
            "check_out": r.check_out.isoformat() if r.check_out else None,
            "duration_minutes": r.duration_minutes,
            "location": r.location,
        }
        for r in records
    ]


# ── Status check (allowed methods) ───────────────────────────────────────────

@router.get("/methods")
async def allowed_methods(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Return which attendance methods are enabled by the manager for this org."""
    result = await db.execute(select(Organization).where(Organization.id == user.org_id))
    org = result.scalar_one_or_none()
    settings = (org.settings or {}) if org else {}
    return {
        "allowed_methods": settings.get("allowed_methods", ["qr"]),
        "geofence_enabled": bool(settings.get("geofence")),
        "office_hours": settings.get("office_hours", {"start": "09:00", "end": "18:00"}),
    }


# ── Internal helper ──────────────────────────────────────────────────────────

async def _mark_attendance(
    db: AsyncSession,
    user: User,
    method: str,
    location: dict | None = None,
) -> dict:
    today = date.today()
    now = datetime.now(timezone.utc)

    result = await db.execute(
        select(AttendanceRecord).where(
            AttendanceRecord.user_id == user.id,
            AttendanceRecord.date == today,
        )
    )
    record = result.scalar_one_or_none()

    if not record:
        # First mark of the day → check-in
        record = AttendanceRecord(
            user_id=user.id,
            org_id=user.org_id,
            date=today,
            check_in=now,
            method=method,
            location=location,
            status="present",
        )
        db.add(record)
        await db.commit()
        await db.refresh(record)
        return {
            "action": "check_in",
            "time": now.isoformat(),
            "message": "Checked in successfully",
        }

    if record.check_out:
        raise HTTPException(status_code=400, detail="Already completed attendance for today")

    # Second mark → check-out
    record.check_out = now
    record.duration_minutes = int((now - record.check_in).total_seconds() / 60)
    record.status = "present"
    await db.commit()
    return {
        "action": "check_out",
        "time": now.isoformat(),
        "duration_minutes": record.duration_minutes,
        "hours": round(record.duration_minutes / 60, 2),
        "message": "Checked out successfully",
    }
