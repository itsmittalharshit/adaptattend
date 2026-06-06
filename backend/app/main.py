"""
AdaptAttend — FastAPI microservice.

Stateless except for Redis (QR one-time-use + face challenge TTL).
The Flutter app owns all persistent data in on-device SQLite.

Endpoints:
  GET  /health
  POST /qr/generate    — create a 15-second TOTP QR token
  POST /qr/verify      — consume a QR token (one-time use)
  GET  /face/challenge — issue a liveness prompt (stored in Redis, 60 s TTL)
  POST /face/enroll    — extract FaceNet512 embedding, return encrypted blob
  POST /face/verify    — compare live image against stored encrypted embedding
  POST /geo/check      — haversine geofence check
"""
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routers import qr, face, geo

logger = logging.getLogger("uvicorn")


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("✅ AdaptAttend microservice ready.")
    yield


app = FastAPI(
    title="AdaptAttend API",
    version="3.0.0",
    description=(
        "Stateless microservice for AdaptAttend Flutter app. "
        "Handles QR token generation, face recognition (DeepFace), "
        "and geofence checks. All persistent data lives on-device (SQLite)."
    ),
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],   # Flutter mobile — no fixed origin
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(qr.router,   prefix="/qr",   tags=["QR Tokens"])
app.include_router(face.router, prefix="/face", tags=["Face Recognition"])
app.include_router(geo.router,  prefix="/geo",  tags=["Geofence"])


@app.get("/health", tags=["Health"])
async def health():
    return {"status": "ok", "version": "3.0.0"}
