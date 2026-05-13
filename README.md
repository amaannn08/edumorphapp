# Shiksha Verse 📚

> Minimalist EdTech platform — lecture reels, shorts, and quiz battles.

[![Deploy to EC2](https://github.com/yourusername/shiksha-verse/actions/workflows/deploy.yml/badge.svg)](https://github.com/yourusername/shiksha-verse/actions)

---

## Quick Navigation

| Document | Description |
|---|---|
| [ARCHITECTURE.md](./ARCHITECTURE.md) | System overview, data flows, design decisions |
| [BACKEND.md](./BACKEND.md) | Full API reference with request/response examples |
| [DATABASE.md](./DATABASE.md) | Neon PostgreSQL schema + common queries |
| [DEPLOYMENT.md](./DEPLOYMENT.md) | Step-by-step AWS EC2, S3, Neon, GitHub Actions setup |
| [FRONTEND.md](./FRONTEND.md) | Flutter project structure, API wiring, design tokens |

---

## Repository Structure

```
EduMorph/App/
├── backend/          Node.js + Express API
├── frontend/         Flutter mobile + web app
└── .github/
    └── workflows/    GitHub Actions CI/CD
```

---

## Getting Started

### Backend
```bash
cd backend
cp .env.example .env     # Fill in Neon URL, AWS keys, JWT secrets
npm install
npm run db:migrate       # Create tables in Neon
npm run dev              # Start dev server at http://localhost:3000
```

### Frontend
```bash
cd frontend
flutter pub get
flutter run -d chrome    # Web (no emulator needed)
# or
flutter run -d android   # Android emulator/device
```

### Frontend → Backend (development)
Edit `frontend/lib/core/services/api_config.dart`:
```dart
static const String _devUrl = 'http://localhost:3000'; // web
// or
static const String _devUrl = 'http://10.0.2.2:3000'; // Android emulator
```

### Frontend → Backend (production)
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
| Media Storage | AWS S3 |
| Email / OTP | Nodemailer → AWS SES |
| Auth | JWT access (15min) + refresh (7d) |
| Process Manager | PM2 (cluster mode) |
| Reverse Proxy | Nginx |
| Hosting | AWS EC2 t3.micro |
| CI/CD | GitHub Actions |

---

## Scripts

| Command | Description |
|---|---|
| `npm run dev` | Start backend with nodemon |
| `npm start` | Start backend (production) |
| `npm run db:migrate` | Apply schema to Neon |
| `npm test` | Run Jest tests |
| `flutter run -d chrome` | Run Flutter on Chrome |
| `flutter analyze` | Check Flutter for lint issues |
