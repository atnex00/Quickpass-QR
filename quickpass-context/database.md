---
tags:
  - quickpass
  - database
  - schema
---
# Database Architecture

## Connection
- PostgreSQL via Knex (query builder, not ORM)
- Connection string from `DB_CONNECTION` env var
- Dev: `postgresql://postgres:1234@localhost:5432/zaneco_quickpass`
- Prod: Supabase cloud

## Tables

### departments
| Column | Type | Notes |
|---|---|---|
| department_id | VARCHAR(20) PK | e.g. `DEP-001` |
| department_name | VARCHAR(100) | UNIQUE, NOT NULL |
| department_code | VARCHAR(10) | UNIQUE, nullable |
| head_of_department | VARCHAR(100) | nullable |
| is_active | BOOLEAN | default true |
| created_at | TIMESTAMP | default NOW() |

### employees
| Column | Type | Notes |
|---|---|---|
| employee_id | VARCHAR(6) PK | Zero-padded 6-digit string |
| full_name | VARCHAR(100) | NOT NULL |
| position | VARCHAR(50) | NOT NULL |
| department_id | VARCHAR(20) | FK → departments, nullable |
| email | VARCHAR(100) | UNIQUE, NOT NULL |
| password_hash | VARCHAR(255) | NOT NULL (bcrypt) |
| is_supervisor | BOOLEAN | default false |
| is_admin | BOOLEAN | default false |
| is_security | BOOLEAN | default false |
| is_active | BOOLEAN | default true |
| profile_photo | VARCHAR(255) | nullable |
| fcm_token | VARCHAR(255) | nullable |
| hire_date | DATE | nullable |
| last_login | TIMESTAMP | nullable |

Indexes: `department_id`, `is_supervisor`, `(department_id, is_supervisor)`, `is_security`

### sessions
| Column | Type | Notes |
|---|---|---|
| session_id | VARCHAR(36) PK | UUID |
| employee_id | VARCHAR(6) | FK → employees, NOT NULL |
| is_active | BOOLEAN | default true |
| created_at | TIMESTAMP | default NOW() |
| expires_at | TIMESTAMP | NOT NULL |

### leave_requests
| Column | Type | Notes |
|---|---|---|
| leave_id | VARCHAR(30) PK | `LV-YYYYMMDD-XXXXXXXX` |
| employee_id | VARCHAR(6) | FK → employees, NOT NULL |
| department_id | VARCHAR(20) | FK → departments, NOT NULL |
| supervisor_id | VARCHAR(6) | FK → employees, NOT NULL |
| leave_date | DATE | NOT NULL |
| start_time | VARCHAR(8) | HH:mm or HH:mm:ss |
| end_time | VARCHAR(8) | HH:mm or HH:mm:ss |
| reason | TEXT | NOT NULL |
| status | ENUM | pending/approved/rejected/active/completed/cancelled |
| out_qr_code | TEXT | base64url JSON |
| in_qr_code | TEXT | base64url JSON |
| out_qr_image | VARCHAR(500) | Path to PNG |
| in_qr_image | VARCHAR(500) | Path to PNG |
| out_scan_time | TIMESTAMP | nullable |
| in_scan_time | TIMESTAMP | nullable |
| rejection_reason | TEXT | nullable |

Indexes: `employee_id`, `supervisor_id`, `status`, `leave_date`, `(department_id, status)`

### qr_scan_logs
| Column | Type | Notes |
|---|---|---|
| log_id | BIGSERIAL PK | Auto-increment |
| leave_id | VARCHAR(30) | FK → leave_requests, NOT NULL |
| qr_type | ENUM('OUT','IN') | NOT NULL |
| scanned_by | VARCHAR(6) | (logical FK to employees) |
| scan_time | TIMESTAMP | default NOW() |
| ip_address | VARCHAR(45) | nullable |
| location | VARCHAR(100) | nullable |
| is_valid | BOOLEAN | default true |
| validation_message | TEXT | nullable |

UNIQUE constraint on `(leave_id, qr_type)`

## Relationships
```
departments 1───* employees
employees   1───* sessions
employees   1───* leave_requests (as employee)
employees   1───* leave_requests (as supervisor)
departments 1───* leave_requests
leave_requests 1───* qr_scan_logs
```

## State Machine
```
pending → approved (supervisor approves) → active (OUT scanned) → completed (IN scanned)
pending → rejected (supervisor rejects with reason)
approved → pending (supervisor revokes approval)
```

## Key Queries
- **Leave history**: `leave_requests` LEFT JOIN `employees` (twice: as emp + sup), paginated
- **Conflict check**: `start_time < ? AND end_time > ?` on same date, exclude rejected/cancelled
- **Approve**: Transaction with `FOR UPDATE` row lock, generate QR codes, update status
- **Scan validation**: Transaction with `FOR UPDATE`, verify state machine, check UNIQUE constraint

## Migrations (10 files, in order)
| # | File | Action |
|---|---|---|
| 001 | `001_create_departments.js` | departments table |
| 002 | `002_create_employees.js` | employee_id_seq + employees table |
| 003 | `003_create_sessions.js` | sessions table |
| 004 | `004_create_leave_requests.js` | leave_requests table |
| 005 | `005_create_qr_scan_logs.js` | qr_scan_logs table |
| 006 | `006_create_functions.js` | generate_employee_id() function |
| 007 | `007_add_is_security.js` | is_security column + index |
| 008 | `008_optional_department.js` | department_id nullable |
| 009 | `009_add_qr_images.js` | out_qr_image, in_qr_image columns |
| 010 | `010_add_qr_scan_unique_constraint.js` | UNIQUE (leave_id, qr_type) |

## Seeds
- **8 departments** (Engineering, Marketing, HR, Finance, Operations, Sales, IT, R&D)
- **12 employees** — all password `pass1234`

## Database Function
`generate_employee_id()` — PL/pgSQL function using sequence `employee_id_seq`, returns zero-padded 6-digit string.
