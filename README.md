# Shiksha Verse 📚

> Minimalist EdTech platform for Indian students — lecture reels, Shorts, AI-powered vault, and quiz battles.

[![Deploy to EC2](https://github.com/yourusername/shiksha-verse/actions/workflows/deploy.yml/badge.svg)](https://github.com/yourusername/shiksha-verse/actions)

---

## Quick Navigation

| Document | Description |
|---|---|
| [ARCHITECTURE.md](./ARCHITECTURE.md) | System overview, data flows, design decisions |
| [BACKEND.md](./BACKEND.md) | Full API reference (all routes, rate limits, error codes) |
| [DATABASE.md](./DATABASE.md) | Neon PostgreSQL schema (all 16 tables) + common queries |
| [DEPLOYMENT.md](./DEPLOYMENT.md) | Step-by-step AWS EC2, S3, Twilio, Google OAuth, GitHub Actions |
| [FRONTEND.md](./FRONTEND.md) | Flutter project structure, routes, ApiService usage, design tokens |

---

## Repository Structure

```
EduMorph/App/
├── backend/          Node.js 20 + Express API
├── frontend/         Flutter 3.41.9 (Android / iOS / Web)
└── .github/
    └── workflows/    GitHub Actions CI/CD → EC2
```

---

## Getting Started

### Backend
```bash
cd backend
cp .env.example .env     # Fill in DATABASE_URL (Neon), JWT secrets, AWS keys
npm install
npm run db:migrate       # Create all 16 tables in Neon
npm run db:seed          # Seed Special Ops + battle rooms
npm run dev              # Start dev server at http://localhost:3000
```

> **OTP in dev mode**: If `SMS_PROVIDER_KEY` is not set, phone OTPs are printed to the console — no Twilio account required for local testing.

### Frontend
```bash
cd frontend
flutter pub get
flutter run -d chrome    # Web — fastest for UI iteration
# or
flutter run -d android   # Android emulator / physical device
```

### Connecting Frontend → Backend (local dev)
Edit `frontend/lib/core/services/api_config.dart`:
```dart
static const String _devUrl = 'http://localhost:3000';  // Chrome
// or
static const String _devUrl = 'http://10.0.2.2:3000';  // Android emulator
```

### Production Build
```bash
flutter build apk --dart-define=BACKEND_URL=https://api.yourdomain.com
```

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile / Web | Flutter 3.41.9 |
| API | Node.js 20 + Express |
| Database | Neon PostgreSQL (serverless) |
| Media Storage | AWS S3 (presigned URL direct upload) |
| Phone OTP | Twilio SMS |
| Email OTP | Nodemailer → AWS SES |
| Google SSO | google_sign_in (Flutter) + Google OAuth 2.0 |
| AI Summaries | OpenAI API (vault notes) |
| Auth | JWT access (15 min) + refresh (7 d) + SharedPreferences |
| Video Playback | video_player + chewie |
| Process Manager | PM2 (cluster mode) |
| Reverse Proxy | Nginx |
| Hosting | AWS EC2 t3.micro |
| CI/CD | GitHub Actions |

---

## Key Features

| Module | What it does |
|---|---|
| **Auth** | Phone OTP (Twilio) + Google SSO + email/password |
| **Home** | Daily streak, resume card, subject-filtered trending feed |
| **Lecture Detail** | Course hero, lesson list, bookmark per lesson, doubt modal |
| **Video Player** | Native `video_player` + `chewie` controls |
| **Shorts** | Vertical PageView reels with like/view tracking |
| **Vault** | Notes CRUD + AI summarisation + Doubts tracker + Mind Maps |
| **Battlefield** | Live countdown, Special Ops quiz missions, open battle rooms, global leaderboard |
| **Profile** | XP, streak, weekly activity chart, subjects, sign out |

---

## Scripts

| Command | Description |
|---|---|
| `npm run dev` | Start backend with nodemon (hot reload) |
| `npm start` | Start backend (production) |
| `npm run db:migrate` | Apply schema to Neon (idempotent) |
| `npm run db:seed` | Insert Special Ops + battle room sample data |
| `npm test` | Run Jest tests |
| `flutter pub get` | Install Flutter dependencies |
| `flutter run -d chrome` | Run Flutter on Chrome |
| `flutter analyze` | Check Flutter for lint issues (should report 0) |
| `flutter build apk` | Build release Android APK |
