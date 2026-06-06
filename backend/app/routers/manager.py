"""Manager router — employee CRUD, settings, face enrollment, attendance view, CSV export, key management."""
import csv
import io
import uuid
from datetime import date, datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Query
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.core.dependencies import require_manager
from app.core.security import hash_password, verify_password
from app.models.attendance import AttendanceRecord
from app.models.face_data import FaceData
from app.models.organization import Organization
from app.models.user import User
from app.services.face_service import enroll_face
from app.services.key_service import generate_manager_key, hash_key, verify_key

router = APIRouter()


# ─── Request schemas ──────────────────────────────────────────────────────────

class CreateEmployeeRequest(BaseModel):
    username: str
    password: str
    full_name: str | None = None
    email: str | None = None


class UpdateEmployeeRequest(BaseModel):
    full_name: str | None = None
    email: str | None = None
    password: str | None = None
    is_active: bool | None = None


class UpdateSettingsRequest(BaseModel):
    allowed_methods: list[str] | None = None
    geofence: dict | None = None      # {lat, lng, radius_meters} or null to disable
    office_hours: dict | None = None  # {start: "09:00", end: "18:00"}


class ChangeKeyRequest(BaseModel):
    current_key: str   # MGR-XXXX-XXXX-XXXX (or the fixed demo key)
    new_key: str | None = None  # omit to auto-generate a new key


# ─── Employee CRUD ────────────────────────────────────────────────────────────

@router.get("/employees", summary="List all employees in the org")
async def list_employees(
    manager: User = Depends(require_manager),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(User).where(User.org_id == manager.org_id, User.role == "employee")
        .order_by(User.full_name)
    )
    employees = result.scalars().all()

    # Check who has face enrolled
    face_result = await db.execute(
        select(FaceData.user_id).where(
            FaceData.user_id.in_([e.id for e in employees])
        )
    )
    enrolled_ids = {row[0] for row in face_result.all()}

    return [
        {
            "id": str(e.id),
            "username": e.username,
            "full_name": e.full_name,
            "email": e.email,
            "is_active": e.is_active,
            "has_face_enrolled": e.id in enrolled_ids,
            "created_at": e.created_at.isoformat(),
        }
        for e in employees
    ]


@router.get("/employees/{employee_id}", summary="Get a single employee")
async def get_employee(
    employee_id: uuid.UUID,
    manager: User = Depends(require_manager),
    db: AsyncSession = Depends(get_db),
):
    emp = await _get_employee_or_404(db, employee_id, manager.org_id)
    face = await db.execute(select(FaceData).where(FaceData.user_id == employee_id))
    face_data = face.scalar_one_or_none()
    return {
        "id": str(emp.id),
        "username": emp.username,
        "full_name": emp.full_name,
        "email": emp.email,
        "is_active": emp.is_active,
        "has_face_enrolled": face_data is not None,
        "created_at": emp.created_at.isoformat(),
    }


@router.post("/employees", status_code=201, summary="Create a new employee")
async def create_employee(
    body: CreateEmployeeRequest,
    manager: User = Depends(require_manager),
    db: AsyncSession = Depends(get_db),
):
    # Check username uniqueness within org
    existing = await db.execute(
        select(User).where(User.org_id == manager.org_id, User.username == body.username)
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=409, detail="Username already exists in this org")

    employee = User(
        org_id=manager.org_id,
        username=body.username,
        password_hash=hash_password(body.password),
        role="employee",
        full_name=body.full_name,
        email=body.email,
    )
    db.add(employee)
    await db.commit()
    await db.refresh(employee)
    return {"id": str(employee.id), "username": employee.username, "full_name": employee.full_name}


@router.put("/employees/{employee_id}", summary="Update employee details")
async def update_employee(
    employee_id: uuid.UUID,
    body: UpdateEmployeeRequest,
    manager: User = Depends(require_manager),
    db: AsyncSession = Depends(get_db),
):
    emp = await _get_employee_or_404(db, employee_id, manager.org_id)
    if body.full_name is not None:
        emp.full_name = body.full_name
    if body.email is not None:
        emp.email = body.email
    if body.password is not None:
        emp.password_hash = hash_password(body.password)
    if body.is_active is not None:
        emp.is_active = body.is_active
    await db.commit()
    return {"id": str(emp.id), "username": emp.username, "full_name": emp.full_name, "is_active": emp.is_active}


@router.delete("/employees/{employee_id}", summary="Deactivate an employee")
async def deactivate_employee(
    employee_id: uuid.UUID,
    manager: User = Depends(require_manager),
    db: AsyncSession = Depends(get_db),
):
    emp = await _get_employee_or_404(db, employee_id, manager.org_id)
    emp.is_active = False
    await db.commit()
    return {"status": "deactivated", "id": str(employee_id)}


# ─── Face Enrollment ──────────────────────────────────────────────────────────

@router.post("/employees/{employee_id}/face", summary="Enroll or update employee face")
async def enroll_employee_face(
    employee_id: uuid.UUID,
    image: UploadFile = File(..., description="Clear frontal face photo (JPEG/PNG)"),
    manager: User = Depends(require_manager),
    db: AsyncSession = Depends(get_db),
):
    await _get_employee_or_404(db, employee_id, manager.org_id)

    # Get org to determine if images should be permanent (showcase orgs)
    org_result = await db.execute(select(Organization).where(Organization.id == manager.org_id))
    org = org_result.scalar_one()

    image_bytes = await image.read()
    try:
        encrypted, image_path = enroll_face(
            image_bytes,
            org_id=manager.org_id,
            user_id=employee_id,
            is_permanent=org.is_showcase,
        )
    except Exception as e:
        raise HTTPException(status_code=422, detail=f"Could not detect face in image: {e}")

    existing = await db.execute(select(FaceData).where(FaceData.user_id == employee_id))
    face_data = existing.scalar_one_or_none()
    if face_data:
        face_data.encrypted_embedding = encrypted
        face_data.image_path = image_path
        face_data.is_permanent = org.is_showcase
        face_data.updated_at = datetime.now(timezone.utc)
    else:
        db.add(FaceData(
            user_id=employee_id,
            encrypted_embedding=encrypted,
            image_path=image_path,
            is_permanent=org.is_showcase,
        ))

    await db.commit()
    return {"status": "enrolled", "employee_id": str(employee_id)}


@router.delete("/employees/{employee_id}/face", summary="Remove employee face data")
async def remove_employee_face(
    employee_id: uuid.UUID,
    manager: User = Depends(require_manager),
    db: AsyncSession = Depends(get_db),
):
    await _get_employee_or_404(db, employee_id, manager.org_id)
    result = await db.execute(select(FaceData).where(FaceData.user_id == employee_id))
    face_data = result.scalar_one_or_none()
    if not face_data:
        raise HTTPException(status_code=404, detail="No face data enrolled")
    await db.delete(face_data)
    await db.commit()
    return {"status": "removed"}


# ─── Org Settings ─────────────────────────────────────────────────────────────

@router.get("/settings", summary="Get org attendance settings")
async def get_settings(
    manager: User = Depends(require_manager),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Organization).where(Organization.id == manager.org_id))
    org = result.scalar_one()
    return {
        "allowed_methods": org.settings.get("allowed_methods", ["qr"]),
        "geofence": org.settings.get("geofence"),
        "office_hours": org.settings.get("office_hours", {"start": "09:00", "end": "18:00"}),
    }


@router.put("/settings", summary="Update org attendance settings")
async def update_settings(
    body: UpdateSettingsRequest,
    manager: User = Depends(require_manager),
    db: AsyncSession = Depends(get_db),
):
    VALID_METHODS = {"qr", "geo", "face"}
    if body.allowed_methods is not None:
        invalid = set(body.allowed_methods) - VALID_METHODS
        if invalid:
            raise HTTPException(status_code=422, detail=f"Invalid methods: {invalid}. Choose from {VALID_METHODS}")

    result = await db.execute(select(Organization).where(Organization.id == manager.org_id))
    org = result.scalar_one()
    new_settings = dict(org.settings)

    if body.allowed_methods is not None:
        new_settings["allowed_methods"] = body.allowed_methods
    if body.geofence is not None:
        required = {"lat", "lng", "radius_meters"}
        if not required.issubset(body.geofence.keys()):
            raise HTTPException(status_code=422, detail=f"Geofence requires: {required}")
        new_settings["geofence"] = body.geofence
    if "geofence" in (body.model_fields_set) and body.geofence is None:
        new_settings["geofence"] = None  # explicit disable
    if body.office_hours is not None:
        new_settings["office_hours"] = body.office_hours

    org.settings = new_settings
    await db.commit()
    return new_settings


# ─── Attendance View & Export ─────────────────────────────────────────────────

@router.get("/attendance", summary="View attendance records (all employees)")
async def view_attendance(
    date_from: date | None = Query(None, description="Filter from date (YYYY-MM-DD)"),
    date_to: date | None = Query(None, description="Filter to date (YYYY-MM-DD)"),
    employee_id: uuid.UUID | None = Query(None),
    status: str | None = Query(None, description="present | incomplete | absent"),
    page: int = Query(1, ge=1),
    per_page: int = Query(50, ge=1, le=200),
    manager: User = Depends(require_manager),
    db: AsyncSession = Depends(get_db),
):
    filters = [AttendanceRecord.org_id == manager.org_id]
    if date_from:
        filters.append(AttendanceRecord.date >= date_from)
    if date_to:
        filters.append(AttendanceRecord.date <= date_to)
    if employee_id:
        filters.append(AttendanceRecord.user_id == employee_id)
    if status:
        filters.append(AttendanceRecord.status == status)

    offset = (page - 1) * per_page
    result = await db.execute(
        select(AttendanceRecord)
        .where(and_(*filters))
        .order_by(AttendanceRecord.date.desc(), AttendanceRecord.check_in.desc())
        .offset(offset)
        .limit(per_page)
    )
    records = result.scalars().all()

    # Fetch employee names
    emp_result = await db.execute(
        select(User.id, User.full_name, User.username).where(User.org_id == manager.org_id)
    )
    emp_map = {row[0]: (row[1] or row[2]) for row in emp_result.all()}

    return [
        {
            "id": str(r.id),
            "employee_id": str(r.user_id),
            "employee_name": emp_map.get(r.user_id, "Unknown"),
            "date": r.date.isoformat(),
            "status": r.status,
            "method": r.method,
            "check_in": r.check_in.isoformat() if r.check_in else None,
            "check_out": r.check_out.isoformat() if r.check_out else None,
            "duration_minutes": r.duration_minutes,
            "hours": round(r.duration_minutes / 60, 2) if r.duration_minutes else None,
            "location": r.location,
        }
        for r in records
    ]


@router.get("/attendance/export", summary="Export attendance as CSV")
async def export_attendance_csv(
    date_from: date | None = Query(None),
    date_to: date | None = Query(None),
    employee_id: uuid.UUID | None = Query(None),
    manager: User = Depends(require_manager),
    db: AsyncSession = Depends(get_db),
):
    filters = [AttendanceRecord.org_id == manager.org_id]
    if date_from:
        filters.append(AttendanceRecord.date >= date_from)
    if date_to:
        filters.append(AttendanceRecord.date <= date_to)
    if employee_id:
        filters.append(AttendanceRecord.user_id == employee_id)

    result = await db.execute(
        select(AttendanceRecord).where(and_(*filters)).order_by(AttendanceRecord.date.desc())
    )
    records = result.scalars().all()

    emp_result = await db.execute(
        select(User.id, User.full_name, User.username).where(User.org_id == manager.org_id)
    )
    emp_map = {row[0]: (row[1] or row[2]) for row in emp_result.all()}

    output = io.StringIO()
    writer = csv.DictWriter(output, fieldnames=[
        "Date", "Employee", "Status", "Method",
        "Check-In", "Check-Out", "Duration (min)", "Hours",
    ])
    writer.writeheader()
    for r in records:
        writer.writerow({
            "Date": r.date.isoformat(),
            "Employee": emp_map.get(r.user_id, "Unknown"),
            "Status": r.status,
            "Method": r.method or "",
            "Check-In": r.check_in.strftime("%H:%M") if r.check_in else "",
            "Check-Out": r.check_out.strftime("%H:%M") if r.check_out else "",
            "Duration (min)": r.duration_minutes or "",
            "Hours": round(r.duration_minutes / 60, 2) if r.duration_minutes else "",
        })

    output.seek(0)
    filename = f"attendance_{date.today().isoformat()}.csv"
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )


# ─── Manager Profile ──────────────────────────────────────────────────────────

@router.get("/profile", summary="Get manager profile")
async def manager_profile(manager: User = Depends(require_manager)):
    return {
        "id": str(manager.id),
        "username": manager.username,
        "full_name": manager.full_name,
        "email": manager.email,
        "role": manager.role,
    }


# ─── Manager Key Management ───────────────────────────────────────────────────

@router.put("/change-key", summary="Change manager auth key (MGR-XXXX-XXXX-XXXX)")
async def change_manager_key(
    body: ChangeKeyRequest,
    manager: User = Depends(require_manager),
    db: AsyncSession = Depends(get_db),
):
    """
    Change the manager's personal auth key.

    - current_key: required to verify identity (prevents token theft attacks)
    - new_key: optional; if omitted, a new MGR-XXXX-XXXX-XXXX key is auto-generated

    The new key is returned once — store it safely.
    """
    # Re-fetch manager from DB (Depends caches the token-decoded user object)
    result = await db.execute(select(User).where(User.id == manager.id))
    db_manager = result.scalar_one()

    # Verify current key
    if not db_manager.manager_key_hash or not verify_key(body.current_key, db_manager.manager_key_hash):
        raise HTTPException(status_code=403, detail="Current key is incorrect")

    # Generate or use provided new key
    if body.new_key:
        new_key = body.new_key
        if not (new_key.startswith("MGR-") and len(new_key.split("-")) == 4):
            raise HTTPException(
                status_code=422,
                detail="new_key must follow the MGR-XXXX-XXXX-XXXX format",
            )
    else:
        new_key = generate_manager_key()

    db_manager.manager_key_hash = hash_key(new_key)
    await db.commit()

    return {
        "status": "key_changed",
        "new_key": new_key,
        "warning": "Store this key safely — it will not be shown again.",
    }


# ─── Internal helper ──────────────────────────────────────────────────────────

async def _get_employee_or_404(db: AsyncSession, employee_id: uuid.UUID, org_id: uuid.UUID) -> User:
    result = await db.execute(
        select(User).where(User.id == employee_id, User.org_id == org_id, User.role == "employee")
    )
    emp = result.scalar_one_or_none()
    if not emp:
        raise HTTPException(status_code=404, detail="Employee not found")
    return emp
