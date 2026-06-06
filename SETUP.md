# AdaptAttend — Setup Guide

Three independent pieces. Run each in its own Terminal tab.

---

## Architecture

```
Flutter App (Android)
  ├── SQLite on-device (Drift)  ← all persistent data lives here
  └── FastAPI backend calls only for:
        • QR token generate / verify  (Redis one-time-use)
        • Face enroll / verify        (DeepFace FaceNet512)
        • Geofence check              (Haversine, stateless)

Marketing Website (Next.js)
  └── Pure static marketing, EmailJS contact form
```

---

## 1 — Marketing Website

```bash
cd frontend
npm install --legacy-peer-deps
npm run dev
# → http://localhost:3000
```

**EmailJS contact form setup** (one-time):
1. Sign up at https://www.emailjs.com (free tier)
2. Create a service connected to Gmail → copy **Service ID**
3. Create a template with variables `from_name`, `reply_to`, `subject`, `message` → copy **Template ID**
4. Copy your **Public Key** from Account → API Keys
5. Open `frontend/app/page.tsx`, find `ContactSection`, fill in the three placeholders

---

## 2 — FastAPI Backend (Python 3.12)

```bash
# One-time setup
brew install python@3.12 redis
brew services start redis

cd backend
python3.12 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

cp .env.example .env
# Auto-generate secrets:
JWT=$(python -c "import secrets; print(secrets.token_hex(32))")
FERNET=$(python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())")
sed -i '' "s/replace_with_random_hex/$JWT/" .env
sed -i '' "s/replace_with_fernet_key/$FERNET/" .env

# Run
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
# API docs → http://localhost:8000/docs
```

Or just run: `bash start_backend.sh`

**Endpoints:**
| Method | Path | Description |
|--------|------|-------------|
| POST | `/qr/generate` | Generate 15s QR token |
| POST | `/qr/verify` | Consume QR token (one-time) |
| GET | `/face/challenge` | Liveness prompt |
| POST | `/face/enroll` | Extract + encrypt face embedding |
| POST | `/face/verify` | Match live face vs stored embedding |
| POST | `/geo/check` | Geofence haversine check |
| GET | `/health` | Status |

---

## 3 — Flutter Android App

### Prerequisites
```bash
# Install Flutter SDK
brew install --cask flutter
flutter doctor   # fix any issues shown

# Android Studio → SDK Manager → install:
#   Android SDK Platform 34
#   Android Emulator (or use a physical device)
```

### Generate Drift code (one-time after any schema change)
```bash
cd mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Run on emulator
```bash
flutter emulators --launch <your_emulator_id>
flutter run
```

### Run on physical Android device
1. Enable Developer Options on the phone
2. Enable USB Debugging
3. Connect via USB
4. Update `lib/services/api_service.dart`:
   ```dart
   // Change this line:
   const _baseUrl = 'http://10.0.2.2:8000';   // emulator
   // To your Mac's LAN IP:
   const _baseUrl = 'http://192.168.1.X:8000'; // physical device
   ```
5. `flutter run`

### Build release APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

---

## Demo credentials (seeded on first launch)

| Role | Username | PIN |
|------|----------|-----|
| Manager | manager | 1234 |
| Employee | emma | 1234 |
| Employee | liam | 1234 |
| Employee | sofia | 1234 |
| Employee | noah | 1234 |
| Employee | zara | 1234 |

Demo org has 30 days of seeded attendance at 87% rate across all methods (QR/GPS/Face).
Manager can add up to 5 additional employees (demo limit).

---

## Quick Start (all three together)

```bash
# Tab 1: Redis + FastAPI
bash start_backend.sh

# Tab 2: Marketing website
bash start_website.sh

# Tab 3: Flutter (emulator must be running)
cd mobile && flutter run
```
