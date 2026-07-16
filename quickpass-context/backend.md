---
tags:
  - quickpass
  - backend
  - api
---
# Backend Architecture

## Entry Point
`src/app.js` — the only entry point (not `src/index.js`).

Startup sequence:
1. Load env (`.env` then `.env.<NODE_ENV>`, defaults to `dev`)
2. Validate required env vars (`DB_CONNECTION`)
3. Generate secrets if missing (JWT_SECRET, COOKIE_SECRET, QR_SECRET)
4. Init Express with helmet, cors, cookie-parser, rate limiting
5. Init Firebase (gracefully degrades if missing FCM env vars)
6. Mount routes at `/api`
7. SPA fallback, 404 handler, error handler
8. Start HTTP on `PORT` (default 3000) + optional HTTPS on 3443

## Auth Flow
- **Login**: POST `/auth/login` → validate credentials → create session → return JWT (15min) + signed `refresh_sid` cookie (7d)
- **Authenticate middleware**: Verify Bearer JWT → check session active → load employee with department → set `req.user`
- **Token refresh**: POST `/auth/refresh` → validate session from cookie → rotate → new JWT
- **Logout**: Invalidate session, clear cookie

## Role Guards (in `middleware/auth.js`)
| Guard | Checks |
|---|---|
| `requireSupervisor` | `is_supervisor \|\| is_admin` |
| `requireAdmin` | `is_admin` |
| `requireSecurity` | `is_security \|\| is_admin` |

## API Routes

### Auth
| Method | Path | Description |
|---|---|---|
| POST | `/auth/login` | Login with employee_id + password |
| POST | `/auth/logout` | Logout, invalidate session |
| POST | `/auth/refresh` | Refresh JWT via cookie |
| GET | `/auth/profile` | Get current profile |
| PUT | `/auth/profile` | Update name/position/email/password |
| POST | `/auth/profile/photo` | Upload profile photo (multipart) |
| PUT | `/auth/fcm-token` | Store FCM push token |

### Employee Leave
| Method | Path | Description |
|---|---|---|
| POST | `/leave/request` | Submit leave (date must be today) |
| GET | `/leave/history` | Paginated history with status filter |
| GET | `/leave/active` | Current active/approved leave |
| GET | `/leave/:id` | Single leave detail |
| DELETE | `/leave/:id` | Admin: hard-delete + scan logs |

### Supervisor
| Method | Path | Description |
|---|---|---|
| GET | `/supervisor/pending` | Pending leaves (own dept unless admin) |
| POST | `/supervisor/approve/:leaveId` | Approve → generate OUT/IN QR codes |
| POST | `/supervisor/reject/:leaveId` | Reject with reason |
| GET | `/supervisor/approved` | Approved leaves |
| POST | `/supervisor/revoke/:leaveId` | Revoke → back to pending |
| GET | `/supervisor/team-leaves` | Team leaves with date or range (`start_date`/`end_date`) filter |

### Security/Scan
| Method | Path | Description |
|---|---|---|
| POST | `/scan/validate` | Validate QR, transition leave status |
| GET | `/scan/history` | Paginated scan log |

### Admin
| Method | Path | Description |
|---|---|---|
| POST | `/admin/employees` | Create employee |
| GET | `/admin/employees` | List with search/filter |
| PUT | `/admin/employees/:id` | Update employee |
| PUT | `/admin/employees/:id/supervisor` | Toggle supervisor |
| PUT | `/admin/employees/:id/admin` | Toggle admin |
| PUT | `/admin/employees/:id/status` | Toggle active |
| DELETE | `/admin/employees/:id` | Hard-delete + cascade |
| POST | `/admin/import/hr` | Bulk import |
| GET | `/admin/departments` | List departments |
| POST | `/admin/departments` | Create department |
| PUT | `/admin/departments/:id` | Update department |
| DELETE | `/admin/departments/:id` | Delete (fails if employees exist) |
| GET | `/admin/reports` | Reports (daily/department/summary) |

### Notes
- `GET /supervisor/team-leaves` accepts optional `date` (single day) or `start_date` + `end_date` (range) — calendar view uses range
- Also returns `pending` leaves for calendar visibility (shows upcoming approved + pending together)

## Firebase Admin SDK
- v14+ — `admin.cert()` is top-level (not `admin.credential.cert()`)
- Graceful degradation: if FCM env vars missing, push notifications disabled (no crash)

## QR Code System

- **Data payload**: `{ leave_id, employee_id, type (OUT|IN), timestamp, signature }`
- **Signature**: `HMAC-SHA256(QR_SECRET, `${leaveId}:${employeeId}:${type}:${timestamp}`)`
- **Encoding**: JSON → base64url
- **Validation**: decode → verify HMAC (timing-safe) → check 15-min window → state machine transition
- **One-time use**: UNIQUE `(leave_id, qr_type)` constraint prevents replay

## Rate Limiting
| Scope | Window | Max |
|---|---|---|
| Global | 15 min | 100 |
| Login | 15 min | 20 |
| Refresh | 15 min | 30 |
| HR import | 60 min | 5 |

## Controllers
| File | Functions | Lines |
|---|---|---|
| `authController.js` | login, logout, refreshToken, getProfile, updateProfile, fcmToken, uploadProfilePhoto | 306 |
| `leaveController.js` | submitLeave, getHistory, getActiveLeave, getLeaveById, deleteLeave | 225 |
| `supervisorController.js` | getPendingRequests, approveLeave, rejectLeave, getApprovedLeaves, revokeApproval, getTeamLeaves | 313 |
| `scanController.js` | validateScan, getScanHistory | 174 |
| `adminController.js` | 13 functions for employee/dept/report CRUD | 454 |

## Services
| Service | Purpose |
|---|---|
| `qrService.js` | HMAC signing, base64url encode/decode, time window check |
| `qrImageService.js` | QR SVG → PNG via sharp, with logo overlay, amber/teal accents |
| `notificationService.js` | FCM push notifications (leave submitted/approved/rejected/scanned) |

## Middleware
| Middleware | Purpose |
|---|---|
| `auth.js` | authenticate, requireSupervisor, requireAdmin, requireSecurity |
| `validate.js` | Joi body (`validate`) and query (`validateQuery`) validation |
| `errorHandler.js` | Centralized error handler + `createError(status, message)` helper |

## Validation
All schemas defined inline in `routes/index.js` with Joi. Key patterns:
- Employee ID: `/^\d{6}$/`
- Password: min 8 chars (admin: must have uppercase+lowercase+digit)
- Dates: ISO format
- Times: `HH:mm` or `HH:mm:ss` format
- All fields stripped of unknown keys, abort on first error

## Env Config
- `.env` base + `.env.<NODE_ENV>` overrides (default NODE_ENV = `dev`)
- `.env.dev` for local, `.env.prod` for production (Supabase)
- Critical vars: `DB_CONNECTION`, `JWT_SECRET`, `COOKIE_SECRET`, `QR_SECRET`, `CORS_ORIGIN`
