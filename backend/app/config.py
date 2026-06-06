from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # Redis — one-time-use QR tokens + face challenge TTLs
    REDIS_URL: str = "redis://localhost:6379"

    # Face data encryption (Fernet key)
    # Generate: python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
    FACE_ENCRYPTION_KEY: str = ""

    # JWT secret — used to sign QR token JWTs
    JWT_SECRET: str = "change-me-min-32-chars-long-please"
    JWT_ALGORITHM: str = "HS256"

    # Face images stored temporarily for enrollment reference (not required)
    FACE_IMAGES_DIR: str = "face_images"

    class Config:
        env_file = ".env"


settings = Settings()
