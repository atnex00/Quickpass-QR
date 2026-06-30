# Quickpass — Project Guide for AI Agents

## Overview

QR-based gate pass and leave management system. Three components:

- **web/** — React 19 + TypeScript + Vite + Tailwind v4 (shadcn/ui patterns)
- **flutter_app/** — Flutter 3.x + Provider + Dio
- **backend/** — Node.js + Express + PostgreSQL (Knex) + JWT

## Commands

### Web (`web/`)
| Command | Purpose |
|---|---|
| `npm run dev` | Start dev server (Vite) |
| `npm run build` | Type-check + production build |
| `npm run lint` | ESLint check |

### Backend (`backend/`)
| Command | Purpose |
|---|---|
| `npm run dev` | Start with nodemon (auto-restart) |
| `npm start` | Start in production |
| `npm test` | Run Jest tests |
| `npm run migrate` | Run Knex migrations |
| `npm run migrate:rollback` | Rollback last migration |
| `npm run seed` | Run database seeds |

### Flutter (`flutter_app/`)
| Command | Purpose |
|---|---|
| `./scripts/setup.sh` | Install Android SDK + Flutter in `tools/` (Linux/macOS) |
| `./scripts/setup.ps1` | Install Android SDK + Flutter in `tools/` (Windows) |
| `flutter run` | Run on connected device |
| `flutter build apk` | Build Android APK |
| `flutter build ios` | Build iOS |
| `flutter analyze` | Static analysis |

## Architecture

### Roles
- `is_admin` — Full access, user management, departments, reports
- `is_supervisor` — Approve/reject leave requests for their department
- `is_security` — Scan QR codes at gates, view scan history
- Regular employee — Submit leaves, view history

### Routes (Security / Standalone Scanner)
| Path | Role | Component |
|---|---|---|
| `/security/scan` | is_security | ScannerPage (full-screen kiosk) |
| `/security/result` | is_security | ScanResultPage |
| `/security/history` | is_security | ScanHistoryPage |

### Routes (Web)
| Path | Role | Component |
|---|---|---|
| `/login` | public | LoginPage |
| `/employee` | any | EmployeeDashboard |
| `/employee/request` | any | RequestLeavePage |
| `/employee/history` | any | LeaveHistoryPage |
| `/employee/qr/:id` | any | QrDisplayPage |
| `/employee/profile` | any | MyProfilePage |
| `/supervisor` | supervisor/admin | SupervisorDashboard |
| `/supervisor/pending` | supervisor | PendingRequestsPage |
| `/admin/employees` | admin | EmployeesPage |
| `/admin/departments` | admin | DepartmentsPage |
| `/admin/reports` | admin | ReportsPage |

### Flutter Navigation
- `main.dart` routes by role: `isAdmin` → AdminPanel, `isSupervisor` → SupervisorDashboard, else → EmployeeDashboard
- No named routes; uses `Navigator.push` for subscreens

### Data Flow
- Zustand stores (web) / ChangeNotifier providers (Flutter) → API service layer → Express backend → PostgreSQL
- Auth via JWT stored in cookie (web) or FlutterSecureStorage (Flutter)

## Code Conventions

### General
- **No comments in code** unless explaining a non-obvious decision
- Use existing patterns when adding new features
- Keep files focused — one primary export per file

### Web (TypeScript + React)
- Functional components with hooks (no class components)
- Store: Zustand with `create` + `set` pattern
- API: Axios instance from `@/lib/api` (cookie-based auth)
- UI: shadcn/ui components from `@/components/ui/`
- Styling: Tailwind utility classes, `cn()` from `@/lib/utils`
- Imports: Use `@/` path alias (e.g., `@/stores/leaveStore`)
- Forms: Controlled `useState` + native `<form>` + `onSubmit`
- Error handling: `toast.error()` from sonner for user feedback
- Empty states: Center icon + message + actionable CTA

### Flutter (Dart)
- State: `ChangeNotifier` + `Provider` pattern
- API: Singleton `ApiService` (Dio)
- Theme: `QuickpassTheme` with `QuickpassColors` from `config/theme.dart`
- Widgets: Shared widgets in `widgets/` directory
- Forms: `Form` + `GlobalKey<FormState>` + `TextFormField` + validators
- Screens: StatefulWidget with `Scaffold`, `QuickpassAppBar`, `RefreshIndicator`

### Backend (Node.js + Express)
- Controllers: Request handlers in `controllers/`
- Routes: Defined in `routes/index.js` with Joi validation
- Middleware: Auth (`authenticate`, `requireSupervisor`) in `middleware/auth.js`
- Database: Knex query builder with migrations in `database/migrations/`
- Errors: `createError(status, message)` via `middleware/errorHandler.js`
- Always use LEFT JOIN when querying leave_requests with employee joins

## Color System (Web — Current)
| Token | Light | Dark |
|---|---|---|
| `--primary` | `#1e40af` | `#b8c4ff` |
| `--secondary` | `#2563eb` | `#b4c5ff` |
| `--destructive` | `#dc2626` | `#ffb4ab` |
| `--background` | `#fbf8ff` | `#0f172a` |
| `--foreground` | `#1a1b22` | `#f1f0fa` |
| `--border` | `#c4c5d5` | `#334155` |

## Color System (Flutter)
| Token | Hex |
|---|---|
| `primary` | `0xFF1E40AF` |
| `secondary` | `0xFF2563EB` |
| `accent` | `0xFFF59E0B` |
| `success` | `0xFF10B981` |
| `error` | `0xFFDC2626` |
| `error` | `0xFFFF6161` |

## Typography
- **Web**: Inter (single face, via Google Fonts)
- **Flutter**: Inter (`GoogleFonts.interTextTheme()`)
- **Scale**: text-xs(12) → text-sm(14) → text-base(16) → text-lg(18) → text-2xl(24)
- **Headings**: Semi-Bold (600), tight letter-spacing for large
- **Body**: Regular (400)
- **Labels**: Uppercase, 0.05em letter-spacing (12px, weight 600)
- **Timer/duration**: monospace weight 700

## Design Principles

### NO AI Slop

Every UI decision must be intentional and distinctive. Reject anything that reads like a generic template.

**Not allowed:**
- Default shadcn component styling without customization
- Generic gradients (dark blue to light blue, white to grey)
- Boring empty states with just "No data" text
- Tailwind defaults without custom spacing/tokens
- Same radius, same shadow as every other dashboard
- Layout that doesn't earn its structure

**Required instead:**
- Every component should have a deliberate visual signature
- Empty states should invite action with personality
- Layout should feel purpose-built for THIS app, not any CRUD app
- Typography, spacing, and color should feel chosen, not defaulted
- If it could be mistaken for a Bootstrap demo, it's wrong

The signature element is "The Verified Path" — structured, high-contrast, authoritative. Every screen should feel like a command center, not a form filler.

### Design System
1. "The Verified Path" — structured grid, high-contrast, no ambiguity
2. 8px grid system (4px micro-adjustments)
3. Professional-Soft shape language (4px radius standard, 999px for pills)
4. Cards: white bg, 1px border, header with bottom divider
5. Tables: no vertical borders, horizontal borders only, hover zebra striping
6. Buttons: primary=Deep Blue bg, secondary=White+Deep Blue border
7. Status badges: soft-fill style (10% opacity bg, 100% text)
8. Depth via tonal layers (not shadows)

## QR Code
- Valid ±15 minutes from scheduled time (start_time for OUT, end_time for IN)
- Embedded Quickpass logo in center
- 3 states: "Opens in" (before window) → "Expires in" (during window) → "Expired" (after)
- QR data: JSON with `leave_id`, `employee_id`, `type`, `timestamp`, `signature` (HMAC-SHA256)

## Design Principles (from frontend-design skill)
1. Empty states are invitations to act — explain what to do next
2. Errors don't apologize — state what happened and how to fix it
3. Writing is design material — use active voice, sentence case, plain verbs
4. Add motion deliberately — hover micro-interactions, page transitions
5. One signature element per page — keep the rest clean
6. Use consistent spacing and alignment
