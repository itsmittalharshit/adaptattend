import uuid
from datetime import datetime, date
from pydantic import BaseModel


class AttendanceRecordResponse(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    date: date
    status: str
    method: str | None
    check_in: datetime | None
    check_out: datetime | None
    duration_minutes: int | None
    location: dict | None

    model_config = {"from_attributes": True}


class CheckInResponse(BaseModel):
    action: str
    time: str
    message: str


class CheckOutResponse(BaseModel):
    action: str
    time: str
    duration_minutes: int
    hours: float
    message: str


class QRVerifyRequest(BaseModel):
    qr_jwt: str


class GeoMarkRequest(BaseModel):
    lat: float
    lng: float
    accuracy: float | None = None


class FaceChallengeResponse(BaseModel):
    challenge_id: str
    motions: list[str]


class AllowedMethodsResponse(BaseModel):
    allowed_methods: list[str]
    geofence_enabled: bool
    office_hours: dict
