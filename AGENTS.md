# Quickpass — Project Guide for AI Agents

QR-based gate pass and leave management system.

- **web/** — React 19 + TypeScript + Vite 6 + Tailwind v4 (shadcn/ui patterns)
- **flutter_app/** — Flutter 3.27+ + Provider + Dio
- **backend/** — Node.js + Express + PostgreSQL (Knex) + JWT
- **database/** — Shared migration files (root level, not inside backend)

## Setup

```bash
cp backend/.env.example backend/.env
cd backend && npm install && cd ../flutter_app && flutter pub get
createdb passlynx
cd backend && npm run migrate && npm run seed
```

Two terminals:
```bash
cd backend && npm run dev
cd flutter_app && flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

Env: `NODE_ENV` selects `backend/.env.<NODE_ENV>` (defaults to `dev`). Knexfile loads the same way via dotenv.

Setup scripts (`scripts/setup.ps1` / `setup.sh`) install Flutter + Android SDK into `tools/` — no system-wide installs. `scripts/run_phone.ps1` uses ADB reverse tunnel (`localhost:3000`) for physical device testing.

No local PostgreSQL needed — `docker-compose.yml` provides only the backend service, DB is Supabase cloud.

## Commands

| Location | Command | Purpose |
|---|---|---|
| root | `npm run dev` | Backend + web concurrently (`dev.sh`) |
| root | `npm run prod` | Production mode |
| root | `npm run build:web` | `cd web && vite build` |
| root | `npm run migrate` / `seed` | Knex migrate:latest / seed:run |
| backend | `npm run dev` | nodemon on `src/app.js` |
| backend | `npm test` | Jest (`--coverage --forceExit --detectOpenHandles`) |
| backend | `npm run lint` | ESLint on `src/` |
| backend | `npm run migrate:rollback` | Knex migrate:rollback |
| web | `npm run dev` | Vite on port 8080 (proxies `/api` → `localhost:3000`) |
| web | `npm run build` | `tsc -b && vite build` |
| flutter_app | `flutter run` | Run on connected device |
| flutter_app | `flutter analyze` | Static analysis |
| flutter_app | `flutter build apk` / `appbundle` / `ios` | Production builds |

Seeds need `bcryptjs`. Run from `backend/` (resolves to `backend/node_modules/bcryptjs`). Root also has `bcryptjs` as fallback.

## Architecture

### Roles & Workflow
- `is_admin` — Full access
- `is_supervisor` — Approve/reject department leave requests
- `is_security` — Scan QR codes at gates
- Regular employee — Submit leaves, view history

1. Employee requests leave → `pending`
2. Supervisor approves → QR codes generated (OUT + IN, HMAC-SHA256 signed, one-time use, valid ±15 min from scheduled time)
3. Security scans OUT QR at exit → `active`
4. Security scans IN QR at entry → `completed`

QR data: JSON with `leave_id`, `employee_id`, `type`, `timestamp`, `signature`.

### State & API
- **Web:** Zustand stores → Axios (`@/lib/api`, cookie-based JWT)
- **Flutter:** ChangeNotifier + Provider → singleton Dio ApiService (`FlutterSecureStorage` for JWT)
- **API:** Express routes at `/api/*`, Joi validation, JWT auth middleware (`authenticate`, `requireSupervisor`, `requireAdmin`, `requireSecurity` in `middleware/auth.js`). Rate limited (100 req / 15 min).
- **Optional HTTPS server** on port 3443 for mobile camera access (reads key/cert from env paths, silently skipped if files missing).

### Backend Entry Points
- **`src/app.js`** — Main entry (used by package.json). Loads env, Express + CORS + rate limit + Firebase init, serves `web/dist` in prod, SPA fallback.
- **`src/index.js`** — Refactored/alternate version (WIP, not used by package.json).

### Web Routes (React Router v7)
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

Employee routes inside `<AppLayout />` (sidebar). Security routes inside `<SecurityShell />` (no sidebar). Admin/supervisor inside `<AppLayout />` with `<RequireRole>`.

### Flutter Navigation
- `main.dart` role routing: `isScanner` → ScannerScreen, `isAdmin` → AdminPanel, `isSupervisor` → SupervisorDashboard, else → EmployeeDashboard
- No named routes; uses `Navigator.push` for subscreens
- MultiProvider (4 providers: Auth, Leave, Supervisor, Scan)

### Flutter Admin Panel Visual Patterns
- Bottom `NavigationBar` with gold (`darkPrimary`) indicator at 15% alpha, 80px height
- `SliverAppBar` pinned, gold background, QR icon in rounded container + "Quickpass" title
- Cards: `surfaceContainerLowest` / `surface`, 12px radius, 1px `outlineVariant` border, no shadows
- Typography: Inter via `GoogleFonts.interTextTheme()`, hardcoded sizes (headings 20px w700, body 14px, labels 12px)
- Buttons: gold fill (`darkPrimary`, 8-12px radius) for primary; red for destructive
- Status badges: pill-shaped, 12% alpha bg + 30% alpha border
- Spacing: 8px grid, cards 16px padding, section gaps 24px

### Database
- Migrations in `database/migrations/` (8 files, ordered: departments → employees → sessions → leave_requests → qr_scan_logs → functions → add_is_security → optional_department)
- Seeds in `database/seeds/` (departments + employees, all passwords `pass1234`)
- `employees` table: `password_hash` auth, `sessions` table for JWT tracking
- Employee ID is auto-generated 6-digit zero-padded string via `generate_employee_id()` function

### Test Users
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
- Tailwind v4 CSS-driven (`@theme` directive in `index.css`), no `tailwind.config.*`
- Imports via `@/` path alias
- Forms: controlled `useState` + native `<form>` + `onSubmit`
- Error toast: `toast.error()` from sonner
- Icons: lucide-react

### Flutter (Dart)
- State: `ChangeNotifier` + `Provider`
- API: Singleton `ApiService` (Dio) with auth interceptor
- Theme: `QuickpassTheme` with `QuickpassColors` from `config/theme.dart`
- Forms: `Form` + `GlobalKey<FormState>` + `TextFormField` + validators
- Screens: `StatefulWidget` + `Scaffold`, `RefreshIndicator`
- `API_BASE_URL` is compile-time `--dart-define`. Default fallback: `http://182.168.0.231:3000/api` (note: likely a typo for `192.168`)

### Backend (Node.js + Express)
- Controllers in `controllers/`
- Routes in `routes/index.js` with Joi validation
- Error handling: `createError(status, message)` via `middleware/errorHandler.js`
- Always use LEFT JOIN when querying leave_requests with employee joins

## Design Language

| Token | Light | Dark |
|---|---|---|
| Primary / AppBar | `#1E40AF` / `#FFD700` | `#B8C4FF` / `#FFD700` |
| Surface | `#FFFFFF` / `#FBF8FF` | `#1E2020` / `#0F172A` |
| Success / Error / Warning | `#16A34A` / `#DC2626` / `#F59E0B` | `#6EE7B7` / `#FFB4AB` / `#FBBF24` |
| Outline variant | `#C4C5D5` | `#334155` |

- Inter font everywhere (Google Fonts)
- Cards: white bg, 1px border, 12px radius
- Status badges: soft-fill (10-12% opacity bg, 100% text), pill shape
- Depth via tonal layering, not shadows

## Misc
- No CI/CD configured (no `.github/workflows/`)
- Vite dev server on port 8080 (not the default 5173)
- `npm run dev` at root runs `dev.sh` which starts backend + web concurrently
- Web Color System defined in `web/src/index.css` via `@theme` — CSS-driven, no config file
