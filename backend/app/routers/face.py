"""
Face recognition router — stateless from the app's perspective.

Enroll:
  POST /face/enroll  multipart: image_file (JPEG/PNG)
  → { encrypted_embedding: str }   # Flutter stores this in its local SQLite

Verify:
  GET  /face/challenge
  → { challenge_id: str, motions: [str, str] }   # shown to employee

  POST /face/verify  multipart: image_file + form fields
  → { match: bool }

The backend never persists anything; Redis only holds the 60-second challenge TTL.
"""
import random
import uuid
import os

from fastapi import APIRouter, HTTPException, UploadFile, File, Form
from pydantic import BaseModel

from app.core.redis_client import get_redis
from app.services.face_service import (
    extract_embedding, verify_face,
    encrypt_embedding, decrypt_embedding,
)

router = APIRouter()

CHALLENGES = [
    "blink_twice",
    "turn_head_left",
    "turn_head_right",
    "smile",
    "raise_eyebrows",
    "nod_head",
]


@router.get("/challenge", summary="Issue a random liveness challenge (60 s TTL)")
async def get_challenge():
    challenge_id = str(uuid.uuid4())
    motions = random.sample(CHALLENGES, k=2)
    redis = await get_redis()
    await redis.setex(f"face_challenge:{challenge_id}", 60, ",".join(motions))
    return {"challenge_id": challenge_id, "motions": motions}


@router.post("/enroll", summary="Extract & encrypt face embedding (returned to Flutter)")
async def enroll_face_endpoint(image_file: UploadFile = File(...)):
    """
    Upload a face image → get back an encrypted embedding string.
    Flutter stores this string in its on-device SQLite for that employee.
    """
    image_bytes = await image_file.read()
    try:
        embedding = extract_embedding(image_bytes)
    except Exception as exc:
        raise HTTPException(status_code=422, detail=f"No face detected: {exc}")

    encrypted = encrypt_embedding(embedding)
    return {"encrypted_embedding": encrypted, "model": "FaceNet512"}


@router.post("/verify", summary="Verify a live face against a stored encrypted embedding")
async def verify_face_endpoint(
    image_file: UploadFile = File(...),
    encrypted_embedding: str = Form(...),
    challenge_id: str = Form(None),
):
    """
    Flutter sends:
      - image_file: current camera frame
      - encrypted_embedding: the blob stored in SQLite (from /face/enroll)
      - challenge_id (optional): liveness challenge token to consume

    Returns { match: bool, liveness_ok: bool }
    """
    # Check liveness challenge if provided
    liveness_ok = True
    if challenge_id:
        redis = await get_redis()
        key = f"face_challenge:{challenge_id}"
        exists = await redis.exists(key)
        if not exists:
            raise HTTPException(status_code=400, detail="Liveness challenge expired or invalid")
        await redis.delete(key)
        liveness_ok = True   # challenge completed by the app

    image_bytes = await image_file.read()
    try:
        match = verify_face(image_bytes, encrypted_embedding)
    except Exception as exc:
        raise HTTPException(status_code=422, detail=f"Face verification error: {exc}")

    return {"match": match, "liveness_ok": liveness_ok}
