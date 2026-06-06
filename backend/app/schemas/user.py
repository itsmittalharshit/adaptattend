import uuid
from datetime import datetime
from pydantic import BaseModel, EmailStr


class UserBase(BaseModel):
    username: str
    full_name: str | None = None
    email: EmailStr | None = None


class CreateEmployeeRequest(UserBase):
    password: str


class UpdateEmployeeRequest(BaseModel):
    full_name: str | None = None
    email: str | None = None
    is_active: bool | None = None


class UserResponse(UserBase):
    id: uuid.UUID
    org_id: uuid.UUID
    role: str
    is_active: bool
    created_at: datetime
    has_face_enrolled: bool = False

    model_config = {"from_attributes": True}


class OrgSettingsRequest(BaseModel):
    allowed_methods: list[str] | None = None  # ['qr', 'geo', 'face']
    geofence: dict | None = None              # {lat, lng, radius_meters}
    office_hours: dict | None = None          # {start: "09:00", end: "18:00"}


class OrgSettingsResponse(BaseModel):
    allowed_methods: list[str]
    geofence: dict | None
    office_hours: dict
