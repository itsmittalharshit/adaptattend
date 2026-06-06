# Re-export from face_service for backwards-compat
from app.services.face_service import encrypt_embedding, decrypt_embedding

__all__ = ["encrypt_embedding", "decrypt_embedding"]
