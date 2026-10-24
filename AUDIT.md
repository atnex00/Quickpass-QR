# Quickpass-QR — Codebase Audit Report

Date: 2026-08-10
Scope: backend/, web/, flutter_app/, database/, scripts/, CI, repo hygiene
Method: read-only parallel audits (backend security, web frontend, Flutter app, infra/repo)

---

## CONSOLIDATED SUMMARY

### HIGH — functional breakage

| # | Finding | Location |
|---|---|---|
| 1 | `npm run seed` fails on fresh DB — seed calls `setval('employee_id_seq', ...)` but migration `013_add_approval_metadata` drops that sequence | `database/seeds/002_employees.js:12,62` vs `database/migrations/013_add_approval_metadata.js:10-13` |
| 2 | `.env.prod` is dead — `NODE_ENV=production` loads `.env.production` (doesn't exist), so prod runs on base `.env` | `prod.sh:4`, `backend/src/app.js:10`, `knexfile.js:7` |
| 3 | Gate Pass page polls every 5s -> 180 req/15min, blows the 100/15min rate limit — app 429s after ~8 min | `web/src/pages/employee/QrDisplayPage.tsx:11,37` vs `backend/src/app.js:143-151` |
| 4 | Cross-user stale state on web — `logout()` only clears authStore; leaveStore/scanStore keep previous user's data | `web/src/stores/authStore.ts:50-59` |
| 5 | Cross-user cache leak in Flutter — `CacheService.clearAll()` exists but is never called; user B authenticates as user A on network failure; unread badge persists | `flutter_app/lib/services/cache_service.dart:103-110`, `auth_provider.dart:47-55` |
| 6 | iOS crashes at startup — placeholder Firebase iOS config + unguarded `FirebaseAnalytics/Crashlytics.instance` | `flutter_app/lib/firebase_options.dart:26-33`, `main.dart:43-53,213` |

### MEDIUM — security & correctness

Backend:
- `trust proxy 1` lets clients spoof `X-Forwarded-For` -> rate-limit bypass (`app.js:126`)
- Profile photos served with no auth + client-controlled extension (`.html`/`.svg` polyglot = stored-XSS vector) (`app.js:197-201`, `authController.js:272-277`)
- Refresh token returned in JSON body for any `User-Agent: Dart` (spoofable, 7-day theft window) (`authController.js:78-80,310`)
- Placeholder secrets (`change-this-...`) pass `requireEnv`; `QR_SECRET` known -> forge QR codes (`app.js:37-40`, `.env.example`)
- `syncHR.js` default password `quickpass123` for all imports, no forced change (`scripts/syncHR.js:26,671...`)
- Bulk import leaks raw DB errors; CSV export vulnerable to formula injection (`adminController.js:549`, `auditController.js:34-47`)
- `rejectUnauthorized: false` in dev DB config; cookie `secure` flag tied to `NODE_ENV`; CSP `'unsafe-inline'` in scriptSrc

Web:
- Icon-only buttons without aria-labels; `opacity-0` delete button unusable for keyboard (a11y)
- Admin/search inputs fire API calls per keystroke, no debounce
- Sidebar re-renders whole nav tree every second (clock state)
- Most security-critical logic (401->refresh->retry) untested

Flutter:
- No role guards on AdminPanel/SupervisorDashboard; FCM `new_request` notification pushes supervisor UI to any role (`notification_service.dart:104-115`)
- Contradictory cleartext config: `usesCleartextTraffic="true"` ignored (NSC denies it) -> dev HTTP flow broken on modern Android (`AndroidManifest.xml:13`, `network_security_config.xml:3`)
- Camera stays active when scanner tab hidden (`scanner_screen.dart:42-49`); QR screen polls 5s forever (`qr_display_screen.dart:37-44`)
- Hardcoded LAN IP as default API URL (`app_config.dart:4-7`)
- Silent error swallows (logout, toggleActive, FCM token registration); no Android 13+ notification permission request

Infra:
- `backend/.env.dev` is tracked in git with real dev DB password + secrets (in history since initial commit)
- docker-compose: cert generator writes `scripts/certs` but web mounts root `./certs` -> `up` fails; AGENTS.md "backend only" claim wrong
- `lint-staged` uses `bash -c` — breaks Windows commits without Git Bash; root scripts bash-only
- `migrate:rollback` fails on seeded data (down() re-applies NOT NULL with NULLs present)

### LOW (sample)
Dead code: orphaned `SecurityHeader.tsx`, unused `DeviceService`, unused deps (`date-fns`, `tailwindcss-animate` — dialog animations inert), stray assets; doc drift (README says 8/11 migrations — actual 14; dead `npm run tunnel` ref; nonexistent `src/index.js`); `tsconfig.tsbuildinfo` tracked in git; Sentry error handler unreachable; `JWT_EXPIRES_IN` ignored.

### VERIFIED SOUND
Route guards (web + backend), QR HMAC + one-time use + ±15min window, scan requires security role, IDOR ownership checks, mass-assignment whitelists, no SQL injection, token storage (memory + httpOnly cookie / FlutterSecureStorage), interceptor cleanup, no hardcoded prod secrets.

---

## 1. BACKEND AUDIT

### 1.1 MEDIUM — `trust proxy 1` allows `X-Forwarded-For` spoofing -> rate-limit bypass and forged IP attribution
`backend/src/app.js:126` (`app.set('trust proxy', 1)`)
With `trust proxy = 1`, Express trusts the client-supplied `X-Forwarded-For` header for direct connections. All IP-based rate limiters (`userOrIpKey` at `app.js:128-140`, login limiter at `app.js:166-172`, global limiter) key on `req.ip`, and `req.ip` is also stored in `qr_scan_logs.ip_address` (`scanController.js:99`) and audit logs. `docker-compose.yml` publishes backend port `3000:3000` directly, so a client with network access to that port can send a spoofed `X-Forwarded-For` on every request and rotate keys, bypassing the 20-attempt/15-min login limit entirely.
Fix: Don't trust the proxy when the app is directly reachable; bind backend to `127.0.0.1` in docker-compose and let only nginx/proxy set `X-Forwarded-For`, or configure `trust proxy` to the exact proxy hop count.

### 1.2 MEDIUM — Refresh token (`refresh_sid`) is delivered in the API response body for any client with `User-Agent: Dart`
`backend/src/controllers/authController.js:78-80` (login), `:103` (refresh accepts body token), `:158-160` (refresh returns body token), `:310-313` (`isMobileClient` = UA contains `"Dart"`)
The long-lived (7-day) refresh token is sent in plaintext JSON for mobile clients, exposed to any proxy/log that records response bodies. The UA check is trivially spoofable. No device/IP binding — a stolen `refresh_sid` can be used from anywhere for up to 7 days (rotation only invalidates after first use).
Fix: Dedicated mobile token flow, bind sessions to a device/IP fingerprint checked on refresh.

### 1.3 MEDIUM — Profile photos (and all of `uploads/`) are served without authentication; filenames are enumerable
`backend/src/app.js:197-201` (`app.use('/uploads', express.static(uploadsDir))`)
`/uploads/photos/<employee_id>_<timestamp>.<ext>` is publicly readable with no auth. Employee IDs are sequential 6-digit numbers, so every employee's photo is trivially enumerable. QR images under `uploads/qr_codes` are correctly blocked by the 404 middleware, but photos are not.
Fix: Serve photos through an authenticated endpoint or use unguessable filenames.

### 1.4 MEDIUM — Raw signed QR payloads (`out_qr_code`/`in_qr_code`) are returned to same-department supervisors
`backend/src/controllers/leaveController.js:175` and `:105-111`
Supervisors can read full QR payloads for any leave in their department. Impact bounded (HMAC + ±15min window), but least-privilege violation.
Fix: Project out `out_qr_code`/`in_qr_code` from supervisor-facing queries.

### 1.5 MEDIUM — Secret strength is never validated; `.env.example` placeholder secrets would silently deploy
`backend/src/app.js:37-40` (`requireEnv` only checks presence), `backend/.env.example:19,23,26`
If example/dev values reach production, an attacker with the known secret can forge JWTs (full auth bypass) and forge valid OUT/IN QR payloads (`qrService.js:31-34`).
Fix: Reject secrets matching known placeholders in production; enforce minimum entropy.

### 1.6 MEDIUM — Default password `quickpass123` hardcoded for HR-synced accounts
`backend/scripts/syncHR.js:26, 671, 689, 764, 798`
Every imported employee gets the same known default password; no forced-password-change mechanism.
Fix: Random per-employee passwords delivered out-of-band, or force password change on first login.

### 1.7 MEDIUM — Bulk import leaks raw database error messages to the client
`backend/src/controllers/adminController.js:549`
Per-employee import failures echo raw `err.message` (Postgres constraint violations, connection errors) in the API response.
Fix: Map expected failures to fixed messages; log `err.message` server-side only.

### 1.8 MEDIUM — `ssl: { rejectUnauthorized: false }` for dev/test DB connections
`backend/knexfile.js:23, 43, 63` (dev/development/test); production correctly uses `rejectUnauthorized: true` (`knexfile.js:83`)
Dev environments connect to Supabase cloud with certificate verification disabled. Also `ssl` only enabled when `DB_SSL === 'true'`.
Fix: Default `DB_SSL=true` and `rejectUnauthorized: true` for non-local environments.

### 1.9 MEDIUM — Login brute-force facilitated by sequential IDs + weak seed passwords + spoofable IP keying
`backend/src/routes/index.js:55-61`, `database/seeds/002_employees.js:10` (all `pass1234`), `backend/src/app.js:166-172` (20 attempts/15 min per IP)
Combined with finding 1.1, the effective login throttle is bypassable; employee IDs are sequential.
Fix: Fix 1.1; require password complexity; consider per-account + per-IP throttling.

### 1.10 MEDIUM — Cookie `secure` flag depends solely on `NODE_ENV === 'production'`
`backend/src/controllers/authController.js:56` and `:152`
The optional HTTPS server (port 3443) and TLS-terminated staging send the refresh cookie over plaintext HTTP whenever `NODE_ENV` isn't exactly `production`.
Fix: Base `secure` on an explicit env flag or `req.secure`.

### 1.11 MEDIUM — CSP allows `'unsafe-inline'` for scripts
`backend/src/app.js:86-98`
Also, CSP is only applied when `CORS_ORIGIN` is set (a misconfig silently disables it).
Fix: Remove `'unsafe-inline'` from scriptSrc (use nonces/hashes); apply helmet defaults unconditionally.

### 1.12 MEDIUM — Admin/supervisors see raw internal error messages on 5xx
`backend/src/middleware/errorHandler.js:9-11`
`showMessage = err.expose && (isPrivileged || statusCode < 500)` — invites raw DB messages leaking to privileged users.
Fix: Never expose `err.message` for status >= 500.

### 1.13 MEDIUM — CSV formula injection in audit export
`backend/src/controllers/auditController.js:34-47`
CSV escapes double quotes but not cells beginning with `=`, `+`, `-`, `@`. `actor_name`/`description` are attacker-influenced (employee can set `full_name` to `=cmd|'/C calc'!A0` via `updateProfile`).
Fix: Prefix cells starting with `= + - @` with `'`.

### 1.14 MEDIUM — Profile-photo upload accepts spoofable content and stores with client-controlled extension
`backend/src/controllers/authController.js:259-265` (magic-byte check), `:272` (`ext = path.extname(req.file.originalname)`)
Shallow magic-byte check (a WAV file passes as "WebP"); stored filename uses client-provided extension, served via express.static (content-type follows extension). Multer fileFilter trusts client `mimetype`.
Fix: Force extension from detected magic bytes, re-encode with sharp, validate with a real image decoder.

### 1.15 LOW — Synchronous filesystem operations in async request handler
`backend/src/controllers/authController.js:273-277`, `qrImageService.js:78`
Blocks event loop during photo upload/QR cleanup; failed `unlinkSync` can orphan files.
Fix: Use `fs.promises`.

### 1.16 LOW — `updateProfile` email change is not checked for uniqueness
`backend/src/controllers/authController.js:193-212`
Hits `employees.email` unique constraint -> unhandled `23505` -> generic 500.
Fix: Pre-check email uniqueness; return 409.

### 1.17 LOW — `getStatus` and `getLogs` admin endpoints bypass the `PANEL_ENABLED` gate
`backend/src/controllers/panelController.js:16-36, 82-94`
`getStatus` (memory, node version, PID, env) and `getLogs` (last 100 lines of app.log, may contain error stacks) are not gated while the mutating endpoints are.
Fix: Apply the same gate.

### 1.18 LOW — Session lookup doesn't bind the JWT's `employee_id` to the session row
`backend/src/middleware/auth.js:14-17`
`db('sessions').where({ session_id: decoded.session_id, is_active: true })` doesn't check `employee_id = decoded.employee_id`.
Fix: Add `.andWhere('employee_id', decoded.employee_id)`.

### 1.19 LOW — Start/end time comparison is lexicographic and allows seconds format mismatch
`backend/src/controllers/leaveController.js:17-19`
Works for zero-padded `HH:MM` but breaks with mixed `HH:MM:SS`; accepts `start_time = end_time`.
Fix: Normalize to canonical `HH:MM:SS` before comparing.

### 1.20 LOW — Error logging may serialize SQL/query details; redaction covers only headers
`backend/src/config/logger.js:12`, `backend/src/middleware/errorHandler.js:6`
Knex errors embed failing SQL and bindings.
Fix: Add pino redact paths for `err.sql`, `err.bindings`, `err.stack` in production.

### 1.21 LOW — Sentry error handler is unreachable
`backend/src/app.js:223-226`, `backend/src/middleware/errorHandler.js:3` (`_next` never called)
Custom `errorHandler` responds without `next(err)`, so `sentry.setupErrorHandler(app)` never receives request errors.
Fix: Call `next(err)` after responding or register Sentry's handler first.

### 1.22 LOW — `express-rate-limit` v7 and Express 4 are one major behind current
`backend/package.json:27, 28`
express-rate-limit latest is 8.6.2 (v7 in use); Express latest 5.2.1 (4.22.2 in use). All other deps current: uuid@14.0.1, sharp@0.35.3, firebase-admin@14.1.0 (latest 14.2.0). No known-vulnerable versions found.
Fix: No urgency; plan the rate-limit major upgrade; monitor Express 4 EOL.

### 1.23 LOW — Dead config: `JWT_EXPIRES_IN` is set but ignored
`backend/.env:9`, `.env.dev:8`, `authController.js:50,145` (hardcoded `expiresIn: '15m'`)
Fix: Read `process.env.JWT_EXPIRES_IN` or remove the var.

### 1.24 LOW — `getApprovedLeaves`/`getTeamLeaves` scoping quirks
`backend/src/controllers/supervisorController.js:233-238` (supervisors see all approved leaves in department incl. other supervisors' teams), `:331-357` (admins restricted to own department)
Read-only over/under-exposure; write paths verified safe.
Fix: For admins in `getTeamLeaves`, skip the department filter.

### Backend verified sound
- JWT algorithm pinning: `algorithms: ['HS256']` enforced in `auth.js:12` and rate-limit key generator
- QR HMAC + replay controls: HMAC-SHA256 with `timingSafeEqual`, signature covers all fields, ±15-min window, one-time use via unique `(leave_id, qr_type)` + `forUpdate()` row lock, `23505` fallback
- Scan authorization: `/api/scan/*` requires `requireSecurity`
- `/api/scan` rate-limit skip intentional and covered: global limiter skips the path but a dedicated 300/15-min limiter is mounted; import endpoints have 5/hour limiter
- Ownership/IDOR: leave read/cancel enforce employee-owner or admin; supervisor approve/reject/revoke enforce assigned supervisor + department; no employee->employee IDOR
- Mass assignment: explicit whitelists everywhere
- SQL injection: no unsafe `db.raw` with user input
- Session security: rotation with row lock, logout revocation, password-change revocation, stale-session cleanup on boot and daily purge; roles re-read from DB per request

---

## 2. WEB FRONTEND AUDIT

### 2.1 HIGH — Gate Pass page polling exhausts the per-user rate limit, breaking the app
`web/src/pages/employee/QrDisplayPage.tsx:11,37` (`POLL_INTERVAL = 5000`, `setInterval(() => fetchLeave(false), POLL_INTERVAL)`)
Backend global limiter: `backend/src/app.js:143-151` — 100 requests / 15 min per user. 5s polling = 180 req/15min, blowing the budget in ~8 minutes -> 429 on every API call, QR page flips to error state.
Fix: Poll at 15-30s, or stop polling when the QR is marked used, or fetch only on window focus/visibility change.

### 2.2 MEDIUM — Cross-user stale state after logout (stores never reset)
`web/src/stores/authStore.ts:50-59` — `logout()` clears only authStore. leaveStore and scanStore keep the previous user's data; user B sees user A's data on first render.
Fix: Reset all stores in `logout()` (or add a shared `resetAll()`).

### 2.3 LOW — Failed logins trigger a wasted `/auth/refresh` round-trip
`web/src/lib/api.ts:51-68` — any 401 triggers refresh, including the 401 from `POST /auth/login`.
Fix: Skip refresh when `originalRequest.url === "/auth/login"`.

### 2.4 LOW — `err.config` may be undefined in the 401 interceptor
`web/src/lib/api.ts:54-56` — `originalRequest._retry = true` can throw TypeError.
Fix: Guard with `if (!originalRequest) return Promise.reject(err)`.

### 2.5 Verified OK — auth/API layer
- Access token held in module variable, NOT localStorage; refresh token is httpOnly signed cookie
- Refresh dedupe via `_refreshPromise`; `_retry` flag prevents loops; `/auth/refresh` excluded from retry
- 401 -> `_onAuthFailure` -> store cleared -> redirect to `/login`
- `loadUser` called once via `isMounted` ref

### 2.6 Verified OK — route guards
- All `/admin/*` and `/supervisor/*` wrapped in `RequireRole`; `/security/*` inside `SecurityShell` (requires `is_security || is_admin`); `/employee/*` and `/guides` intentionally open to any authenticated role

### 2.7 LOW — AdminPanelPage double-redirect for non-admins
`web/src/pages/admin/AdminPanelPage.tsx:74-78` — page navigates to `/login` but the guard redirects to `/employee`. Pick one.

### 2.8 Verified OK — QR payload/signature handling
- Ownership enforced server-side; QR image fetched as authorized blob; one-time use polled + server-enforced; no client-side regeneration; no hardcoded secrets in web/src

### 2.9 MEDIUM — Profile-photo upload allows attacker-controlled file extensions (stored-XSS vector)
`backend/src/controllers/authController.js:272-277` — file saved with client extension (`.html`/`.svg`), served by static; polyglot could execute in victim's session. Also no `X-Content-Type-Options: nosniff` (`web/nginx.conf`).
Fix: Derive extension from detected magic bytes; add nosniff + CSP.

### 2.10 Verified OK — XSS
No `dangerouslySetInnerHTML`; only innerHTML write clears a qr-code-styling container (not user input); no `target="_blank"` without rel.

### 2.11 LOW — `SecurityHeader.tsx` is fully orphaned
`web/src/components/layout/SecurityHeader.tsx` — never imported. Delete it (contains icon-only logout with no aria-label).

### 2.12 LOW — Unused exports and dependency
- `web/src/lib/utils.ts:33-49` — `statusColors`/`statusLabels` never imported
- `web/src/components/ui/card.tsx:29-48` — `CardDescription`, `CardFooter` unused
- `web/package.json:21` — `date-fns` never imported
- `web/package.json:32,45,50` — `tailwindcss-animate`, `autoprefixer`, `postcss` never referenced; `animate-in`/`fade-in-0` classes in `dialog.tsx:19,42` are inert

### 2.13 LOW — Miscellaneous dead expressions
- `AdminPanelPage.tsx:349` — `parsed.msg || parsed.msg || line` (duplicate condition)
- `UserManagerPage.tsx:336,374,459` — stray JSX comments
- `web/tsconfig.tsbuildinfo` tracked in git — build artifact should be gitignored

### 2.14 MEDIUM — Icon-only controls without accessible names
- `SecurityHeader.tsx:21-26,43,46,48`; `ScanHistoryPage.tsx:23,31`; `ScanResultPage.tsx:80-87`; `Sidebar.tsx:161-180` (collapsed: Profile/Logout/toggle)
Fix: Add aria-label/title.

### 2.15 MEDIUM — Invisible-until-hover delete button (keyboard/touch inaccessible)
`web/src/pages/admin/DepartmentsPage.tsx:111-118` — `opacity-0 group-hover:opacity-100`, no aria-label, focusable but invisible.

### 2.16 LOW — Color contrast failures
- `index.css:38` — `--muted-foreground: #78716c` on `#fffbeb` ~4.3:1 (just under WCAG AA 4.5:1)
- `index.css:46,68` — `--success-foreground: #ffffff` on `#0d9488` ~3.5:1 (fails AA)
- 9-12px labels at `/40`-`/60` opacity fail badly

### 2.17 Verified OK — images
All `<img>` tags have `alt`.

### 2.18 MEDIUM — Sidebar re-renders the entire nav tree every second
`web/src/components/layout/Sidebar.tsx:58-63` — 1s setInterval re-renders all ~15 NavLinks; interval also runs on mobile where only MobileBottomBar renders. Intervals are cleaned up.
Fix: Isolate the clock into a tiny component; skip interval on mobile.

### 2.19 LOW — Search inputs fire API requests on every keystroke (no debounce)
`web/src/pages/admin/UserManagerPage.tsx:110-113,340-345`; `AuditLogPage.tsx:56-59`.

### 2.20 Verified OK — performance
lucide icons imported individually; recharts manually chunked; heavy libs lazy-loaded; keys present; no useEffect dependency bugs.

### 2.21 MEDIUM — Most security-critical logic is untested
`web/src/lib/__tests__/api.test.ts:33-61` — smoke-only; never exercises 401 -> refresh -> retry, refresh-failure path, or `/auth/refresh` exclusion. authStore tests miss `updateProfilePhoto`, `setOnAuthFailure`, `loadUser` error path. themeStore test smoke-only. `StatusBadge.test.tsx` tests the wrong component.

### 2.22 LOW — nginx has no security headers
`web/nginx.conf:1-25` — no nosniff, CSP, or X-Frame-Options.

### 2.23 Verified OK — config
vite proxy + alias correct; manualChunks names match; eslint config correct; `/load-preview` route DEV-only and tree-shaken in prod.

---

## 3. FLUTTER APP AUDIT

### 3.1 MEDIUM — Hardcoded LAN endpoint as default base URL
`lib/config/app_config.dart:4-7` — defaults to `http://192.168.0.231:3000/api`. A release build without the define connects to a developer's home LAN over cleartext HTTP.
Fix: Default empty or gate behind `kDebugMode`.

### 3.2 MEDIUM — Logout swallows server-side session invalidation
`lib/services/api_service.dart:192-199` — `catch (_) {}` around `POST /auth/logout`; server session stays valid.
Fix: Log the failure; at minimum don't silently drop.

### 3.3 MEDIUM — `getActiveLeave()` swallows all errors and returns null
`lib/services/api_service.dart:267-274` — every failure becomes "no active leave"; provider falls back to cache and clears `_error`, hiding real outages.
Fix: Re-throw non-404 errors or return a tri-state.

### 3.4 LOW — No transport hardening
`api_service.dart:46-50` — no TLS pinning, no min TLS version; cleartext possible in dev.
Fix: Certificate pinning for production hosts.

### 3.5 INFO — Refresh flow sound
Refresh via `refresh_sid`, 401 queueing (`_pendingRequests`), retry cap 3 then `clearLocalAuth()` + `onForceLogout`. Tokens in FlutterSecureStorage. No hardcoded credentials.

### 3.6 HIGH — Cross-user cache leakage: SharedPreferences cache is never cleared on logout
`lib/services/cache_service.dart:103-110` defines `clearAll()` but it is never called. Logout paths only clear secure storage.
- `auth_provider.dart:47-55` — loads previous user's cached profile and sets `_isAuthenticated = true` during network failure
- `leave_provider.dart:71-77`, `supervisor_provider.dart:38-45` — same stale fallback; cache keys not user-scoped
Fix: Call `CacheService().clearAll()` inside `ApiService.clearLocalAuth()`; scope cache keys by `employee_id`.

### 3.7 MEDIUM — Stale cached profile trusted without token validation
`auth_provider.dart:47-57` — cached profile authenticates the session with no server round-trip; inner `catch (cacheError) {}` empty swallow.
Fix: Only fall back to cache for display; set `_isAuthenticated = false` unless token validated.

### 3.8 LOW — Unread-notification badge persists across users
`lib/providers/notification_provider.dart:10-28` — `unread_count` in SharedPreferences; `_resetProviders()` doesn't reset NotificationProvider; logout never clears key.
Fix: Reset on logout.

### 3.9 INFO — No notifier leaks
Providers created once in `_QuickpassAppState` (main.dart:107-116); `reset()` on force logout; `initialize()` guarded by `_isInitializing`.

### 3.10 MEDIUM — No client-side role guard on AdminPanel/SupervisorDashboard; notification deep-link pushes supervisor UI to any role
- `lib/screens/admin/admin_panel.dart:10-66` and `lib/screens/supervisor/supervisor_dashboard.dart:18-111` have no role check (only SecurityShell guards itself)
- `lib/services/notification_service.dart:104-115` — `_navigateByType('new_request')` pushes SupervisorDashboard unconditionally; same in `main.dart:139-156`. Server 403s, but UI + requests still happen.
Fix: Mirror SecurityShell guard; gate notification navigation on role.

### 3.11 LOW — Routing priority hides security role for admin+security users
`main.dart:178-184 / 247-259` — `isAdmin` wins over `isScanner`; admin+security user (999999) can never reach the scanner.
Fix: Add scanner destination for admin+security users.

### 3.12 LOW — Jailbreak/root detection is startup-only and partial
`lib/services/device_security_service.dart:8-15` — only `isJailBroken`, once before `runApp`. `isNotTrust` (emulator) and `checkForIssues` (debugger/dev-mode/Frida) unused. Fail-closed on plugin error.
Fix: Policy decision — use `checkForIssues`/`isNotTrust` and re-check on resume if required.

### 3.13 LOW — Compromised-device handler leaves cache behind
`device_security_service.dart:17-19` — calls `clearLocalAuth()` which clears secure storage only (see 3.6).

### 3.14 INFO — QR display one-time-use server-driven and correct
Cards show "Already Scanned" once scanTime set; countdown self-cancels; `_resolveTarget()` only computes countdown target — signature verification is server-side.

### 3.15 MEDIUM — Contradictory cleartext config: manifest attribute is dead, dev HTTP is blocked
`android/app/src/main/AndroidManifest.xml:13` (`usesCleartextTraffic="true"`) vs `android/app/src/main/res/xml/network_security_config.xml:3` (cleartext denied). Per Android docs, the manifest flag is ignored on API 24+ when a Network Security Config exists -> LAN/dev flow fails at the network layer.
Fix: debug-only NSC (or domain-config for dev hosts); remove misleading manifest attribute.

### 3.16 MEDIUM — Camera keeps running when the scanner tab is not visible
`lib/screens/security/scanner_screen.dart:42-49` — `didUpdateWidget` only handles `active` false->true; switching to Dashboard/History (IndexedStack) leaves the camera + torch active offscreen.
Fix: On `active == false`, call `_controller?.stop()`.

### 3.17 MEDIUM — QR screen polls the server every 5 s forever
`qr_display_screen.dart:37-44` — `Timer.periodic(5s)` for whole screen lifetime even after both passes scanned/expired; failures silently swallowed.
Fix: Stop polling once both scans set or OUT window is after; longer interval otherwise.

### 3.18 INFO — Scanner validation flow sound
`scanner_screen.dart:105-131` guards with `_isProcessing`; both camera and manual-entry paths validate server-side; result screen has proper loading/success/error UI.

### 3.19 LOW — `DeviceService` is unused
`lib/services/device_service.dart:6-17` — `getFingerprint()` has zero call sites.

### 3.20 INFO — No orphans from deleted widgets
`custom_app_bar.dart` and `qr_code_widget.dart` deleted; no remaining references.

### 3.21 LOW — Stray unreferenced assets
`assets/images/logo.png`, `assets/references/*.png` (5 files) — not declared in pubspec, not referenced.

### 3.22 INFO — Minor unused constants
`lib/utils/constants.dart` — `outQrLabel`, `inQrLabel`, `qrCountdownInterval`, `scanTimeout`, `employeeIdLength` unused.

### 3.23 INFO — Unused dev dependency
`pubspec.yaml:42-43` declares `integration_test` but no `integration_test/` directory exists.

### 3.24 MEDIUM — Silent error swallows with user-visible impact
- `lib/screens/admin/employee_detail_screen.dart:435-449` — Deactivate/Activate `catch (_) {}` with no feedback (appears to succeed on failure)
- `lib/services/notification_service.dart:61-65` — FCM token send failure swallowed, no retry
- `lib/services/api_service.dart:196`, `auth_provider.dart:95` — logout failures swallowed
- `qr_display_screen.dart:43,434` — polling/parse errors dropped
- `auth_provider.dart:56-57` — empty `catch (cacheError) {}`

### 3.25 INFO — Good error/loading UI coverage elsewhere
leave_history, dashboard (RefreshIndicator + error), pending_requests, scan_result, admin tabs all have proper states.

### 3.26 INFO — Disposal generally correct
qr_display cancels poll timer + countdown; scanner disposes controller/observer/text; connectivity_banner cancels everything; admin_employee_tab cancels Debouncer.

### 3.27 LOW — Unmounted `context.read` race in scan result
`scan_result_screen.dart:29-32` — `addPostFrameCallback` uses `context.read` without `mounted` check; popping within the same frame throws.

### 3.28 HIGH (iOS only) — Firebase placeholder config will crash iOS at startup
- `lib/firebase_options.dart:26-33` — iOS options are placeholders
- `main.dart:43-50` — Firebase init skipped when key starts with `YOUR_`
- But `main.dart:213` calls `FirebaseAnalytics.instance` every build and `main.dart:53,56,84` call `FirebaseCrashlytics.instance` — both throw when Firebase never initialized -> iOS crashes at startup
Fix: Guard analytics/crashlytics behind an `isFirebaseConfigured` flag.

### 3.29 LOW — Real Firebase API key committed in source
`lib/firebase_options.dart:18` — client-side identifier (not secret by design), but verify console has app restrictions (package + SHA-1).

### 3.30 MEDIUM — No runtime notification permission request on Android 13+
`lib/services/notification_service.dart:34-58` never calls `requestNotificationsPermission()`. On Android 13+ the prompt never appears.
Fix: Call `requestNotificationsPermission()` during `init()`.

### 3.31 LOW — Release build silently falls back to the debug keystore
`android/app/build.gradle.kts` — release falls back to debug signing when key.properties absent, no warning.

### 3.32 LOW — iOS push background mode not configured
`ios/Runner/Info.plist` has no `UIBackgroundModes` (remote-notification) and no push entitlements.

### 3.33 INFO — Dependency versions resolve cleanly
dio 5.11.0, mobile_scanner 6.0.11, flutter_secure_storage 9.2.4, firebase 15.2.10/11.6.0/4.3.10, no conflicts.

### 3.34 LOW — `test/widget_test.dart` is a placeholder
Pumps a bare MaterialApp with hardcoded "Quickpass" text — verifies nothing about the real app.

### 3.35 INFO — Broad meaningful coverage exists
~50 test files (models, providers, services, 6 screens) with mocked Dio/secure storage/prefs. Gaps: admin screens, supervisor screens, SecurityShell, main.dart routing, NotificationService.

### 3.36 LOW — Security-service test only exercises the fail-closed path
`test/services/device_security_service_test.dart:13-17` — jailbreak_root_detection channel not mocked, so `isDeviceCompromised()` always returns true in tests; clean-device path untested.

---

## 4. INFRASTRUCTURE & REPO AUDIT

### 4.1 HIGH — `npm run seed` fails after a fresh migrate
`database/seeds/002_employees.js:12,62` call `SELECT setval('employee_id_seq', ...)`; `database/migrations/013_add_approval_metadata.js:10-13` drops both `generate_employee_id()` and `employee_id_seq`. Seeds run after `migrate:latest` -> `relation "employee_id_seq" does not exist`.
Fix: Remove the two `setval` calls (IDs are explicit) or stop dropping the sequence.

### 4.2 CONFIRMED — two `013_` files exist; ordering is lexical
`013_add_approval_metadata.js` and `013_leave_requests_optional_department.js` — Knex sorts lexicographically (`013_a` before `013_l`). AGENTS.md's warning is correct; fragile but consistent.

### 4.3 OK — 013_add_approval_metadata up/down symmetric
up(): adds `approved_at`, `approved_by` FK, drops function + sequence. down(): reverses. Does not modify employees table.

### 4.4 MEDIUM — down() of the "optional department" migrations will fail on seeded data
`013_leave_requests_optional_department.js:7-10` and `008_optional_department.js:7-10` re-apply `notNullable()` which throws if NULLs exist (seed 999999 has `department_id: null`).
Fix: down() should delete NULL rows first or be a no-op.

### 4.5 OK — Seeds
Department references valid (DEP-001..006; 999999 null). Seed data matches AGENTS.md test users/passwords.

### 4.6 LOW — 001_departments.js truncate list omits `audit_logs`
`database/seeds/001_departments.js:6` — only cleared via CASCADE from employees. Fragile.

### 4.7 MEDIUM — root npm scripts are bash-only; `stop.sh`/`run.sh` need `lsof`/`pgrep` which Git Bash on Windows doesn't ship
`package.json:7-8` env-prefix syntax fails in cmd/PowerShell without bash on PATH. `scripts/stop.sh:22,41`, `scripts/run.sh:57` use `lsof`/`pgrep` — not bundled with Git for Windows.
Fix: cross-env or PowerShell twins; document Git Bash requirement.

### 4.8 MEDIUM — double port-kill race + over-broad kill
`dev.sh:30` runs `free-port.js 3000`, then `backend/package.json:10` (predev) runs it again. `backend/scripts/free-port.js:7-9` uses `findstr :${port}` (substring match — also matches `:30000`) and `taskkill /F`s whatever PID holds the port.

### 4.9 LOW/MEDIUM — docs reference a nonexistent `backend/src/index.js`
AGENTS.md and README.md:395 reference it; file does not exist.

### 4.10 LOW — mojibake/encoding corruption in script headers
`scripts/setup_db.ps1`, `setup_db.sh`, `uninstall.ps1`, `run_phone.sh`, `generate-certs.sh`, `generate-keystore.sh`, `DEPLOY.md` contain corrupted characters in comments.

### 4.11 LOW — `npm run tunnel` is a dead reference
README.md:542 documents it for `web/`; no such script exists.

### 4.12 OK — CI runs correct commands in correct directories
ci.yml: backend (npm ci -> lint -> test), web (npm ci -> lint -> build -> vitest), flutter (flutter-action + cache -> pub get -> analyze -> test). Backend tests fully mocked (185 cases, no DB) — no real-SQL integration coverage. `jest.setup.js:1` sets `DB_CONNECTION=sqlite::memory:` which is meaningless for the pg client (harmless since db is mocked).

### 4.13 LOW — security.yml lacks npm caching
`.github/workflows/security.yml:13-22` — npm ci twice, no setup-node cache. Push trigger `[push, pull_request]` (all branches) vs ci.yml `[master, khrez]`. Stale branches exist: `tauri`, `main`, `ZNC-Quickpass`, `ZNCQP-React`.

### 4.14 MEDIUM — `backend/.env.dev` is tracked in git
`git ls-files` shows it despite `.gitignore:11-16` ignoring `.env.*`. Contains `postgresql://postgres:admin@localhost:5432/znc-quickpass`, `JWT_SECRET`, `QR_SECRET`, `COOKIE_SECRET`. Dev-only (localhost), but committed secret material in history.
Fix: `git rm --cached backend/.env.dev`, add to .gitignore, rotate local DB password.

### 4.15 MEDIUM — AGENTS.md/README drift with reality
- README.md:440 says "8 Knex migration files"; README.md:454 says "11 files" with table listing 001-011. Actual: 14 files.
- AGENTS.md "docker-compose provides only the backend service" — false (see 4.17).
- AGENTS.md "web/dist served in prod" — verified true. Vite port 8080 verified. HTTPS :3443 verified.

### 4.16 LOW — README command-table errors
README.md:517 says `npm run prod` runs dev.sh — it runs prod.sh. README.md:542 `npm run tunnel` doesn't exist.

### 4.17 MEDIUM — docker-compose contains web AND backend; AGENTS.md/README say "backend service only"
`docker-compose.yml:3-54` defines web (nginx, 8080:80 + 8443:443, volume `./certs`) and backend (env_file `./backend/.env`). No DB service (Supabase claim accurate). `web/nginx.conf:3-5` requires `/etc/nginx/certs/server.crt|server.key` but root `./certs` doesn't exist and `scripts/generate-certs.sh:3` generates into `scripts/certs` — `docker-compose up --build` fails for web service.
Fix: Point generate-certs.sh at root `./certs` (or fix the mount).

### 4.18 LOW — obsolete compose version + prod-env mismatch
`docker-compose.yml:1` `version: '3.8'` obsolete. backend Dockerfile `npm ci --only=production` fine; entrypoint runs migrations (skippable).

### 4.19 MEDIUM — lint-staged relies on `bash -c` (Windows fragility)
`package.json:22,25` — `bash -c "cd web && npx tsc --noEmit"` and `bash -c "cd flutter_app && flutter analyze ..."`. Husky v9 runs hooks via `sh`; on Windows works only with Git Bash installed and on PATH. `--no-fatal-infos --no-fatal-warnings` can mask real analyzer issues.

### 4.20 HIGH — documented `.env.prod` override is never loaded by `npm run prod`
`prod.sh:4` sets `NODE_ENV=production`; env loaders build `.env.${NODE_ENV}` -> `backend/.env.production` (doesn't exist). AGENTS.md, README.md:299-304, and `.env.example` document `.env.prod`. So `npm run prod` silently runs on base `.env`.
Fix: Name the file `.env.production`, or map `production` -> `.env.prod` in `loadEnv()` (app.js:10 and knexfile.js:7).

### 4.21 Secret scan — clean
No private key blocks, sk- keys, AWS keys, or real API tokens in source. Only hits: test fixtures (`Password1`, `pass1234`) and bcrypt hashes. Committed Firebase config (`google-services.json`, `firebase_options.dart`) contains a real Android API key — not a secret by Firebase's model, but note iOS placeholders. `scripts/certs/server.key` exists on disk but is gitignored.

---

## PRIORITIZED FIX ORDER (if fixing)

1. HIGH: seed/sequence (4.1), .env.prod loading (4.20), QR polling (2.1), web store resets (2.2), Flutter cache clearing (3.6), iOS Firebase guard (3.28)
2. MEDIUM security: trust proxy (1.1), photo upload auth+extension (1.3, 1.14, 2.9), refresh token body leak (1.2), secret validation (1.5), CSV injection (1.13), Flutter role guards (3.10), Android notification permission (3.30), camera lifecycle (3.16), cleartext config (3.15)
3. LOW: dead code, doc drift, a11y labels, gitignore tsbuildinfo, .env.dev untracking (4.14)
