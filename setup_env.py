#!/usr/bin/env python3
"""Run once: python setup_env.py — generates backend/.env with random secrets."""
import secrets
import shutil
import subprocess
from pathlib import Path

backend_dir = Path(__file__).parent / "backend"
env_example = backend_dir / ".env.example"
env_file = backend_dir / ".env"

if env_file.exists():
    print("✅ .env already exists — skipping.")
else:
    content = env_example.read_text()
    jwt_secret = secrets.token_hex(32)
    fernet_key = subprocess.check_output([
        "python3", "-c",
        "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
    ], cwd=str(backend_dir)).decode().strip()
    content = content.replace("replace_with_a_random_64_char_hex_string", jwt_secret)
    content = content.replace("replace_with_fernet_key", fernet_key)
    env_file.write_text(content)
    print("✅ backend/.env created with auto-generated secrets")
    print(f"   JWT_SECRET: {jwt_secret[:16]}...")
    print(f"   FACE_ENCRYPTION_KEY: {fernet_key[:16]}...")
