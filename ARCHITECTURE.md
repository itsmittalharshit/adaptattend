# Adaptive Attendance System — Architecture

> **Purpose:** Resume-quality full-stack project showcasing QR attendance, facial recognition, geolocation, and smart analytics across a Next.js web app and Flutter Android app.

---

## Table of Contents

1. [System Overview](#1-system-overview)
2. [Tech Stack](#2-tech-stack)
3. [High-Level Architecture](#3-high-level-architecture)
4. [Guest Access & Key System](#4-guest-access--key-system)
5. [Attendance Methods](#5-attendance-methods)
6. [Roles & Flows](#6-roles--flows)
7. [Database Schema](#7-database-schema)
8. [API Design](#8-api-design)
9. [Project Folder Structure](#9-project-folder-structure)
10. [Security & Encryption](#10-security--encryption)
11. [Third-Party Services (Free Tier)](#11-third-party-services-free-tier)
12. [Development Roadmap](#12-development-roadmap)

---

## 1. System Overview

The system has three entry points sharing one backend:

```
[Marketing Website]  →  guest login  →  [Demo Environment]
[Web App (Next.js)]  →  key + login  →  Manager / Employee dashboards
[Android App (Flutter)]  →  key + login  →  Same dashboards, native features
```

Every "organization" in the demo is spawned from a guest key. A guest gets a sandboxed environment with sample data that expires in 15–30 days. Within that org there are manager and employee accounts.

---

## 2. Tech Stack

| Layer | Technology | Reason |
|---|---|---|
| **Frontend (web)** | Next.js 14 (App Router) + TypeScript | SSR for marketing SEO, React for app |
| **Styling** | Tailwind CSS + shadcn/ui | Rapid, consistent UI |
| **Animations** | Framer Motion | Attractive landing page |
| **Charts** | Recharts + Victory | Rich analytics graphs |
| **Mobile** | Flutter 3.x (Dart) | Cross-platform, one codebase |
| **Backend** | Python 3.11 + FastAPI | Async, fast, great ML lib support |
| **ORM** | SQLAlchemy 2.0 (async) + Alembic | Type-safe DB layer |
| **Database** | Supabase (PostgreSQL) | Free managed Postgres + Storage + Auth helpers |
| **Cache / OTP store** | Upstash Redis (free tier) | Low-latency OTP/QR token storage |
| **Email** | Resend (free 3k/month) | OTP and verification emails |
| **OAuth** | Google OAuth 2.0 | Gmail sign-in for guests |
| **Facial Recognition** | DeepFace (Python) | Zero-cost, runs in backend |
| **QR Codes** | `qrcode` + TOTP-style tokens | Time-rotating secure QR |
| **Encryption** | `cryptography` (Fernet) | Face embedding encryption at rest |
| **Auth tokens** | PyJWT | Stateless JWT sessions |
| **Hosting (dev/demo)** | Vercel (frontend) + Railway (backend) | Both have generous free tiers |

---

## 3. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENTS                                  │
│  ┌──────────────────┐   ┌─────────────────┐                    │
│  │  Next.js Web App │   │  Flutter App    │                    │
│  │  (marketing +    │   │  (Android)      │                    │
│  │   dashboard)     │   │                 │                    │
│  └────────┬─────────┘   └────────┬────────┘                    │
└───────────┼──────────────────────┼──────────────────────────────┘
            │  HTTPS / REST        │  HTTPS / REST
            ▼                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                     FastAPI Backend                             │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │
│  │  /auth   │ │/attendance│ │/manager  │ │   /analytics     │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              Services Layer                              │   │
│  │  QRService  FaceService  GeoService  EmailService        │   │
│  └──────────────────────────────────────────────────────────┘   │
└──────┬────────────────────────────┬───────────────────────────┘
       │                            │
       ▼                            ▼
┌──────────────────┐   ┌────────────────────────┐
│ Supabase         │   │ Upstash Redis          │
│ PostgreSQL       │   │ OTP codes              │
│ Storage (faces)  │   │ QR tokens (15s TTL)    │
└──────────────────┘   └────────────────────────┘
```

---

## 4. Guest Access & Key System

### Flow

```
Guest visits website
    │
    ├─► "Try with Gmail" → Google OAuth callback → backend verifies → creates guest record
    │
    └─► "Try with Email" → enters email → backend sends OTP → guest verifies OTP
                                                    │
                                    ┌───────────────▼─────────────────┐
                                    │  Create guest_account record     │
                                    │  Generate unique 12-char KEY     │
                                    │  Seed demo org with sample data  │
                                    │  Set expiry = now + 15 days      │
                                    └───────────────┬─────────────────┘
                                                    │
                                    Display KEY prominently to guest
                                    (also emailed for reference)
```

### Key Format

```
AAS-XXXX-XXXX-XXXX    (e.g., AAS-K7M2-P9QR-4TW8)
```

- 12 random alphanumeric characters after prefix
- Stored hashed in DB; shown plaintext only once (or emailed)
- Linked to one org (demo environment)

### Demo Org Limits

| Resource | Limit |
|---|---|
| Employees | 10 max |
| Attendance records | 500 |
| Face data uploads | 5 |
| Storage | 20 MB |
| Expiry | 15–30 days (configurable) |

---

## 5. Attendance Methods

### 5.1 Time-Adaptive QR Code

```
Manager opens "Generate QR" page
    │
    Backend generates token = TOTP(org_secret, window=15s)
    Stores token in Redis with 15s TTL
    Returns QR payload (JWT containing token + org_id + timestamp)
    │
    QR code displayed, refreshes every 10 seconds
    │
Employee scans QR with app camera
    │
    App sends { scanned_payload, employee_id, scan_timestamp }
    Backend validates: token exists in Redis AND timestamp within window
    If valid → create attendance record (method: QR)
    Token deleted from Redis (one-time use per employee)
```

### 5.2 Geolocation (Phone Location)

```
Manager sets geofence:
    { center_lat, center_lng, radius_meters }  →  stored in org settings

Employee taps "Mark Attendance"
    App requests location permission
    Device GPS → { lat, lng }
    App sends to backend
    Backend calculates Haversine distance from geofence center
    If distance ≤ radius → valid attendance
    Record includes { lat, lng, accuracy_meters }
```

Manager can combine QR + Geo (employee must scan valid QR AND be within geofence).

### 5.3 Facial Recognition with Liveness Detection

```
Employee taps "Face Attendance"
    │
    Backend sends random motion challenge:
    e.g., { "blink twice", "turn head left", "smile" }
    │
    App shows live camera feed with overlay instructions
    Flutter ML Kit detects face landmarks in real-time
    App captures frames as employee performs motions
    Sends { frames[], employee_id, challenge_id }
    │
    Backend (DeepFace):
    1. Verify liveness (motion sequence was performed)
    2. Extract face embedding from best frame
    3. Decrypt stored embedding for this employee
    4. Compare cosine similarity (threshold: 0.4)
    5. If match → create attendance record (method: FACE)

Face data storage:
    embedding (512-float array) → JSON → Fernet encrypt → base64 → store in DB
```

---

## 6. Roles & Flows

### 6.1 Manager

**Login:** unique key → username + password → email OTP (2FA) → JWT issued

**Dashboard sections:**
- **Attendance Controls:** toggle which methods are active (QR / Geo / Face), configure geofence, set office hours
- **Employee Management:** add/edit/remove employees, assign face data, view profiles
- **Live QR Display:** full-screen QR that auto-refreshes every 10s
- **Analytics:**
  - Individual: attendance rate, avg time in office, punctuality score, streak
  - Team: daily/weekly/monthly attendance heatmap, late arrivals chart, presence timeline, top attendance leaderboard

### 6.2 Employee

**Login:** unique key → username + password → JWT issued (no 2FA)

**Dashboard sections:**
- **Mark Attendance:** shows only manager-enabled methods; two actions: Check-In and Check-Out
- **Today's Status:** time checked in, current duration, check-out reminder
- **History:** calendar view of attendance, filter by month, export CSV
- **Time Report:** total hours per week/month

### 6.3 Attendance Record Lifecycle

```
Check-In  →  record created  { check_in: timestamp, status: "present" }
Check-Out →  record updated  { check_out: timestamp, duration: minutes }

Duration calculated as: check_out - check_in (in minutes)
If no check-out by end of day: status = "incomplete"
```

---

## 7. Database Schema

### `guest_accounts`
```sql
id              UUID PRIMARY KEY DEFAULT gen_random_uuid()
email           TEXT UNIQUE NOT NULL
key_hash        TEXT NOT NULL          -- bcrypt hash of the key
org_id          UUID REFERENCES organizations(id)
created_at      TIMESTAMPTZ DEFAULT now()
expires_at      TIMESTAMPTZ NOT NULL
is_active       BOOLEAN DEFAULT true
auth_method     TEXT  -- 'google' | 'email_otp'
google_sub      TEXT  -- Google user ID if OAuth
```

### `organizations`
```sql
id              UUID PRIMARY KEY DEFAULT gen_random_uuid()
name            TEXT NOT NULL
is_demo         BOOLEAN DEFAULT true
settings        JSONB DEFAULT '{}'   -- allowed_methods, geofence, office_hours
created_at      TIMESTAMPTZ DEFAULT now()
expires_at      TIMESTAMPTZ         -- null for real orgs
```

### `users`
```sql
id              UUID PRIMARY KEY DEFAULT gen_random_uuid()
org_id          UUID REFERENCES organizations(id) ON DELETE CASCADE
username        TEXT NOT NULL
password_hash   TEXT NOT NULL
role            TEXT NOT NULL  -- 'manager' | 'employee'
full_name       TEXT
email           TEXT           -- manager's email for OTP
is_active       BOOLEAN DEFAULT true
created_at      TIMESTAMPTZ DEFAULT now()

UNIQUE(org_id, username)
```

### `face_data`
```sql
id              UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id         UUID REFERENCES users(id) ON DELETE CASCADE
encrypted_embedding  TEXT NOT NULL  -- Fernet-encrypted JSON array
storage_path    TEXT               -- Supabase Storage path for sample image
created_at      TIMESTAMPTZ DEFAULT now()
updated_at      TIMESTAMPTZ DEFAULT now()
```

### `qr_tokens`
> Stored in Redis only (ephemeral, 15s TTL).
> Key: `qr:{org_id}:{token}` → Value: `{created_at}`

### `attendance_records`
```sql
id              UUID PRIMARY KEY DEFAULT gen_random_uuid()
user_id         UUID REFERENCES users(id) ON DELETE CASCADE
org_id          UUID REFERENCES organizations(id)
date            DATE NOT NULL
check_in        TIMESTAMPTZ
check_out       TIMESTAMPTZ
duration_minutes INTEGER        -- computed on check_out
method          TEXT            -- 'qr' | 'geo' | 'face'
location        JSONB           -- { lat, lng, accuracy } if geo
status          TEXT DEFAULT 'present'  -- 'present' | 'incomplete' | 'absent'
created_at      TIMESTAMPTZ DEFAULT now()

UNIQUE(user_id, date, check_in)  -- prevents double check-in on same timestamp
```

### `otp_codes`
> Stored in Redis only.
> Key: `otp:{email}` → Value: `{code, attempts}` — TTL: 10 minutes

---

## 8. API Design

Base URL: `https://api.yourdomain.com/v1`

### Auth Routes (`/auth`)

| Method | Path | Description |
|---|---|---|
| POST | `/auth/guest/gmail` | Initiate Google OAuth, return redirect URL |
| GET | `/auth/guest/gmail/callback` | OAuth callback, create/return guest key |
| POST | `/auth/guest/email/send-otp` | Send OTP to email |
| POST | `/auth/guest/email/verify-otp` | Verify OTP, return guest key |
| POST | `/auth/login` | Manager/Employee login (key + username + password) |
| POST | `/auth/manager/verify-otp` | Manager 2FA OTP verification |
| POST | `/auth/refresh` | Refresh JWT token |
| POST | `/auth/logout` | Invalidate token |

### Attendance Routes (`/attendance`)

| Method | Path | Description |
|---|---|---|
| GET | `/attendance/qr/generate` | Generate QR token (manager only) |
| POST | `/attendance/qr/verify` | Employee submits scanned QR |
| POST | `/attendance/geo/mark` | Employee submits location |
| POST | `/attendance/face/challenge` | Get liveness challenge |
| POST | `/attendance/face/verify` | Submit face frames for recognition |
| POST | `/attendance/checkout` | Employee checks out |
| GET | `/attendance/today` | Employee's today record |
| GET | `/attendance/history` | Employee history (paginated, filterable) |

### Manager Routes (`/manager`)

| Method | Path | Description |
|---|---|---|
| GET | `/manager/employees` | List all employees |
| POST | `/manager/employees` | Create employee |
| PUT | `/manager/employees/{id}` | Update employee |
| DELETE | `/manager/employees/{id}` | Deactivate employee |
| POST | `/manager/employees/{id}/face` | Upload/enroll face |
| GET | `/manager/settings` | Get org settings |
| PUT | `/manager/settings` | Update attendance methods, geofence |
| GET | `/manager/attendance` | All attendance records (filterable) |

### Analytics Routes (`/analytics`)

| Method | Path | Description |
|---|---|---|
| GET | `/analytics/team/summary` | Today's team attendance summary |
| GET | `/analytics/team/heatmap` | Date × employee attendance heatmap |
| GET | `/analytics/team/trends` | Weekly/monthly trend data |
| GET | `/analytics/employee/{id}/report` | Individual full report |
| GET | `/analytics/employee/{id}/punctuality` | Punctuality score + history |

---

## 9. Project Folder Structure

```
adaptive-attendance-system/
│
├── backend/                          # FastAPI application
│   ├── app/
│   │   ├── main.py                   # App entry, CORS, router registration
│   │   ├── config.py                 # Settings from .env (Pydantic BaseSettings)
│   │   ├── database.py               # SQLAlchemy async engine + session
│   │   │
│   │   ├── models/                   # SQLAlchemy ORM models
│   │   │   ├── __init__.py
│   │   │   ├── guest.py
│   │   │   ├── organization.py
│   │   │   ├── user.py
│   │   │   ├── face_data.py
│   │   │   └── attendance.py
│   │   │
│   │   ├── schemas/                  # Pydantic request/response schemas
│   │   │   ├── auth.py
│   │   │   ├── user.py
│   │   │   ├── attendance.py
│   │   │   └── analytics.py
│   │   │
│   │   ├── routers/                  # FastAPI route handlers
│   │   │   ├── auth.py
│   │   │   ├── attendance.py
│   │   │   ├── manager.py
│   │   │   ├── employee.py
│   │   │   └── analytics.py
│   │   │
│   │   ├── services/                 # Business logic
│   │   │   ├── qr_service.py         # TOTP token gen/verify, Redis ops
│   │   │   ├── face_service.py       # DeepFace enrollment, comparison, liveness
│   │   │   ├── geo_service.py        # Haversine distance, geofence validation
│   │   │   ├── email_service.py      # Resend API, OTP generation
│   │   │   ├── key_service.py        # Guest key generation, validation
│   │   │   └── analytics_service.py  # Aggregation queries, scoring
│   │   │
│   │   └── core/
│   │       ├── security.py           # JWT creation/validation, password hashing
│   │       ├── encryption.py         # Fernet key management, encrypt/decrypt
│   │       ├── dependencies.py       # FastAPI Depends (get_current_user, etc.)
│   │       └── redis_client.py       # Upstash Redis async client
│   │
│   ├── alembic/                      # Database migrations
│   │   ├── versions/
│   │   └── env.py
│   ├── requirements.txt
│   ├── alembic.ini
│   └── .env.example
│
├── frontend/                         # Next.js 14 application
│   ├── app/
│   │   ├── layout.tsx                # Root layout
│   │   ├── page.tsx                  # Landing page (marketing)
│   │   │
│   │   ├── (marketing)/              # Marketing route group
│   │   │   ├── features/page.tsx
│   │   │   ├── demo/page.tsx         # Guest login (Gmail/OTP)
│   │   │   └── components/
│   │   │       ├── Hero.tsx
│   │   │       ├── FeatureCards.tsx
│   │   │       ├── HowItWorks.tsx
│   │   │       └── DemoSection.tsx
│   │   │
│   │   └── (app)/                    # App route group (requires key)
│   │       ├── enter-key/page.tsx    # Key entry screen
│   │       ├── login/page.tsx        # Username + password
│   │       │
│   │       ├── manager/
│   │       │   ├── layout.tsx        # Manager shell (sidebar)
│   │       │   ├── page.tsx          # Dashboard overview
│   │       │   ├── qr/page.tsx       # Live QR display
│   │       │   ├── employees/
│   │       │   │   ├── page.tsx
│   │       │   │   └── [id]/page.tsx
│   │       │   ├── settings/page.tsx
│   │       │   ├── attendance/page.tsx
│   │       │   └── analytics/page.tsx
│   │       │
│   │       └── employee/
│   │           ├── layout.tsx        # Employee shell
│   │           ├── page.tsx          # Mark attendance
│   │           ├── history/page.tsx
│   │           └── report/page.tsx
│   │
│   ├── components/
│   │   ├── ui/                       # shadcn/ui components
│   │   ├── qr/
│   │   │   └── QRDisplay.tsx         # Auto-refreshing QR component
│   │   ├── attendance/
│   │   │   ├── QRScanner.tsx         # Webcam QR scanner
│   │   │   ├── FaceCapture.tsx       # Webcam face capture
│   │   │   └── GeoAttendance.tsx     # Location button
│   │   ├── analytics/
│   │   │   ├── AttendanceHeatmap.tsx
│   │   │   ├── PunctualityChart.tsx
│   │   │   ├── TeamTrendsChart.tsx
│   │   │   └── EmployeeReport.tsx
│   │   └── layout/
│   │       ├── Navbar.tsx
│   │       ├── ManagerSidebar.tsx
│   │       └── EmployeeSidebar.tsx
│   │
│   ├── lib/
│   │   ├── api.ts                    # Axios instance with interceptors
│   │   ├── auth.ts                   # JWT storage, auth helpers
│   │   └── utils.ts
│   │
│   ├── hooks/
│   │   ├── useAttendance.ts
│   │   ├── useAnalytics.ts
│   │   └── useQR.ts
│   │
│   ├── types/
│   │   └── index.ts                  # Shared TypeScript types
│   │
│   ├── public/
│   │   └── app-download/             # APK download hosted here
│   │
│   ├── next.config.js
│   ├── tailwind.config.js
│   └── package.json
│
├── mobile/                           # Flutter application
│   ├── lib/
│   │   ├── main.dart                 # Entry point
│   │   │
│   │   ├── config/
│   │   │   ├── app_config.dart       # API base URL, constants
│   │   │   └── theme.dart            # App theme, colors
│   │   │
│   │   ├── models/
│   │   │   ├── user.dart
│   │   │   ├── attendance.dart
│   │   │   └── analytics.dart
│   │   │
│   │   ├── services/
│   │   │   ├── api_service.dart      # Dio HTTP client
│   │   │   ├── auth_service.dart     # JWT storage (flutter_secure_storage)
│   │   │   ├── qr_service.dart       # mobile_scanner wrapper
│   │   │   ├── face_service.dart     # google_mlkit_face_detection + camera
│   │   │   └── geo_service.dart      # geolocator wrapper
│   │   │
│   │   ├── providers/                # Riverpod state providers
│   │   │   ├── auth_provider.dart
│   │   │   ├── attendance_provider.dart
│   │   │   └── analytics_provider.dart
│   │   │
│   │   └── screens/
│   │       ├── splash/
│   │       │   └── splash_screen.dart
│   │       ├── onboarding/
│   │       │   └── enter_key_screen.dart
│   │       ├── auth/
│   │       │   └── login_screen.dart
│   │       ├── manager/
│   │       │   ├── manager_shell.dart       # Bottom nav shell
│   │       │   ├── dashboard_screen.dart
│   │       │   ├── qr_display_screen.dart
│   │       │   ├── employees_screen.dart
│   │       │   ├── settings_screen.dart
│   │       │   └── analytics_screen.dart
│   │       └── employee/
│   │           ├── employee_shell.dart
│   │           ├── mark_attendance_screen.dart
│   │           ├── qr_scan_screen.dart
│   │           ├── face_scan_screen.dart
│   │           ├── geo_attendance_screen.dart
│   │           ├── history_screen.dart
│   │           └── report_screen.dart
│   │
│   ├── assets/
│   │   ├── images/
│   │   └── icons/
│   │
│   ├── android/
│   │   └── app/build.gradle          # Android config
│   │
│   ├── pubspec.yaml
│   └── README.md
│
├── docs/
│   ├── ARCHITECTURE.md               # This file
│   ├── API.md                        # Full API reference
│   ├── SETUP.md                      # Local dev setup guide
│   └── diagrams/
│       ├── system-overview.png
│       └── db-schema.png
│
└── .github/
    └── workflows/
        ├── backend-ci.yml            # Python tests + lint
        └── frontend-ci.yml           # Next.js build check
```

---

## 10. Security & Encryption

### Face Data Encryption

```python
# Fernet symmetric encryption
from cryptography.fernet import Fernet

# Key stored in env variable (never in DB)
FACE_ENCRYPTION_KEY = os.getenv("FACE_ENCRYPTION_KEY")  # base64 32-byte key
fernet = Fernet(FACE_ENCRYPTION_KEY)

def encrypt_embedding(embedding: list[float]) -> str:
    data = json.dumps(embedding).encode()
    return fernet.encrypt(data).decode()  # base64 string

def decrypt_embedding(encrypted: str) -> list[float]:
    data = fernet.decrypt(encrypted.encode())
    return json.loads(data)
```

### JWT Strategy

- Short-lived access tokens: 30 minutes
- Refresh tokens: 7 days, stored httpOnly cookie
- Manager tokens require OTP claim (`"otp_verified": true`)

### Password Storage

- bcrypt with cost factor 12
- No plaintext passwords ever logged or returned

### QR Token Security

- TOTP-style: `HMAC-SHA256(org_secret, floor(unix_time / 15))`
- One-time use: token deleted from Redis after first valid scan
- Payload signed as JWT (prevents tampering)

---

## 11. Third-Party Services (Free Tier)

| Service | Usage | Free Limit |
|---|---|---|
| **Supabase** | PostgreSQL + Storage | 500MB DB, 1GB storage |
| **Upstash Redis** | OTP + QR tokens | 10K commands/day |
| **Resend** | Transactional email (OTP) | 3,000 emails/month |
| **Google OAuth** | Gmail guest login | Free |
| **Vercel** | Next.js hosting | 100GB bandwidth |
| **Railway** | FastAPI hosting | $5 free credit/month |

Total monthly cost at demo scale: **$0**

---

## 12. Development Roadmap

### Phase 1 — Foundation (Week 1–2)
- [ ] Supabase project setup, schema migrations
- [ ] FastAPI project scaffold + auth routes (OTP, Gmail OAuth, JWT)
- [ ] Guest key generation and demo org seeding
- [ ] Next.js project + marketing landing page
- [ ] Flutter project + key entry + login screens

### Phase 2 — Attendance Core (Week 3–4)
- [ ] QR generation + Redis token store
- [ ] QR scan on web (webcam) and Flutter (mobile_scanner)
- [ ] Geolocation attendance (web Geolocation API + Flutter geolocator)
- [ ] Face enrollment API (DeepFace embedding + Fernet encrypt)
- [ ] Face attendance + liveness challenge

### Phase 3 — Dashboards (Week 5–6)
- [ ] Manager dashboard: employee CRUD, live QR screen
- [ ] Attendance settings (toggle methods, geofence config)
- [ ] Employee dashboard: mark attendance, check-in/out, history
- [ ] Mobile: mirror all dashboard screens

### Phase 4 — Analytics (Week 7)
- [ ] Aggregation queries (heatmap, trends, punctuality score)
- [ ] Recharts visualizations: heatmap, bar chart, line chart
- [ ] Individual employee report
- [ ] Export attendance CSV

### Phase 5 — Polish (Week 8)
- [ ] Marketing website animations (Framer Motion)
- [ ] APK build, host download on website
- [ ] Demo data seeder script
- [ ] End-to-end test walkthrough
- [ ] README + demo video script
