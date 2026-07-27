---
tags:
  - quickpass
  - web
  - frontend
---
# Web Frontend Architecture

## Entry — `src/main.tsx`
Renders `<App />` inside `React.StrictMode`, wrapped by `<ThemeProvider>` (applies the persisted theme before first paint to avoid a flash). Calls `applyTheme()` synchronously before render.

## Routes (React Router v7, defined in `App.tsx`)

### Public
| Path | Component |
|---|---|
| `/login` | LoginPage |

### AppLayout (authenticated shell with sidebar)
| Path | Component | Guard |
|---|---|---|
| `/employee` | EmployeeDashboard | any auth |
| `/employee/request` | RequestLeavePage | any auth |
| `/employee/history` | LeaveHistoryPage | any auth |
| `/employee/qr/:id` | QrDisplayPage | any auth |
| `/employee/profile` | MyProfilePage | any auth |
| `/supervisor` | SupervisorDashboard | supervisor/admin |
| `/supervisor/pending` | PendingRequestsPage | supervisor/admin |
| `/admin/employees` | UserManagerPage | admin |
| `/admin/departments` | DepartmentsPage | admin |
| `/admin/reports` | ReportsPage | admin |
| `/guides` | GuidesPage | any auth |

### SecurityShell (no sidebar)
| Path | Component |
|---|---|
| `/security/scan` | ScannerPage |
| `/security/result` | ScanResultPage |
| `/security/history` | ScanHistoryPage |

### Catch-all: `*` → redirect to `/employee`

## Auth Pattern
- **Access token**: in-memory (module-level variable in `lib/api.ts`)
- **Refresh token**: HTTP-only cookie (sent via `withCredentials: true`)
- **Login**: POST `/auth/login` → store token in memory
- **401 interceptor**: auto-refresh via POST `/auth/refresh`, retry original request
- **Session restore**: `loadUser()` calls `/auth/refresh` then `/auth/profile`
- **No localStorage for tokens** — only in-memory

## Zustand Stores

### authStore
- `user`, `isAuthenticated`, `isLoading`, `error`
- Methods: `login`, `logout`, `loadUser`, `updateProfile`, `updateProfilePhoto`

### leaveStore
- `history`, `activeLeave`, `pendingRequests`, `approvedLeaves`, `isLoading`, `error`
- Methods: `loadHistory`, `loadActiveLeave`, `submitLeave`, `loadPendingRequests`, `approveLeave`, `rejectLeave`, `loadApprovedLeaves`, `revokeApproval`

### scanStore
- `lastResult`, `isLoading`, `error`, `history`, `historyLoading`
- Methods: `validateScan`, `loadHistory`, `clearResult`

### themeStore
- `theme`: `"light" | "dark" | "system"` (default `"system"`)
- `setTheme(theme)`, `resolved()` → actual `"light" | "dark"`
- Persisted via zustand `persist` to a **per-user** localStorage key: `quickpass-theme-<employee_id>` when logged in, else `quickpass-theme` (falls back to reading the global key).
- `applyTheme()` toggles `dark` class on `<html>`.
- `rehydrateTheme()` re-reads the store from the active user's key (called by authStore on login/logout/loadUser).
- `ThemeProvider` (`components/ThemeProvider.tsx`) mounts the store and listens for system scheme changes.

## API Client (`lib/api.ts`)
- Axios instance with `baseURL: "/api"`, `withCredentials: true`
- Request interceptor: attach Bearer token
- Response interceptor: 401 auto-refresh with retry queue
- Auth failure callback registered by authStore

## UI Components

### Layout
- **AppLayout**: StatusBar + Sidebar (or MobileBottomBar on small screens) + Outlet
- **SecurityShell**: Standalone auth-gated shell for scanner routes
- **Sidebar**: Desktop nav with collapsible sections filtered by role
- **MobileBottomBar**: Fixed bottom nav with up to 5 items + "More" overflow
- **RequireRole**: Route guard component

### shadcn/ui Pattern Components
Badge, Button (with `asChild`), Card, Dialog, Input, Label, Select, Table, Textarea — all from `@radix-ui/*` primitives

### Shared
- **StatusBadge**: Colored pill for leave status
- **QrDisplay**: QR code with countdown timer (qr-code-styling)
- **DashboardSkeleton**: Loading placeholder
- **PhotoCropper**: Profile photo crop modal (react-easy-crop)

## Styling — Tailwind CSS v4
- **CSS-driven** (no `tailwind.config.*` file)
- `@theme inline` in `index.css` maps CSS vars to Tailwind color tokens
- Warm amber/stone theme, shared hue family across light & dark (only luminance inverts)
- Light tokens: `--primary: #b45309`, `--background: #fffbeb`, `--card: #ffffff`, `--success: #0d9488`
- Dark tokens (`.dark` block): `--primary: #fbbf24`, `--background: #1c1917`, `--card: #292524`, `--success: #34d399`
- Fonts: Inter (body) + Playfair Display (headings)
- 30+ utility classes via `@apply` (panel-card, input-stitch, btn-primary, etc.)
- Vite: dev server on port 8080, proxies `/api` → `localhost:3000`

## Dark Mode
- Driven by a `.dark` class on `<html>` (Tailwind v4 variant), not a media query.
- Toggle UI: `ThemeToggle` (`components/layout/ThemeToggle.tsx`) — a Light/System/Dark segmented control, mounted in `AppLayout` StatusBar, `SecurityHeader`, and `LoginPage`.
- Do NOT add `prefers-color-scheme` media queries; the store already handles system preference.
- Theme choice persists per-user in localStorage (see `themeStore`).

## Key Dependencies
| Package | Purpose |
|---|---|
| react ^19.0.0 | UI framework |
| react-router ^7.1.1 | Routing |
| zustand ^5.0.2 | State management |
| axios ^1.7.9 | HTTP client |
| lucide-react ^0.468.0 | Icons |
| sonner ^1.7.1 | Toast notifications |
| recharts ^3.9.2 | Charts (admin reports) |
| qr-code-styling ^1.9.2 | QR rendering |
| jsqr ^1.4.0 | QR decoding |
| date-fns ^4.1.0 | Date formatting |
| react-easy-crop ^6.1.0 | Photo cropping |
| class-variance-authority ^0.7.1 | Component variants |
