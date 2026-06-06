# Backend Setup & Testing Guide

This guide walks you through running the FastAPI backend from scratch to a fully working API you can explore via Swagger UI.

---

## Prerequisites

| Tool | Version | Install |
|---|---|---|
| Python | 3.11+ | https://python.org |
| pip | latest | `pip install --upgrade pip` |
| Git | any | https://git-scm.com |

No Docker required. All external services have free tiers.

---

## Step 1 — Create Free Service Accounts

You need four free accounts. Each takes ~2 minutes:

### 1.1 Supabase (PostgreSQL database)
1. Go to https://supabase.com → Sign up → New project
2. Choose a region, set a DB password
3. Wait ~1 min for project to provision
4. Go to **Project Settings → API**
   - Copy **Project URL** → `SUPABASE_URL`
   - Copy **service_role** key → `SUPABASE_SERVICE_KEY`
5. Go to **Project Settings → Database → Connection string → URI**
   - Replace `[YOUR-PASSWORD]` with your DB password
   - Change `postgresql://` to `postgresql+asyncpg://`
   - This is your `DATABASE_URL`

### 1.2 Upstash Redis (OTP + QR token cache)
1. Go to https://console.upstash.com → Sign up → Create database
2. Choose **Global** region, type `attendance-cache`
3. Click the database → copy **REDIS_URL** (the `rediss://` URL)

### 1.3 Resend (transactional email for OTPs)
1. Go to https://resend.com → Sign up
2. **API Keys → Create API Key** → copy it → `RESEND_API_KEY`
3. Add a sending domain OR use the sandbox (sends only to your own email)
4. Set `FROM_EMAIL=onboarding@resend.dev` for sandbox testing

### 1.4 Google OAuth (optional — for Gmail guest login)
1. Go to https://console.cloud.google.com
2. Create a project → **APIs & Services → Credentials → Create OAuth 2.0 Client**
3. Application type: **Web application**
4. Add authorized redirect URI: `http://localhost:8000/v1/auth/guest/gmail/callback`
5. Copy **Client ID** and **Client Secret**

> **Skip Google OAuth for initial testing** — email OTP works fine without it.

---

## Step 2 — Clone and Configure

```bash
cd "Adaptive Attendance System/backend"

# Create virtual environment
python -m venv venv
source venv/bin/activate        # macOS/Linux
# venv\Scripts\activate          # Windows

# Install dependencies (takes ~3 min; DeepFace is large)
pip install -r requirements.txt
```

Copy and fill in the environment file:

```bash
cp .env.example .env
```

Open `.env` and fill in all values. Minimum required:

```env
DATABASE_URL=postgresql+asyncpg://postgres.xxxx:PASSWORD@aws-xxx.pooler.supabase.com:5432/postgres
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_SERVICE_KEY=eyJ...

REDIS_URL=rediss://default:PASSWORD@xxxxx.upstash.io:6379

JWT_SECRET=pick-any-random-string-at-least-32-chars
JWT_ALGORITHM=HS256

FACE_ENCRYPTION_KEY=   # generate below

RESEND_API_KEY=re_xxxx
FROM_EMAIL=onboarding@resend.dev

# Google OAuth — fill in or leave as dummy values
GOOGLE_CLIENT_ID=dummy
GOOGLE_CLIENT_SECRET=dummy
GOOGLE_REDIRECT_URI=http://localhost:8000/v1/auth/guest/gmail/callback
```

Generate the face encryption key:

```bash
python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"
# Paste the output as FACE_ENCRYPTION_KEY in .env
```

---

## Step 3 — Run Database Migrations

```bash
# Option A: Auto-create tables (simplest for development)
python -c "import asyncio; from app.database import create_db_tables; asyncio.run(create_db_tables())"

# Option B: Use Alembic (production-style)
alembic upgrade head
```

---

## Step 4 — Start the Server

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

You should see:

```
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
INFO:     Application startup complete.
```

---

## Step 5 — Explore the API with Swagger UI

Open your browser: **http://localhost:8000/docs**

You'll see the full interactive API documentation. Here's the recommended flow to test everything:

---

## Step 6 — Full Test Walkthrough

### 6.1 Create a Guest Account (get your access key)

In Swagger, find **Auth → POST /v1/auth/guest/email/send-otp**:
```json
{ "email": "your@email.com" }
```
Check your inbox for the OTP, then call **POST /v1/auth/guest/email/verify-otp**:
```json
{ "email": "your@email.com", "code": "123456" }
```
Response includes your **unique key** like `AAS-K7M2-P9QR-4TW8`. **Save this.**

---

### 6.2 Login as Employee

**POST /v1/auth/login**:
```json
{
  "guest_key": "AAS-K7M2-P9QR-4TW8",
  "username": "employee1",
  "password": "Demo@1234"
}
```
Response → copy the `access_token`.

Click **Authorize** (top right of Swagger) → paste `Bearer <token>`.

---

### 6.3 Check Available Attendance Methods

**GET /v1/attendance/methods** — see which methods the manager enabled.

---

### 6.4 Mark Attendance via QR

First, login as manager (see 6.5), generate a QR, then back to employee:

**POST /v1/attendance/qr/verify**:
```json
{ "qr_jwt": "<paste the qr_jwt from the manager endpoint>" }
```
Response: `{ "action": "check_in", ... }`

Call it again → `{ "action": "check_out", "duration_minutes": 0, ... }`

---

### 6.5 Login as Manager (2FA flow)

**POST /v1/auth/login** with `username: "manager"` → returns `requires_otp: true` + `partial_token`.

Check email for OTP, then **POST /v1/auth/manager/verify-otp**:
- Add `Authorization: Bearer <partial_token>` header
- Body: `{ "code": "123456" }`

Response → full `access_token`. Authorize with it.

---

### 6.6 Manager: Generate QR

**GET /v1/attendance/qr/generate** → copy `qr_jwt`, use in employee's QR verify call.

---

### 6.7 Manager: View All Attendance

**GET /v1/manager/attendance** — paginated, filterable by date range and employee.

**GET /v1/manager/attendance/export** — download CSV.

---

### 6.8 Manager: Configure Geofence

**PUT /v1/manager/settings**:
```json
{
  "allowed_methods": ["qr", "geo"],
  "geofence": {
    "lat": 28.6139,
    "lng": 77.2090,
    "radius_meters": 300
  }
}
```

---

### 6.9 Analytics

All under `/v1/analytics/`:

| Endpoint | What you'll see |
|---|---|
| `GET /team/summary` | Present/absent count today |
| `GET /team/heatmap?days=30` | Full attendance matrix |
| `GET /team/trends?days=30` | Daily trend numbers for a line chart |
| `GET /team/leaderboard` | Ranked by attendance rate |
| `GET /employee/{id}/report` | Individual stats with streaks & punctuality score |
| `GET /employee/{id}/hours-chart?weeks=8` | Weekly hours for a bar chart |

---

### 6.10 Seed Demo Data (30 days of realistic history)

```bash
# Seed ALL demo orgs
python seed.py --all

# Or seed a specific org
python seed.py --org-id <UUID from DB>

# Generate 60 days instead
python seed.py --all --days 60
```

After seeding, the analytics endpoints return populated charts and scores.

---

## Step 7 — Run Tests

```bash
# Install test dependencies
pip install pytest pytest-asyncio httpx aiosqlite

# Run all tests
pytest -v

# Run a specific test file
pytest tests/test_auth.py -v

# Run with coverage
pip install pytest-cov
pytest --cov=app --cov-report=term-missing
```

Expected output (all green):
```
tests/test_auth.py::test_send_guest_otp PASSED
tests/test_auth.py::test_verify_guest_otp_invalid PASSED
...
tests/test_analytics.py::test_team_summary PASSED
...
================================ 35 passed in 8.45s ================================
```

---

## Project Structure (Backend)

```
backend/
├── app/
│   ├── main.py              # FastAPI app, CORS, router registration
│   ├── config.py            # Pydantic settings (reads .env)
│   ├── database.py          # SQLAlchemy async engine
│   ├── core/
│   │   ├── security.py      # JWT, bcrypt
│   │   ├── encryption.py    # Fernet face data encryption
│   │   ├── redis_client.py  # Upstash Redis async client
│   │   └── dependencies.py  # FastAPI Depends (auth guards)
│   ├── models/              # SQLAlchemy ORM models
│   ├── schemas/             # Pydantic request/response models
│   ├── routers/
│   │   ├── auth.py          # Guest login, OAuth, JWT
│   │   ├── attendance.py    # QR, Geo, Face check-in/out
│   │   ├── manager.py       # Employee CRUD, settings, export
│   │   ├── employee.py      # History, calendar, report
│   │   └── analytics.py     # Heatmap, trends, leaderboard
│   └── services/
│       ├── qr_service.py    # TOTP tokens + Redis
│       ├── face_service.py  # DeepFace + Fernet encryption
│       ├── geo_service.py   # Haversine distance
│       ├── email_service.py # OTP via Resend
│       ├── key_service.py   # Guest key generation
│       └── analytics_service.py  # Punctuality, streaks
├── alembic/                 # DB migrations
├── tests/                   # pytest test suite
├── seed.py                  # Demo data generator
├── requirements.txt
├── pytest.ini
└── .env.example
```

---

## API Summary

| Category | Endpoints |
|---|---|
| **Auth** | send-otp, verify-otp, gmail oauth, login, manager 2FA, logout |
| **Attendance** | generate QR, verify QR, geo mark, face challenge, face verify, checkout, today, history, allowed methods |
| **Manager** | list/create/update/delete employees, face enroll/remove, get/update settings, view attendance, export CSV |
| **Employee** | profile, history (paginated), monthly calendar, week/month report, export CSV |
| **Analytics** | team summary, heatmap, trends, method breakdown, leaderboard, individual report, hours chart |
| **Health** | GET /health |

Total: **30+ endpoints**, all documented at http://localhost:8000/docs

---

## Common Issues

**`ModuleNotFoundError: No module named 'app'`**
→ Run commands from inside the `backend/` directory, with the venv activated.

**`asyncpg.exceptions.InvalidPasswordError`**
→ Check your `DATABASE_URL` password. URL-encode special characters (e.g., `@` → `%40`).

**DeepFace download on first run**
→ On first `/attendance/face/challenge` call, DeepFace downloads model weights (~100MB). This is a one-time download.

**Redis connection refused**
→ Check `REDIS_URL` — Upstash uses `rediss://` (with double s for TLS).

**OTP not arriving**
→ In Resend free tier, you can only send to your own verified email. Use the sandbox `FROM_EMAIL=onboarding@resend.dev`.
