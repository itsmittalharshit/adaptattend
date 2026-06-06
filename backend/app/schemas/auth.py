from pydantic import BaseModel, EmailStr


class SendOTPRequest(BaseModel):
    email: EmailStr


class VerifyOTPRequest(BaseModel):
    email: EmailStr
    code: str


class LoginRequest(BaseModel):
    guest_key: str
    username: str
    password: str


class ManagerOTPRequest(BaseModel):
    code: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    full_name: str | None
    user_id: str


class PartialTokenResponse(BaseModel):
    requires_otp: bool
    partial_token: str
    hint: str


class GuestKeyResponse(BaseModel):
    key: str
    email: str
    expires_at: str
    demo_credentials: dict
