---
tags:
  - quickpass
  - conventions
  - style
---
# Code Conventions

## General
- **No comments** unless explaining a non-obvious decision
- One primary export per file
- Use existing patterns when adding new features

## Backend (Node.js + Express)
- Controllers in `controllers/`, routes in `routes/index.js`
- Joi validation for all request bodies and queries
- Error handling: `createError(status, message)` via `middleware/errorHandler.js`
- Always use LEFT JOIN when querying `leave_requests` with employee joins
- Transaction with `FOR UPDATE` for approve and scan flows
- No cascade deletes in DB — manual cascade in app code
- `app.js` is the only entry point (not `index.js`)

## Flutter (Dart)
- State: `ChangeNotifier` + `Provider` (not Riverpod, not Bloc)
- API: singleton `ApiService` (Dio) with auth interceptor
- No named routes — all `Navigator.push` imperative navigation
- Theme: `QuickpassTheme` with `QuickpassColors` from `config/theme.dart`
- Forms: `Form` + `GlobalKey<FormState>` + `TextFormField` + validators
- Screens: `StatefulWidget` + `Scaffold`, `RefreshIndicator`
- `API_BASE_URL` is compile-time `--dart-define`. Default fallback: `http://10.0.2.2:3000/api`
- Models use `json_annotation` + `build_runner` for serialization

## Web (TypeScript + React)
- Functional components with hooks
- Zustand stores with `create` + `set` (not React Context for global state)
- Axios from `@/lib/api` (cookie-based auth via `withCredentials`)
- In-memory JWT (not localStorage) — tokens are NEVER persisted to localStorage
- Theme preference IS persisted to localStorage (per-user key `quickpass-theme-<employee_id>`); this is allowed because it is not a token
- shadcn/ui from `@/components/ui/` (Radix primitives)
- Tailwind v4 CSS-driven (`@theme` directive in `index.css`), no `tailwind.config.*`
- Imports via `@/` path alias
- Forms: controlled `useState` + native `<form>` + `onSubmit`
- Error toast: `toast.error()` from sonner
- Icons: lucide-react

## Flutter Admin Panel Visual Patterns
- Bottom `NavigationBar` with gold (`darkPrimary`) indicator at 15% alpha, 80px height
- `SliverAppBar` pinned, gold background (light) / surface color (dark)
- Cards: `surfaceContainerLowest` / `surface`, 12px radius, 1px `outlineVariant` border, no shadows
- Typography: Inter via `GoogleFonts.interTextTheme()`
- Buttons: gold fill (`darkPrimary`, 8-12px radius) for primary; red for destructive
- Status badges: pill-shaped, 12% alpha bg + 30% alpha border
- Spacing: 8px grid, cards 16px padding, section gaps 24px

## Design Tokens

> Web and Flutter use **different** palettes. Do not copy values between them.

### Web (Tailwind v4, `index.css` — warm amber/stone, same hues light & dark)
| Token | Light | Dark (`.dark`) |
|---|---|---|
| Primary | `#b45309` | `#fbbf24` |
| Background | `#fffbeb` | `#1c1917` |
| Card / Surface | `#ffffff` | `#292524` |
| Foreground | `#292524` | `#f5f3f0` |
| Muted foreground | `#78716c` | `#a8a29e` |
| Border / Input | `#e7e5e4` | `#44403c` |
| Success | `#0d9488` | `#34d399` |
| Destructive | `#dc2626` | `#f87171` |

### Flutter (`config/theme.dart` — QuickpassColors, gold `#FFD700` accent)
See `flutter_app.md` and the Flutter Admin Panel Visual Patterns below.
