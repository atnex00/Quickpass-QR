---
tags:
  - quickpass
  - decisions
  - adr
---
# Architecture Decisions

## 1. No ORM — Knex Query Builder
**Why**: Full control over SQL while still avoiding raw query string concatenation. Knex provides migration tooling and parameterized queries without the overhead/abstraction of a full ORM.

## 2. In-Memory JWT on Web
**Why**: Access tokens stored in a module-level variable (not localStorage) to prevent XSS exfiltration. Refresh tokens are HTTP-only cookies (not accessible via JS). On page reload, `/auth/refresh` restores the session.

## 3. Dual .env System
**Why**: Supports both legacy single-file `.env` setups and modern `.env.dev`/`.env.prod` patterns for different environments. `.env.<NODE_ENV>` overrides `.env`.

## 4. Single Route File
**Why**: All API endpoints defined in one `routes/index.js` file makes it easy to audit the full API surface. Controllers remain separate for logic.

## 5. QR Code as Encrypted JSON
**Why**: QR data is HMAC-SHA256 signed JSON (not a random token). This allows offline-capable gates: security app can validate the QR without a DB lookup (though the actual status transition always goes through the server for consistency).

## 6. Manual Cascade Deletes
**Why**: Application-level cascade (not DB-level `ON DELETE CASCADE`) for explicit control and logging. Admin operations delete in order: scan_logs → sessions → leave_requests → employee.

## 7. Flutter Provider (not Bloc/Riverpod)
**Why**: Simpler state management suitable for the app's complexity level. ChangeNotifier + Provider pattern is well-understood and sufficient for 5 providers.

## 8. No Named Routes in Flutter
**Why**: Role-based home routing makes static route tables awkward. Imperative `Navigator.push` is simpler for the screen depth involved.

## 9. LEFT JOIN Convention
**Why**: All `leave_requests` queries use LEFT JOIN to employees so that if an employee is deleted, historical leave data remains visible.

## 10. Firebase FCM Graceful Degradation
**Why**: Push notifications are optional. If FCM env vars are missing, the app still works — just without push notifications. No startup failure.

## 11. Rate Limiting by Endpoint Type
**Why**: Different endpoints have different risk profiles. Login (20/15min) and refresh (30/15min) are stricter than general API (100/15min). HR import (5/hour) prevents accidental bulk operations.

## 12. Optional HTTPS Server
**Why**: Mobile camera access requires HTTPS. The optional HTTPS server on port 3443 allows local testing with real device cameras without a full production setup.
