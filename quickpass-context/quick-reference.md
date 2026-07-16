---
tags:
  - quickpass
  - reference
  - cheat-sheet
---
# Quick Reference

## Ports
| Service | Port |
|---|---|
| Backend (HTTP) | 3000 |
| Backend (HTTPS) | 3443 |
| Web dev server (Vite) | 8080 |

## Dev Commands

### Root
| Command | Purpose |
|---|---|
| `npm run dev` | Backend + web concurrently (`dev.sh`) |
| `npm run migrate` | Knex migrate:latest |
| `npm run seed` | Knex seed:run |

### Backend
| Command | Purpose |
|---|---|
| `npm run dev` | nodemon on `src/app.js` |
| `npm test` | Jest (--coverage --forceExit) |
| `npm run lint` | ESLint on `src/` |

### Web
| Command | Purpose |
|---|---|
| `npm run dev` | Vite on port 8080 |
| `npm run build` | `tsc -b && vite build` |

### Flutter
| Command | Purpose |
|---|---|
| `flutter run` | Run on connected device |
| `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api` | Emulator |
| `flutter analyze` | Static analysis |
| `flutter build apk` | APK build |

## Test Users (all password: `pass1234`)
| ID | Name | Role |
|---|---|---|
| 000001 | Alice Chen | Employee (Engineering) |
| 000002 | Bob Smith | Employee (Marketing) |
| 000003 | Carol White | Employee (HR) |
| 000004 | David Kim | Supervisor (Engineering Manager) |
| 000005 | Emma Brown | Supervisor (Marketing Director) |
| 000006 | Frank Green | Supervisor (HR Manager) |
| 000007 | Grace Lee | Employee (Engineering) |
| 000008 | Henry Wilson | Supervisor (Product Manager) |
| 000009 | Michael Park | Employee (Engineering) |
| 000010 | Sarah Johnson | Supervisor (Tech Lead) |
| 090901 | Guard Mike | Security |
| 999999 | System Admin | Admin + Supervisor + Security |

## API Base URLs
| Env | URL |
|---|---|
| Dev (local) | `http://localhost:3000/api` |
| Android emulator | `http://10.0.2.2:3000/api` |
| Physical device (ADB reverse) | `http://localhost:3000/api` |
| Web dev (proxy) | `/api` → `localhost:3000` |

## Flutter Routing
| Role | Home Screen |
|---|---|
| Employee | EmployeeDashboard |
| Supervisor | SupervisorDashboard |
| Admin | AdminPanel |
| Security | ScannerScreen |

## Web Routing
| Path | Page |
|---|---|
| `/login` | LoginPage |
| `/employee` | EmployeeDashboard |
| `/employee/request` | RequestLeavePage |
| `/employee/history` | LeaveHistoryPage |
| `/employee/qr/:id` | QrDisplayPage |
| `/employee/profile` | MyProfilePage |
| `/supervisor` | SupervisorDashboard |
| `/supervisor/pending` | PendingRequestsPage |
| `/admin/employees` | UserManagerPage |
| `/admin/departments` | DepartmentsPage |
| `/admin/reports` | ReportsPage |
| `/security/scan` | ScannerPage |
| `/security/result` | ScanResultPage |
| `/security/history` | ScanHistoryPage |

## Database Connection
- Dev: `postgresql://postgres:1234@localhost:5432/zaneco_quickpass`
- Prod: Supabase cloud (via `DB_CONNECTION` env var)

## QR Code Validity
- Window: ±15 minutes from scheduled leave time
- Algorithm: HMAC-SHA256
- Payload: JSON → base64url → QR image PNG

## Key Files by Location
| File | Purpose |
|---|---|
| `backend/src/app.js` | Express bootstrap |
| `backend/src/routes/index.js` | All API route definitions |
| `backend/src/middleware/auth.js` | JWT auth + role guards |
| `backend/src/controllers/scanController.js` | QR scan validation logic |
| `backend/src/services/qrService.js` | HMAC signing + verification |
| `flutter_app/lib/services/api_service.dart` | Dio setup + token refresh |
| `flutter_app/lib/config/theme.dart` | QuickpassColors + QuickpassTheme |
| `flutter_app/lib/main.dart` | Flutter entry + provider setup |
| `web/src/App.tsx` | React Router setup |
| `web/src/index.css` | Tailwind v4 theme tokens |
| `web/src/lib/api.ts` | Axios client with 401 retry |
| `database/migrations/` | 10 migration files |
| `database/seeds/` | Seed data |
