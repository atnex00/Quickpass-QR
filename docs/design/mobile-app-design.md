# Quickpass Mobile App — UI Design Reference

> Use this document as a complete reference for redesigning the Quickpass Flutter mobile app.
> Current state: Flutter 3.44 + Material 3 + Provider

---

## 1. Product Overview

QR-based gate pass and leave management system. Three tiers:

| Role | Access |
|---|---|
| **Employee** | Submit leaves, view history, display QR passes |
| **Supervisor** | Approve/reject department leave requests |
| **Security** | Scan QR codes at gates, view scan history |
| **Admin** | Full access, manage users/departments, view reports |

---

## 2. Navigation Architecture

### 2.1 Auth Flow

```
App Launch → SplashScreen (1s delay, init auth)
           → LoginScreen (employee ID + password)
           → [Role-based home]
```

### 2.2 Role-Based Homes

**Employee** (`EmployeeDashboard`)
```
Bottom Nav (3 tabs)
├── Dashboard (home)
│   ├── Active Leave Card (if any)
│   ├── Stat Cards: Pending / Approved / Completed
│   ├── "Request Leave" button
│   └── Recent Requests list
├── Leave History
│   └── Filterable list (All / Pending / Approved / etc.)
└── Profile
    └── View/Edit personal info
```

**Supervisor** (`SupervisorDashboard`)
```
Bottom Nav (2 tabs)
├── Overview
│   ├── Pending Requests Hero Card (with count)
│   ├── Quick Actions (Review Pending, Team Calendar)
│   └── Approved Leaves list (with revoke)
└── Pending Requests
    └── List with Approve/Reject actions
```

**Security** (`ScannerScreen`)
```
Direct full-screen scanner (no bottom nav)
├── ScannerScreen → ScanResultScreen → ScannerScreen (loop)
└── ScanHistoryScreen (accessible from... currently not linked)
```

**Admin** (`AdminPanel`)
```
TabBar (3 tabs)
├── Employees (search + list + add FAB)
├── Departments (list + add FAB)
└── Reports (overview stats + placeholder)
```

### 2.3 Full Screen Map

```
screens/
├── auth/
│   ├── splash_screen.dart          — Initial loading screen
│   └── login_screen.dart           — Employee ID + password form
├── employee/
│   ├── dashboard_screen.dart       — Employee home (3-tab bottom nav)
│   ├── request_leave_screen.dart   — Leave request form
│   ├── leave_history_screen.dart   — Filterable leave list
│   ├── qr_display_screen.dart      — OUT/IN QR code display
│   └── profile_screen.dart         — View/edit profile
├── supervisor/
│   ├── supervisor_dashboard.dart   — Supervisor home (2-tab bottom nav)
│   └── pending_requests_screen.dart — Approve/reject list
├── security/
│   ├── scanner_screen.dart         — Full-screen QR scanner
│   ├── scan_result_screen.dart     — Validation result
│   └── scan_history_screen.dart    — Past scan logs
└── admin/
    └── admin_panel.dart            — 3-tab admin panel
```

---

## 3. Screen-by-Screen Breakdown

### 3.1 SplashScreen

| Aspect | Detail |
|---|---|
| **Purpose** | Auth initialization with 1s delay |
| **Layout** | Full-screen gradient (primary → primary 80%), centered content |
| **Elements** | QR icon in white rounded square + shadow, "Quickpass" title, subtitle, CircularProgressIndicator |
| **States** | — |
| **Pain points** | Generic splash, no branding personality |

### 3.2 LoginScreen

| Aspect | Detail |
|---|---|
| **Purpose** | Employee authentication |
| **Layout** | Centered scroll view, form with 2 fields |
| **Elements** | QR icon header, heading + subtitle, Employee ID (6-digit numeric) field, Password field (with visibility toggle), error box, "Sign In" button with loading spinner |
| **States** | Loading (button shows spinner), Error (red box above button) |
| **Pain points** | Boring layout, no visual distinction, error state could be more polished |

### 3.3 Employee Dashboard

| Aspect | Detail |
|---|---|
| **Purpose** | Employee home — overview + quick actions |
| **Layout** | IndexedStack bottom nav (3 tabs), scrollable dashboard |
| **Elements** | User card (avatar circle + name + position + ID), Active Leave card (if any → "View QR"), 3 stat cards (Pending/Approved/Completed counts), "Request Leave" FAB-style button, Recent Requests list (max 5) |
| **Empty state** | "No recent requests" placeholder |
| **Pain points** | Cluttered, stat cards feel generic, active leave card could be more prominent |

### 3.4 RequestLeaveScreen

| Aspect | Detail |
|---|---|
| **Purpose** | Submit a leave request |
| **Layout** | Scroll form with card sections |
| **Elements** | QuickpassAppBar "Request Leave" + back, Employee info card (read-only), Date picker card (tappable), Time picker cards (start/end side-by-side), Duration display, Reason text field (3 lines, min 5 chars), Submit button |
| **States** | Validation errors via SnackBar, submitting spinner |
| **Pain points** | Generic form layout, date/time pickers use native dialogs (feel un-integrated) |

### 3.5 LeaveHistoryScreen

| Aspect | Detail |
|---|---|
| **Purpose** | Full leave history |
| **Layout** | AppBar + filter popup + RefreshIndicator + ListView |
| **Elements** | Filter button (colored dots for statuses), leave cards (date + status badge + time + duration + reason), tappable if has QR codes |
| **Empty state** | Icon + "No leave requests found" |
| **Loading state** | LoadingIndicator |
| **Pain points** | Filter is a popup menu (not visible), list items could be more structured |

### 3.6 QrDisplayScreen

| Aspect | Detail |
|---|---|
| **Purpose** | Show OUT/IN QR codes for active leave |
| **Layout** | Scroll with card sections |
| **Elements** | Leave details card (date/time/duration/reason), OUT QR code widget (blue theme), IN QR code widget (green theme), validity footer text |
| **Fallback state** | "QR codes are not available yet" placeholder |
| **Pain points** | Two separate QR cards stacked vertically — could be scroll-heavy on small screens |

### 3.7 ProfileScreen

| Aspect | Detail |
|---|---|
| **Purpose** | View and edit personal info |
| **Layout** | Card sections |
| **Elements** | Header card (avatar + name + position), Account info (read-only: ID, department), Personal info (editable: name, position, email, password), "Save Changes" button |
| **States** | Loading spinner on save |
| **Pain points** | Very basic CRUD form, no visual hierarchy |

### 3.8 SupervisorDashboard

| Aspect | Detail |
|---|---|
| **Purpose** | Supervisor home |
| **Layout** | 2-tab bottom nav |
| **Elements** | User card, Pending Requests hero card (large number + count + arrow), Quick Actions row (2 cards), Approved Leaves list (with undo revoke) |
| **Empty state** | "All caught up!" for pending |
| **Pain points** | "Team Calendar" action is a dead end, no visual distinction from employee dashboard |

### 3.9 PendingRequestsScreen

| Aspect | Detail |
|---|---|
| **Purpose** | Review and act on pending leaves |
| **Layout** | AppBar with count + RefreshIndicator + ListView |
| **Elements** | Employee avatar + name + position, status badge, date/time, reason, "Reject" + "Approve" buttons |
| **Empty state** | Checkmark + "No pending requests" |
| **States** | Confirmation dialogs for approve/reject |
| **Pain points** | List is dense, approval/reject flow uses dialogs (feels heavy) |

### 3.10 ScannerScreen

| Aspect | Detail |
|---|---|
| **Purpose** | Full-screen QR scanner kiosk |
| **Layout** | MobileScanner full background + gradient overlays |
| **Elements** | Top bar (back arrow + title + flashlight toggle), 250x250 scanning frame overlay, bottom instructions text |
| **States** | Camera active, scanning, torch on/off |
| **Pain points** | No recent scans access from scanner, no visual feedback during processing pause |

### 3.11 ScanResultScreen

| Aspect | Detail |
|---|---|
| **Purpose** | Show QR validation result |
| **Layout** | Full-screen result display |
| **Elements** | Success: green check + heading + badge + employee card + "Scan Next" button — Error: red X + heading + error message + "Try Again" button |
| **States** | Loading (initial validation), Success, Error |
| **Pain points** | Transition back to scanner uses pushReplacement (no back stack), result screen feels disconnected |

### 3.12 ScanHistoryScreen

| Aspect | Detail |
|---|---|
| **Purpose** | View past scans |
| **Layout** | AppBar + RefreshIndicator + ListView |
| **Elements** | Status icon (check/cancel), employee name, type + timestamp, validation message, valid/invalid badge |
| **Empty state** | QR icon + "No scan history" |
| **Error state** | Error icon + message + "Retry" |
| **Pain points** | Not linked from scanner screen, no search/filter |

### 3.13 AdminPanel

| Aspect | Detail |
|---|---|
| **Purpose** | Full admin management |
| **Layout** | 3-tab TabBar |
| **Elements** | Employee tab: search + list + add FAB + role badges — Department tab: list + add FAB — Reports tab: stat grid + placeholder |
| **States** | Add dialogs for employees/departments, loading |
| **Pain points** | Reports tab has placeholder content, data-heavy with poor information hierarchy |

---

## 4. Current Design System

### 4.1 Color Palette

**Light Mode:**

| Token | Hex |
|---|---|
| Primary | `#1E40AF` |
| Secondary | `#2563EB` |
| Tertiary | `#F59E0B` |
| Error | `#DC2626` |
| Background | `#FBF8FF` |
| Surface | `#FFFFFF` |
| On Primary | `#FFFFFF` |
| QR Out | `#2563EB` |
| QR In | `#16A34A` |

**Dark Mode:**

| Token | Hex |
|---|---|
| Primary | `#B8C4FF` |
| Secondary | `#B4C5FF` |
| Tertiary | `#FDD68C` |
| Error | `#FFB4AB` |
| Background | `#0F172A` |
| Surface | `#1A1B2E` |

### 4.2 Typography

| Token | Weight | Size |
|---|---|---|
| AppBar title | w600 | 18 |
| Button text | w600 | 15 |
| Body | w400 | 14 (default) |
| Labels | w600 | 12 |
| Large headings | w600 | 20-24 |
| Timer/duration | w700 | monospace |

Typeface: Inter (via Google Fonts)

### 4.3 Spacing & Layout

- Grid: 8px base (4px micro-adjustments)
- Card margin: 16px horizontal, 6px vertical
- Card padding: 16px
- Border radius: 12px (cards), 10px (buttons), 999px (pills/chips)
- Standard button: 24px vertical, 14px horizontal padding

### 4.4 Component Shapes

| Component | Radius |
|---|---|
| Cards | 12px |
| Buttons (filled/outlined) | 10px |
| Input fields | 10px |
| Dialogs | 16px |
| Chips/Pills | 999px |
| FAB | 16px |

### 4.5 Navigation Component

| Component | Style |
|---|---|
| Bottom Nav (employee) | 3 items: Dashboard, History, Profile |
| Bottom Nav (supervisor) | 2 items: Overview, Requests |
| TabBar (admin) | 3 tabs: Employees, Departments, Reports |
| AppBar | Primary bg, centered title, no elevation |

### 4.6 Shared Widgets Inventory

| Widget | File | Usage |
|---|---|---|
| QuickpassAppBar | `custom_app_bar.dart` | Most screens |
| StatusBadge | `status_badge.dart` | Leave status pills (6 types) |
| QrCodeWidget | `qr_code_widget.dart` | QR display with timer |
| LoadingIndicator | `loading_indicator.dart` | Loading state |
| ShimmerLoading | `loading_indicator.dart` | Skeleton placeholders |
| EmptyState | `custom_widgets.dart` | Empty/no-data states |
| LoadingOverlay | `custom_widgets.dart` | Full-screen loading overlay |

---

## 5. User Flows

### 5.1 Employee Flow

```
Login → Dashboard
       ├── Request Leave → Date/Time/Reason → Submit → Back to Dashboard
       ├── View History → Filter → Tap to view QR
       ├── Active Leave → View QR → OUT QR (blue) / IN QR (green)
       └── Profile → Edit info → Save
```

### 5.2 Supervisor Flow

```
Login → Supervisor Dashboard
       ├── Overview → View pending count → Navigate to Requests
       ├── Pending Requests → Approve (dialog) / Reject (reason dialog)
       └── Approved Leaves → Revoke (confirmation dialog)
```

### 5.3 Security Flow

```
Login → ScannerScreen (full-screen)
       ├── Scan QR → Validate → Show Result → Scan Next
       └── (No navigation to history from scanner)
```

### 5.4 Admin Flow

```
Login → AdminPanel
       ├── Employees tab → Search → Add / View
       ├── Departments tab → Add / View
       └── Reports tab → View stats (placeholder)
```

---

## 6. Current Pain Points & Redesign Opportunities

### 6.1 Visual Identity
- Splash screen is generic — no brand personality
- Color palette is safe but unremarkable
- No distinctive visual signature across screens
- Dark/light mode exists but feels like auto-generated Material mappings

### 6.2 Navigation & Information Architecture
- Security scanner has no access to scan history (dead end)
- Supervisors have a "Team Calendar" action that does nothing
- Admin reports tab is a placeholder
- No deep linking or push notification handling visible in UI

### 6.3 Component Consistency
- Login form card has no border (unlike other cards)
- Some screens use `QuickpassAppBar`, others use default AppBar
- Empty states have inconsistent icon choices and messaging
- Loading states use a mix of `LoadingIndicator`, `ShimmerLoading`, and inline spinners

### 6.4 Interaction Design
- Approve/Reject uses dialogs (heavy, interrupts flow) — swipe actions would feel better
- Date/time pickers use platform-native dialogs (not themed)
- No haptic feedback except on QR scan
- No page transitions or micro-animations
- No pull-to-refresh on admin screens

### 6.5 Layout & Responsiveness
- QR display stacks two large QR cards vertically (requires scrolling)
- Admin employee list has no pagination
- No landscape support consideration

### 6.6 Accessibility
- No semantic labels visible in widget tree
- Color-only status indicators (badges rely on color, not icon + text)
- No focus management or keyboard navigation optimization

---

## 7. Design Principles to Follow

Adapted from project's "Verified Path" design system:

1. **Structured, high-contrast, authoritative** — Every screen should feel like a command center
2. **No AI slop** — Reject generic templates, every component needs a visual signature
3. **Intentional empty states** — Invite action with personality, not "No data"
4. **Errors don't apologize** — State what happened and how to fix it
5. **One signature element per page** — Keep the rest clean
6. **Deliberate motion** — Hover micro-interactions (web), page transitions, haptic feedback
7. **Consistent 8px grid** — 4px micro-adjustments when needed

---

## 8. Technical Constraints

| Constraint | Detail |
|---|---|
| Framework | Flutter 3.44+, Material 3 |
| State management | Provider (ChangeNotifier) |
| Navigation | Manual Navigator.push (no GoRouter/routing pkg) |
| Camera | mobile_scanner package |
| QR generation | qr_flutter package |
| API | Dio HTTP client |
| Auth | JWT stored in FlutterSecureStorage |
| Theming | Manual ThemeData construction (no ThemeData.copyWith) |

---

## 9. Screens Organized by Redesign Priority

| Priority | Screen | Reason |
|---|---|---|
| P0 | LoginScreen | First impression, brand-defining |
| P0 | Employee Dashboard | Most-used screen |
| P1 | ScannerScreen + ScanResultScreen | Core security workflow |
| P1 | QrDisplayScreen | QR pass is the product's main output |
| P1 | Supervisor Dashboard + PendingRequests | Key approval workflow |
| P2 | LeaveHistoryScreen, RequestLeaveScreen | Functional but generic |
| P2 | ProfileScreen | Low usage, simple CRUD |
| P3 | AdminPanel | Internal tool, lower UX bar |
| P3 | SplashScreen, ScanHistoryScreen | Edge cases |
