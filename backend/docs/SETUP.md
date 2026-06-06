# Adaptive Attendance System — Backend Setup Guide

Everything runs locally. No cloud accounts, no paid services.

---

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Python | 3.11+ | https://python.org |
| Docker Desktop | latest | https://docker.com/products/docker-desktop |
| Git | any | https://git-scm.com |

---

## 1. Start Local Services (PostgreSQL + Redis)

From the **project root** (the folder containing `docker-compose.yml`):

```bash
docker compose up -d
```

This starts:
- **PostgreSQL 16** on `localhost:5432`
  - database: `attendance_db`, user: `attendance`, password: `attendance_secret`
- **Redis 7** on `localhost:6379`

Check they're running:
```bash
docker compose ps
```

Both should show `healthy`.

---

## 2. Set Up Python Environment

```bash
cd backend
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

> DeepFace (face recognition) downloads model weights on first run (~200 MB).
> This happens automatically — just let it finish.

---

## 3. Configure Environment Variables

```bash
cp .env.example .env
```

Open `.env`. The defaults work out of the box with Docker:

```env
DATABASE_URL=postgresql+asyncpg://attendance:attendance_secret@localhost:5432/attendance_db
REDIS_URL=redis://localhost:6379/0

# Generate a secure random string (32+ chars) for JWT signing
JWT_SECRET=change-me-to-a-random-secret-string

# Generate with: python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
FACE_ENCRYPTION_KEY=<your-fernet-key>

FACE_IMAGES_DIR=face_images
DEMO_EXPIRY_DAYS=30
CORS_ORIGINS=["http://localhost:3000","http://localhost:8080"]
```

**Generate your secrets:**

```bash
# JWT secret
python -c "import secrets; print(secrets.token_hex(32))"

# Fernet key for face image encryption
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
```

Paste the outputs into `.env`.

---

## 4. Run Database Migrations

```bash
alembic upgrade head
```

This creates all 5 tables: `organizations`, `guest_accounts`, `users`, `face_data`, `attendance_records`.

---

## 5. Start the API Server

```bash
uvicorn app.main:app --reload --port 8000
```

On startup the server will:
1. Create `face_images/demo/` and `face_images/permanent/` directories
2. Seed the **public showcase demo org** (if not already present)
3. Clean up any expired demo orgs' face images

You'll see:
```
✅ Public demo ready — guest_key=AAS-DEMO-DEMO-0001  manager_key=MGR-DEMO-DEMO-0001
✅ Adaptive Attendance System ready.
```

---

## 6. Verify It's Working

Open your browser: **http://localhost:8000/docs**

You'll see the interactive Swagger UI with all endpoints.

Test the health endpoint:
```bash
curl http://localhost:8000/health
# {"status":"ok","version":"2.0.0"}
```

Get demo credentials:
```bash
curl http://localhost:8000/v1/auth/demo/info
```

---

## 7. Quick Login Test

```bash
# Employee login
curl -X POST http://localhost:8000/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "guest_key": "AAS-DEMO-DEMO-0001",
    "username": "employee1",
    "password": "Demo@1234"
  }'

# Manager login (requires manager_key as second factor)
curl -X POST http://localhost:8000/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "guest_key": "AAS-DEMO-DEMO-0001",
    "username": "admin",
    "password": "Admin@1234",
    "manager_key": "MGR-DEMO-DEMO-0001"
  }'
```

Both return `{"access_token": "...", "role": "...", ...}`.

---

## 8. Seed Sample Data (Optional)

Populate the demo org with 30 days of realistic attendance history:

```bash
python seed.py --all
```

Or seed a specific org:
```bash
python seed.py --org-id <UUID-from-register-response>
```

---

## 9. Create a Private Demo Org

```bash
curl -X POST http://localhost:8000/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "org_name": "My Company",
    "manager_username": "boss",
    "manager_password": "MyPass@123"
  }'
```

Response:
```json
{
  "org_name": "My Company",
  "guest_key": "AAS-XXXX-XXXX-XXXX",
  "manager_key": "MGR-XXXX-XXXX-XXXX",
  "expires_at": "2026-07-06T...",
  "warning": "Save these keys — manager_key is shown only once."
}
```

Share the `guest_key` with employees. Keep the `manager_key` secret.

---

## 10. Run Tests

```bash
pytest tests/ -v
```

Tests use an in-memory SQLite database and mocked Redis — no Docker needed for testing.

---

## API Reference Summary

| Method | Endpoint | Auth | Description |
|--------|----------|------|-------------|
| GET | `/v1/auth/demo/info` | None | Get public demo credentials |
| POST | `/v1/auth/register` | None | Create a private demo org |
| POST | `/v1/auth/login` | None | Login (employee or manager) |
| GET | `/v1/attendance/methods` | Employee JWT | Which methods are enabled |
| GET | `/v1/attendance/qr/generate` | Manager JWT | Get a rotating QR token |
| POST | `/v1/attendance/qr/verify` | Employee JWT | Mark attendance via QR |
| POST | `/v1/attendance/geo/mark` | Employee JWT | Mark attendance via GPS |
| POST | `/v1/attendance/face/challenge` | Employee JWT | Get liveness challenge |
| POST | `/v1/attendance/face/verify` | Employee JWT | Mark attendance via face |
| POST | `/v1/attendance/checkout` | Employee JWT | Check out |
| GET | `/v1/manager/employees` | Manager JWT | List employees |
| POST | `/v1/manager/employees` | Manager JWT | Create employee |
| POST | `/v1/manager/employees/{id}/face` | Manager JWT | Enroll employee face |
| GET | `/v1/manager/settings` | Manager JWT | Get org settings |
| PUT | `/v1/manager/settings` | Manager JWT | Update attendance methods/geofence |
| PUT | `/v1/manager/change-key` | Manager JWT | Change manager auth key |
| GET | `/v1/manager/attendance` | Manager JWT | View all attendance records |
| GET | `/v1/manager/attendance/export` | Manager JWT | Download CSV |
| GET | `/v1/analytics/summary` | Manager JWT | Team overview |
| GET | `/v1/analytics/leaderboard` | Manager JWT | Punctuality rankings |
| GET | `/v1/analytics/individual/{id}` | Manager JWT | Per-employee analytics |
| GET | `/v1/employee/history` | Employee JWT | Personal attendance history |

Full interactive docs: **http://localhost:8000/docs**

---

## Changing the Manager Key

After first login, the manager can change their `MGR-XXXX-XXXX-XXXX` key:

```bash
curl -X PUT http://localhost:8000/v1/manager/change-key \
  -H "Authorization: Bearer <your-token>" \
  -H "Content-Type: application/json" \
  -d '{
    "current_key": "MGR-DEMO-DEMO-0001"
  }'
```

Omit `new_key` to auto-generate, or supply your own in `MGR-XXXX-XXXX-XXXX` format.

---

## File Structure

```
backend/
├── app/
│   ├── main.py              # FastAPI app + startup seeding/cleanup
│   ├── config.py            # Settings from .env
│   ├── database.py          # SQLAlchemy async engine
│   ├── models/              # SQLAlchemy ORM models
│   ├── routers/             # API endpoints
│   │   ├── auth.py          # Login, register, demo info
│   │   ├── attendance.py    # QR / Geo / Face attendance marking
│   │   ├── manager.py       # Employee CRUD, settings, key change
│   │   ├── employee.py      # History, reports
│   │   └── analytics.py     # Team analytics + charts
│   ├── services/
│   │   ├── face_service.py  # DeepFace embeddings + local image storage
│   │   ├── qr_service.py    # TOTP QR tokens (15s window)
│   │   ├── analytics_service.py
│   │   ├── key_service.py   # AAS-/MGR- key generation + hashing
│   │   └── cleanup_service.py  # Expired org face image cleanup
│   └── core/
│       ├── security.py      # JWT + bcrypt
│       ├── encryption.py    # Fernet face embedding encryption
│       └── dependencies.py  # JWT-based auth dependencies
├── alembic/                 # Database migrations
├── tests/                   # pytest test suite
├── seed.py                  # Sample data generator
├── .env.example
└── requirements.txt
```

---

## Stopping the Servers

```bash
# Stop API server: Ctrl+C in the terminal running uvicorn

# Stop Docker services
docker compose down

# Stop AND delete all data (fresh start)
docker compose down -v
```

---

## Troubleshooting

**`connection refused` on port 5432/6379** — Docker Desktop is not running, or containers aren't healthy yet. Run `docker compose ps` and wait 10–15 seconds.

**`alembic: command not found`** — activate your virtualenv: `source .venv/bin/activate`

**DeepFace errors on face enrollment** — the model weights download on first use. Ensure you have ~200 MB free and a working internet connection for the first run.

**`FACE_ENCRYPTION_KEY` error** — you need a valid Fernet key. Generate one with: `python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"`
