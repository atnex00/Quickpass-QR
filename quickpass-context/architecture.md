---
tags:
  - quickpass
  - architecture
  - overview
---
# Quickpass Architecture

## Overview
QR-based gate pass and leave management system. Employees request leave → supervisor approves → QR codes generated (OUT + IN) → security scans at gates.

## Tech Stack

| Layer | Technology |
|---|---|
| Backend | Node.js + Express + Knex (PostgreSQL) |
| Web | React 19 + TypeScript + Vite 6 + Tailwind v4 |
| Mobile | Flutter 3.27+ + Provider + Dio |
| Database | PostgreSQL (Supabase cloud) |
| Auth | JWT (HS256, Bearer token) + HTTP-only cookie refresh |

## Repository Structure

```
/Quickpass-QR/
├── backend/          # Express API server
│   ├── src/
│   │   ├── app.js          # Main entry (Express bootstrap)
│   │   ├── config/         # DB + Firebase config
│   │   ├── controllers/    # Route handlers (5 controllers)
│   │   ├── middleware/     # Auth, validation, error handling
│   │   ├── routes/         # All routes in one file
│   │   └── services/       # QR, push notifications, image gen
│   ├── uploads/
│   │   ├── photos/         # Profile photos
│   │   └── qr_codes/       # Generated QR images
│   ├── knexfile.js
│   └── package.json
├── flutter_app/      # Flutter mobile app
│   └── lib/
│       ├── main.dart
│       ├── config/         # Theme, app config
│       ├── models/         # Data models (json_serializable)
│       ├── providers/      # ChangeNotifiers (5 providers)
│       ├── screens/        # 20 screens in 5 role categories
│       ├── services/       # API service + QR service
│       ├── utils/          # Validators, formatters, constants
│       └── widgets/        # Reusable widgets
├── web/              # React web app
│   └── src/
│       ├── App.tsx         # Router setup
│       ├── index.css       # Tailwind v4 + theme tokens
│       ├── lib/            # Axios client + utilities
│       ├── stores/         # Zustand stores (3)
│       ├── types/          # TypeScript interfaces
│       ├── components/     # Layout, shared, shadcn/ui
│       └── pages/          # 17 pages
└── database/          # Shared migrations & seeds
    ├── migrations/    # 10 migration files
    └── seeds/         # Departments + employees
```

## Key Architecture Decisions

- **Single route file** (`routes/index.js`) — all endpoints in one place
- **No ORM** — Knex query builder with raw-ish SQL patterns
- **LEFT JOIN on leave_requests** — always join employees for employee/supervisor names
- **In-memory JWT** on web (not localStorage); Flutter uses FlutterSecureStorage
- **Joi validation** — all request bodies/queries validated
- **Rate limited** — 100 req / 15 min global
