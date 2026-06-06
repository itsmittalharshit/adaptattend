import uuid
from datetime import datetime, timezone
from sqlalchemy import String, Boolean, DateTime, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base


class Organization(Base):
    __tablename__ = "organizations"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    is_demo: Mapped[bool] = mapped_column(Boolean, default=True)
    # is_showcase = True means this is a permanent public demo org (e.g. the one shown on website).
    # Its face images are never deleted.
    is_showcase: Mapped[bool] = mapped_column(Boolean, default=False)
    # settings: {allowed_methods, geofence, office_hours}
    settings: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    # expires_at is null for non-demo orgs
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)

    users = relationship("User", back_populates="organization", cascade="all, delete-orphan")
    guest_account = relationship("GuestAccount", back_populates="organization", uselist=False)
