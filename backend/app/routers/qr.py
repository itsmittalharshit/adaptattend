"""
QR Token router.

The Flutter manager screen calls /qr/generate every 15 s to get a fresh token.
The Flutter employee screen pastes/scans the token and calls /qr/verify.
Tokens are one-time-use (Redis key deleted on first successful verify).
"""
import base64
import hashlib
import hmac
import time

import pyotp
from jose import jwt
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.config import settings
from app.core.redis_client import get_redis

router = APIRouter()

QR_WINDOW = 15  # seconds


class GenerateRequest(BaseModel):
    org_secret: str   # arbitrary string the Flutter app generates per org and stores locally


class VerifyRequest(BaseModel):
    org_secret: str
    token: str        # the JWT string shown on manager screen


def _totp_secret(org_secret: str) -> str:
    """Derive a stable base32 TOTP secret from org_secret + app JWT_SECRET."""
    raw = hmac.new(
        settings.JWT_SECRET.encode(),
        org_secret.encode(),
        hashlib.sha256,
    ).digest()
    return base64.b32encode(raw).decode()


@router.post("/generate", summary="Generate a 15-second QR token JWT")
async def generate_qr(body: GenerateRequest):
    secret = _totp_secret(body.org_secret)
    totp = pyotp.TOTP(secret, interval=QR_WINDOW)
    token_value = totp.now()

    # Store in Redis so verify can enforce one-time-use
    redis = await get_redis()
    redis_key = f"qr:{body.org_secret}:{token_value}"
    await redis.setex(redis_key, QR_WINDOW + 5, "1")

    payload = {
        "org_secret": body.org_secret,
        "token": token_value,
        "iat": int(time.time()),
    }
    signed = jwt.encode(payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)

    return {
        "qr_token": signed,
        "expires_in": QR_WINDOW,
        "current_time": int(time.time()),
    }


@router.post("/verify", summary="Consume a QR token (one-time use)")
async def verify_qr(body: VerifyRequest):
    try:
        payload = jwt.decode(body.token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid QR token signature")

    if payload.get("org_secret") != body.org_secret:
        raise HTTPException(status_code=400, detail="Token org mismatch")

    token_value = payload.get("token")
    redis = await get_redis()
    redis_key = f"qr:{body.org_secret}:{token_value}"

    exists = await redis.exists(redis_key)
    if not exists:
        raise HTTPException(status_code=400, detail="Token expired or already used")

    await redis.delete(redis_key)  # one-time use
    return {"valid": True}
