import uuid
from datetime import datetime, timezone
from sqlalchemy import String, DateTime, ForeignKey, Text, Boolean
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base


class FaceData(Base):
    __tablename__ = "face_data"

    id: Mapped[uuid.UUID] = mapped_column(primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), unique=True)

    # Fernet-encrypted JSON of the 512-float face embedding vector
    encrypted_embedding: Mapped[str] = mapped_column(Text, nullable=False)

    # Local filesystem path to the enrollment image, relative to FACE_IMAGES_DIR.
    # e.g. "demo/550e8400-e29b-41d4-a716-446655440000/3b3b3b3b.jpg"
    # Null means the image was not retained (only the embedding is stored).
    image_path: Mapped[str | None] = mapped_column(String(500), nullable=True)

    # True for showcase/developer orgs — image is never cleaned up.
    # False for regular demo orgs — image deleted when the org expires.
    is_permanent: Mapped[bool] = mapped_column(Boolean, default=False)

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    user = relationship("User", back_populates="face_data")
