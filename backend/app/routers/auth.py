"""
Auth router.

Guest/demo flow:
  - Public showcase demo: fixed credentials visible on website, no signup needed.
  - Private demo (create your own): POST /auth/register with an email to get a
    personal org key. No OTP, no Gmail — key is returned in the response AND
    printed to server logs for dev convenience.

Login flow:
  - Employee:  POST /auth/login { guest_key, username, password }
  - Manager:   POST /auth/login { guest_key, username, password, manager_key }
    Manager uses a special personal key (MGR-XXXX-XXXX-XXXX) instead of OTP.
    The manager key is shown once on org creation and can be changed in-app.
"""
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel, EmailStr

from app.config import settings
from app.database import get_db
from app.models.guest import GuestAccount
from app.models.organization import Organization
from app.models.user import User
from app.core.security import create_access_token, hash_password, verify_password
from app.services.key_service import (
    generate_guest_key, generate_manager_key,
    hash_key, verify_key,
)

router = APIRouter()

# ─── Public showcase demo credentials (shown on website) ─────────────────────
# These are seeded on startup in app/main.py.
PUBLIC_DEMO_GUEST_KEY = "AAS-DEMO-DEMO-0001"
PUBLIC_DEMO_MANAGER_KEY = "MGR-DEMO-DEMO-0001"
PUBLIC_DEMO_MANAGER_USERNAME = "admin"
PUBLIC_DEMO_EMPLOYEE_PASSWORD = "Demo@1234"


# ─── Schemas ──────────────────────────────────────────────────────────────────

class RegisterRequest(BaseModel):
    """Create a private demo org. Returns org key + manager key immediately."""
    org_name: str
    manager_username: str
    manager_password: str


class LoginRequest(BaseModel):
    guest_key: str
    username: str
    password: str
    manager_key: str | None = None  # required only for manager login


# ─── Public demo info (no login needed) ───────────────────────────────────────

@router.get("/demo/info", summary="Get public demo credentials — no login required")
async def demo_info():
    """
    Returns the fixed credentials for the public showcase demo org.
    Anyone can use these to explore the app without signing up.
    """
    return {
        "guest_key": PUBLIC_DEMO_GUEST_KEY,
        "manager": {
            "username": PUBLIC_DEMO_MANAGER_USERNAME,
            "password": "Admin@1234",
            "manager_key": PUBLIC_DEMO_MANAGER_KEY,
            "note": "Manager key acts as a second factor — change it in Settings after login.",
        },
        "employees": [
            {"username": f"employee{i}", "password": PUBLIC_DEMO_EMPLOYEE_PASSWORD}
            for i in range(1, 6)
        ],
        "note": "This is a shared showcase org. Data resets periodically.",
    }


# ─── Register a private demo org ──────────────────────────────────────────────

@router.post("/register", summary="Create a private demo org (no email verification)")
async def register(body: RegisterRequest, db: AsyncSession = Depends(get_db)):
    """
    Creates a personal demo org instantly. Returns:
      - guest_key   (employees enter this to connect)
      - manager_key (manager's personal auth key — store it safely, shown once)

    No email, no OTP, no Google — just create and use.
    """
    # Prevent duplicate manager username (within global scope is fine for demo)
    expiry = datetime.now(timezone.utc) + timedelta(days=settings.DEMO_EXPIRY_DAYS)

    org = Organization(
        name=body.org_name,
        is_demo=True,
        is_showcase=False,
        settings={
            "allowed_methods": ["qr"],
            "geofence": None,
            "office_hours": {"start": "09:00", "end": "18:00"},
        },
        expires_at=expiry,
    )
    db.add(org)
    await db.flush()

    guest_key = generate_guest_key()
    manager_key = generate_manager_key()

    db.add(GuestAccount(
        email=f"demo_{org.id}@local",   # placeholder, no real email needed
        key_hash=hash_key(guest_key),
        org_id=org.id,
        expires_at=expiry,
    ))

    db.add(User(
        org_id=org.id,
        username=body.manager_username,
        password_hash=hash_password(body.manager_password),
        role="manager",
        full_name="Manager",
        manager_key_hash=hash_key(manager_key),
    ))

    await db.commit()

    # Log for dev convenience (remove in production)
    import logging
    logging.getLogger("uvicorn").info(
        f"[NEW ORG] guest_key={guest_key}  manager_key={manager_key}"
    )

    return {
        "org_name": body.org_name,
        "guest_key": guest_key,
        "manager_key": manager_key,
        "expires_at": expiry.isoformat(),
        "warning": "Save these keys — manager_key is shown only once.",
        "next_steps": [
            f"Share guest_key '{guest_key}' with employees",
            "Use manager_key when logging in as manager",
            "Add employees via Manager → Employees → Add",
        ],
    }


# ─── Login ────────────────────────────────────────────────────────────────────

@router.post("/login", summary="Login with guest key + credentials")
async def login(body: LoginRequest, db: AsyncSession = Depends(get_db)):
    """
    Single login endpoint for both employees and managers.

    Employee:  { guest_key, username, password }
    Manager:   { guest_key, username, password, manager_key }

    The manager_key is the MGR-XXXX-XXXX-XXXX key generated at org creation.
    It can be changed in-app via PUT /manager/change-key.
    """
    # 1. Validate guest key
    guest = await _find_guest_by_key(db, body.guest_key)
    if not guest:
        raise HTTPException(status_code=401, detail="Invalid access key")
    if guest.expires_at.replace(tzinfo=timezone.utc) < datetime.now(timezone.utc):
        raise HTTPException(status_code=401, detail="Access key has expired")

    # 2. Find user in org
    result = await db.execute(
        select(User).where(
            User.org_id == guest.org_id,
            User.username == body.username,
            User.is_active == True,
        )
    )
    user = result.scalar_one_or_none()
    if not user or not verify_password(body.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid username or password")

    # 3. Manager must also provide their manager_key
    if user.role == "manager":
        if not body.manager_key:
            raise HTTPException(
                status_code=401,
                detail="manager_key is required for manager login",
            )
        if not user.manager_key_hash or not verify_key(body.manager_key, user.manager_key_hash):
            raise HTTPException(status_code=401, detail="Invalid manager key")

    # 4. Issue JWT
    token = create_access_token({
        "sub": str(user.id),
        "role": user.role,
        "org_id": str(guest.org_id),
    })
    return {
        "access_token": token,
        "token_type": "bearer",
        "role": user.role,
        "full_name": user.full_name,
        "user_id": str(user.id),
        "org_id": str(guest.org_id),
    }


@router.post("/logout", summary="Discard token (client-side)")
async def logout():
    return {"message": "Logged out. Discard your access token on the client."}


# ─── Internal helper ──────────────────────────────────────────────────────────

async def _find_guest_by_key(db: AsyncSession, plain_key: str) -> GuestAccount | None:
    """Scan active guest accounts and bcrypt-verify the key."""
    result = await db.execute(
        select(GuestAccount).where(GuestAccount.is_active == True)
    )
    guests = result.scalars().all()
    return next((g for g in guests if verify_key(plain_key, g.key_hash)), None)
