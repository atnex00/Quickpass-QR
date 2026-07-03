# Quickpass — Project Guide for AI Agents

QR-based gate pass and leave management system.

- **web/** — React 19 + TypeScript + Vite 6 + Tailwind v4 (shadcn/ui patterns)
- **flutter_app/** — Flutter 3.27+ + Provider + Dio
- **backend/** — Node.js + Express + PostgreSQL (Knex) + JWT
- **database/** — Shared migration files (root level, not inside backend)

## Setup

### Prerequisites
- Node.js 20+, Flutter 3.27+, PostgreSQL 14+ (or Supabase)
- Or use the dev container (`.devcontainer/`)

### Quick Start
```bash
# 1. Copy env file
cp backend/.env.example backend/.env
# 2. Install deps
cd backend && npm install && cd ../flutter_app && flutter pub get
# 3. Create database + run migrations + seed
createdb passlynx
cd backend && npm run migrate && npm run seed
# 4. Start backend + Flutter (two terminals)
cd backend && npm run dev
cd flutter_app && flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

The setup script (`scripts/setup.ps1` on Windows, `scripts/setup.sh` on macOS/Linux) installs Flutter and Android SDK into `tools/` without system-wide installs.

### Env Loading
`NODE_ENV` determines which `.env.*` file the backend loads (defaults to `dev` → `.env.dev`). The knexfile loads via `require('dotenv').config({ path: \`.env.\${process.env.NODE_ENV || 'dev'}\` })`.

## Commands

### Root
| Command | Purpose |
|---|---|
| `npm run dev` | Start backend + web concurrently (via `dev.sh`) |
| `npm run prod` | Start in production mode |
| `npm run dev:backend` | Backend only (nodemon) |
| `npm run dev:web` | Web only (Vite dev server) |
| `npm run migrate` | Run Knex migrations |
| `npm run seed` | Run database seeds |

### Backend (`backend/`)
| Command | Purpose |
|---|---|
| `npm run dev` | nodemon on `src/app.js` |
| `npm start` | Production start |
| `npm test` | Jest (`--coverage --forceExit --detectOpenHandles`) |
| `npm run migrate` | Knex migrate:latest |
| `npm run migrate:rollback` | Knex migrate:rollback |
| `npm run seed` | Knex seed:run |
| `npm run lint` | ESLint on `src/` |

Seeds need `bcryptjs`. Run from `backend/` directory (resolves to `backend/node_modules/bcryptjs`). If running from root, `bcryptjs` is also installed at root level.

### Web (`web/`)
| Command | Purpose |
|---|---|
| `npm run dev` | Vite dev server on port 8080 |
| `npm run build` | `tsc -b && vite build` |
| `npm run lint` | ESLint |

Web dev server proxies `/api` → `http://localhost:3000` (defined in `vite.config.ts`).

### Flutter (`flutter_app/`)
| Command | Purpose |
|---|---|
| `flutter run` | Run on connected device |
| `flutter build apk` | Build Android APK |
| `flutter build appbundle` | Build Android App Bundle |
| `flutter build ios` | Build iOS |
| `flutter analyze` | Static analysis |

API base URL is a compile-time env var (`API_BASE_URL`). Override with `--dart-define=API_BASE_URL=http://...`. Default fallback is `http://182.168.0.231:3000/api` (likely a typo for `192.168`).

## Architecture

### Roles
- `is_admin` — Full access
- `is_supervisor` — Approve/reject department leave requests
- `is_security` — Scan QR codes at gates
- Regular employee — Submit leaves, view history

### Workflow
1. Employee requests leave → `pending`
2. Supervisor approves → QR codes generated (OUT + IN)
3. Security scans OUT QR at exit → `active`
4. Security scans IN QR at entry → `completed`

QR valid ±15 minutes from scheduled time (start_time for OUT, end_time for IN). HMAC-SHA256 signed, one-time use. QR data: JSON with `leave_id`, `employee_id`, `type`, `timestamp`, `signature`.

### State & API
- Web: Zustand stores → Axios (`@/lib/api`, cookie-based JWT)
- Flutter: ChangeNotifier + Provider → singleton Dio ApiService (`FlutterSecureStorage` for JWT)
- API: Express routes at `/api/*`, Joi validation, JWT auth middleware

### Backend Entry Points
- **`src/app.js`** — Main entry (used by package.json). Loads env, sets up Express with CORS, rate limiting, Firebase init, serves `web/dist` in production, SPA fallback.
- **`src/index.js`** — Refactored/alternate version (WIP, not used by package.json).

### Web Routes
| Path | Guard | Component |
|---|---|---|
| `/login` | public | LoginPage |
| `/employee/**` | any | EmployeeDashboard, RequestLeavePage, LeaveHistoryPage, QrDisplayPage, MyProfilePage |
| `/supervisor/**` | is_supervisor or is_admin | SupervisorDashboard, PendingRequestsPage |
| `/admin/employees` | is_admin | **UserManagerPage** (not EmployeesPage) |
| `/admin/departments` | is_admin | DepartmentsPage |
| `/admin/reports` | is_admin | ReportsPage |
| `/security/**` | authenticated (SecurityShell) | ScannerPage, ScanResultPage, ScanHistoryPage |
| `*` | — | Redirect to `/employee` |

### Flutter Navigation
- `main.dart` routes by role: `isScanner` → ScannerScreen, `isAdmin` → AdminPanel, `isSupervisor` → SupervisorDashboard, else → EmployeeDashboard
- No named routes; uses `Navigator.push` for all subscreens

### Database
- Migrations in `database/migrations/` (8 files: departments, employees, sessions, leave_requests, qr_scan_logs, functions, add_is_security, optional_department)
- Seeds in `database/seeds/` (departments + employees with password `pass1234`)
- Auth: `employees` table with `password_hash`, `sessions` table with JWT session tracking

### Test Users (all passwords: `pass1234`)
| ID | Name | Role |
|---|---|---|
| 000001 | Alice Chen | Employee (Engineering) |
| 000004 | David Kim | Supervisor (Engineering) |
| 090901 | Guard Mike | Security (no department) |
| 999999 | System Admin | Admin + Supervisor + Security |

## Code Conventions

### General
- **No comments** unless explaining a non-obvious decision
- One primary export per file
- Use existing patterns when adding new features

### Web (TypeScript + React)
- Functional components with hooks
- Zustand stores with `create` + `set`
- Axios from `@/lib/api` (cookie-based auth)
- shadcn/ui from `@/components/ui/`
- Tailwind utility classes + `cn()` from `@/lib/utils`
- Imports via `@/` path alias
- Forms: controlled `useState` + native `<form>` + `onSubmit`
- Error toast: `toast.error()` from sonner
- Routing: React Router v7 with `<BrowserRouter>` + `<Routes>` + `<Route>`
- Theme: Tailwind v4 CSS-driven (`@theme` directive in `index.css`), no `tailwind.config.*`

### Flutter (Dart)
- State: `ChangeNotifier` + `Provider` (MultiProvider in `main.dart` with 4 providers)
- API: Singleton `ApiService` (Dio) with auth interceptor
- Theme: `QuickpassTheme` with `QuickpassColors` from `config/theme.dart`
- Forms: `Form` + `GlobalKey<FormState>` + `TextFormField` + validators
- Screens: StatefulWidget with `Scaffold`, `QuickpassAppBar`, `RefreshIndicator`

### Backend (Node.js + Express)
- Controllers in `controllers/`
- Routes defined in `routes/index.js` with Joi validation
- Auth middleware: `authenticate`, `requireSupervisor`, `requireAdmin` in `middleware/auth.js`
- Database: Knex in `config/database.js`
- Errors: `createError(status, message)` via `middleware/errorHandler.js`
- Always use LEFT JOIN when querying leave_requests with employee joins

## Web Color System

Tailwind v4 CSS variables in `src/index.css`. `@theme` maps them to utility classes.

### Light (`:root`)
| Token | Value |
|---|---|
| `--background` | `#fbf8ff` |
| `--foreground` | `#1a1b22` |
| `--primary` | `#1e40af` |
| `--secondary` | `#2563eb` |
| `--destructive` | `#dc2626` |
| `--border` | `#c4c5d5` |

### Dark (`.dark`)
| Token | Value |
|---|---|
| `--background` | `#0f172a` |
| `--foreground` | `#f1f0fa` |
| `--primary` | `#b8c4ff` |
| `--secondary` | `#b4c5ff` |
| `--destructive` | `#ffb4ab` |
| `--border` | `#334155` |

## Typography

- Web: Inter (Google Fonts, via `index.css`)
- Flutter: Inter (`GoogleFonts.interTextTheme()` in `config/theme.dart`)

## Design Principles

- **"The Verified Path"** — structured, high-contrast, authoritative
- **NO AI slop** — reject generic templates, every component needs a visual signature
- 8px grid, 4px micro-adjustments
- Cards: white bg, 1px border, 12px radius
- Status badges: soft-fill (10% opacity bg, 100% text)
- Depth via tonal layers, not shadows
