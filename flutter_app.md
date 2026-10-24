---
tags:
  - quickpass
  - flutter
  - mobile
---
# Flutter App Architecture

## Entry Point — `main.dart`

1. Init `ApiService` singleton (Dio with interceptors)
2. Lock portrait orientation
3. Load `SettingsProvider` (ThemeMode from SharedPreferences)
4. Create `AuthProvider` (with ApiService)
5. `QuickpassApp` with `MultiProvider`

**Provider setup**: `ApiService` as `Provider<ApiService>.value`, then `MultiProvider` with:
- `AuthProvider`, `LeaveProvider`, `SupervisorProvider`, `ScanProvider`, `SettingsProvider`

**Home routing** (no named routes — all `Navigator.push`):
| Condition | Screen |
|---|---|
| `auth.isLoading` | SplashScreen |
| `!auth.isAuthenticated` | LoginScreen |
| `auth.isAdmin` | AdminPanel |
| `auth.isSupervisor` | SupervisorDashboard |
| `auth.isScanner` | ScannerScreen |
| else | EmployeeDashboard |

Force logout/logged in callbacks use `_navigatorKey` (GlobalKey) with `pushAndRemoveUntil`.

## Providers (ChangeNotifier)

### AuthProvider
- State: `user`, `isLoading`, `loginLoading`, `isAuthenticated`, `error`
- Computed: `isSupervisor`, `isAdmin`, `isSecurity`, `isScanner`
- Methods: `login`, `logout`, `initialize`, `updateProfile`, `uploadProfilePhoto`

### LeaveProvider
- State: `history`, `activeLeave`, `isLoading`, `error`, `pendingCount`, `approvedCount`, `completedCount`
- Methods: `loadHistory`, `loadActiveLeave`, `submitLeave`, `deleteLeave`, `refresh`

### SupervisorProvider
- State: `pendingRequests`, `approvedLeaves`, `teamLeaves`, `isLoading`, `error`, `pendingCount`
- Methods: `loadPendingRequests`, `loadApprovedLeaves`, `loadTeamLeaves`, `approveLeave`, `rejectLeave`, `revokeApproval`

### ScanProvider
- State: `lastResult`, `isScanning`, `isLoading`, `error`
- Methods: `validateScan`, `setScanning`, `clearResult`

### SettingsProvider
- State: `_themeMode` (persisted to SharedPreferences)
- Methods: `load`, `setDarkMode`

## API Service — `ApiService` (singleton, Dio)
- `baseUrl` from `--dart-define=API_BASE_URL` (default `http://10.0.2.2:3000/api`)
- Auth token in FlutterSecureStorage (key `auth_token`), attached via request interceptor
- 401 interceptor: auto-refresh via `/auth/refresh`, queue pending requests, retry
- After 3 failed retries: `onForceLogout` callback
- On `force_logout` in response body: clear auth

## Navigation
- **No named routes** — all imperative `Navigator.push` / `pushReplacement` / `pushAndRemoveUntil`
- **Tab navigation**: `IndexedStack` + `NavigationBar` (employee 3 tabs, supervisor 3 tabs, admin 5 tabs)
- **Team Calendar**: Push-navigated from supervisor overview quick action card
- **AdminPanel**: `AdaptiveScaffold` (NavigationRail tablet, NavigationBar phone)
- **Security**: popup menu, no bottom nav

## Theme — `QuickpassTheme`
- `useMaterial3: true`
- Inter font via `GoogleFonts.interTextTheme()`
- Light primary: `#1E40AF` (blue), Dark primary: `#FFD700` (gold)
- Cards: 12px radius, 1px outlineVariant border, no shadow
- FAB/buttons: gold fill, 8-12px radius
- Navigation bar: gold indicator, 15% alpha, 80px height
- Chips: pill shape (999 radius)
- Status colors: success `#16A34A`, error `#DC2626`, warning `#F59E0B`

## Screens (20 total)
| Category | Screens |
|---|---|
| Auth (2) | SplashScreen, LoginScreen |
| Employee (5) | DashboardScreen, RequestLeaveScreen, LeaveHistoryScreen, QrDisplayScreen, ProfileScreen |
| Supervisor (3) | SupervisorDashboard, PendingRequestsScreen, TeamCalendarScreen |
| Security (3) | ScannerScreen, ScanResultScreen, ScanHistoryScreen |
| Admin (8) | AdminPanel, OverviewTab, EmployeeTab, DepartmentTab, ReportsTab, LeaveTab, EmployeeDetailScreen, admin_shared helpers |
| Shared (1) | SettingsScreen |

## Models (json_serializable)
- **Employee**: employee_id, full_name, position, department, email, roles, profile_photo, hire_date
- **LeaveRequest**: leave_id, employee, supervisor, leave_date, start/end time, reason, status, QR codes, scan times, rejection_reason
- **ScanLog**: log_id, leave_id, qr_type, scanned_by, scan_time, is_valid, message, department_name, department_code, scanned_by_name
- **ScanDepartment**: department_name, department_code, scan_count
- **Department**: department_id, name, code, head, is_active

## Storage
| Store | Usage |
|---|---|
| FlutterSecureStorage | Auth tokens (`auth_token`, `refresh_sid`, `employee_id`, `user_data`) |
| SharedPreferences | Theme mode (`theme_mode`) |

## Key Dependencies
| Package | Purpose |
|---|---|
| provider ^6.1.2 | State management |
| dio ^5.4.3 | HTTP client with interceptors |
| qr_flutter ^4.1.0 | QR code rendering |
| mobile_scanner ^6.0.11 | Camera QR scanning |
| flutter_secure_storage ^9.2.2 | Secure token storage |
| google_fonts ^8.1.0 | Inter font |
| fl_chart ^0.68.0 | Charts (admin reports) |
| json_annotation ^4.9.0 | Model serialization |
| image_picker ^1.1.2 | Photo selection |
| image_cropper ^8.0.2 | Photo cropping |
| permission_handler ^11.3.1 | Camera permissions |
| table_calendar ^3.1.2 | Month calendar widget (team calendar view) |
