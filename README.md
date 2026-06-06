# AdaptAttend — Adaptive Attendance System

> **100% offline · No backend · No cloud · All data stays on-device**

A Flutter portfolio project demonstrating a full-featured employee attendance system that works entirely on-device — no server, no internet required after install.

---

## ✨ Features

| Feature | How it works |
|---|---|
| **6-digit TOTP** | Time-based one-time code, refreshes every 30 s |
| **QR Code scan** | Employee scans rotating QR from manager screen |
| **GPS Geo-fence** | Blocks attendance outside configurable office radius |
| **Manager Face Scan** | Manager holds camera on employee's face — on-device LBP recognition, no model download |
| **Shift & schedule** | Configurable shifts with auto check-out |
| **Offline-first** | Drift (SQLite) for all records; SharedPreferences for face embeddings |

---

## 📱 Tech Stack

- **Flutter 3** — Material 3 UI, go_router, Riverpod-free (ValueNotifier + Provider)
- **Drift** — type-safe SQLite ORM, fully offline
- **Google ML Kit** — face bounding-box detection (on-device, no model download needed)
- **LBP Face Recognition** — 256-bin Local Binary Pattern histogram, cosine similarity ≥ 0.82
- **Geolocator** — GPS geo-fence enforcement
- **SharedPreferences** — lightweight face embedding storage

---

## 🏗 Project Structure

```
adaptattend/
├── mobile/          # Flutter app
│   ├── lib/
│   │   ├── data/        # Drift database (tables, DAOs)
│   │   ├── services/    # Face recognition, QR, seed data
│   │   ├── screens/
│   │   │   ├── manager/ # Dashboard, employees, attendance, face scan
│   │   │   └── employee/# Dashboard, mark attendance, profile
│   │   └── widgets/     # Shared UI components
│   └── assets/images/   # Demo employee photos (pre-enrolled at launch)
├── frontend/        # Next.js marketing website
└── backend/         # Legacy Python stub (not used — app is 100% offline)
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.x (`flutter --version`)
- Android emulator or physical Android device (API 21+)

### Run

```bash
cd mobile
flutter pub get
flutter run
```

The app seeds five demo employees on first launch (face embeddings pre-enrolled from bundled photos). Use the **Manager** flow to try face attendance, or the **Employee** flow to mark attendance via TOTP / QR / GPS.

### Demo credentials

| Role | Email | PIN |
|---|---|---|
| Manager | manager@demo.com | 1234 |
| Employee | emp@demo.com | 1234 |

---

## 🌐 Website

Live: **[adaptattend.vercel.app](https://adaptattend.vercel.app)**

```bash
cd frontend
npm install
npm run dev   # localhost:3000
```

---

## 🔒 Security Notes

- Face embeddings never leave the device (stored in SharedPreferences as JSON)
- Employee-side face scan includes a geo-fence guard (must be within office radius)
- Manager-side face scan runs on the manager's device — employees can't self-serve from home
- TOTP codes rotate every 30 s using device time

---

## 👤 Author

**Harshit Mittal**
[LinkedIn](https://www.linkedin.com/in/theharshitmittal/) · [GitHub](https://github.com/itsmittalharshit) · mittalharshit99@gmail.com

---

*Built as a portfolio project to demonstrate Flutter architecture, on-device ML, and offline-first design.*
