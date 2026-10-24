# ZANECO QuickPass — Smart Gatepass & Leave Management

<p align="center">
  <strong>A QR code-based employee leave management system</strong><br />
  React 19 (Web) + Flutter (Android) + Node.js/Express + Supabase (PostgreSQL)
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-Android%20%7C%20Web-brightgreen" alt="Platform: Android + Web" />
  <img src="https://img.shields.io/badge/backend-Node.js%2020-339933" alt="Backend: Node.js 20" />
  <img src="https://img.shields.io/badge/database-PostgreSQL-4169E1" alt="Database: PostgreSQL" />
  <img src="https://img.shields.io/badge/flutter-3.x-02569B" alt="Flutter: 3.x" />
  <img src="https://img.shields.io/badge/react-19-61DAFB" alt="React: 19" />
  <img src="https://img.shields.io/badge/deploy-DEPLOY.md-2ea44f" alt="Production Deployment Guide" />
</p>

---

## Table of Contents

- [Flutter App Architecture](flutter_app.md)
- [Quick Start (Dev Container)](#quick-start-dev-container)
- [Manual Setup](#manual-setup)
  - [Windows](#windows)
  - [macOS](#macos)
  - [Linux](#linux)
- [Environment Switching](#environment-switching)
- [Supabase Setup](#supabase-setup)
- [Project Structure](#project-structure)
- [Production Deployment](DEPLOY.md)
- [Environment Variables](#environment-variables)
- [Available Commands](#available-commands)
- [Architecture Overview](#architecture-overview)
- [Web Routes](#web-routes)
- [API Endpoints](#api-endpoints)
- [Test Users](#test-users)
- [Troubleshooting](#troubleshooting)

---

## Quick Start (Dev Container)

**Requires**: [VS Code](https://code.visualstudio.com/) + [Docker Desktop](https://www.docker.com/products/docker-desktop/)

```bash
git clone <repo-url> Quickpass-QR
cd Quickpass-QR
code .
```

When prompted, click **"Reopen in Container"** (or press `F1` → `Dev Containers: Reopen in Container`).

First build takes ~5 minutes. The container includes:

| Tool | Purpose |
|------|---------|
| **Node.js 20** | Backend runtime |
| **Flutter 3.x + Dart** | Mobile app framework |
| **.NET SDK 8.0** | Build tooling |
| **Docker CLI** | Container management (Docker-from-Docker) |
| **psql** | PostgreSQL client for Supabase inspection |

> **Android SDK**: The dev container mounts your host Android SDK automatically.
> If you don't have it, install [Android Studio](https://developer.android.com/studio) first.

### After Container Opens

```bash
# 1. Set up environment (dev uses local DB, prod uses Supabase)
cp backend/.env.example backend/.env
# Edit backend/.env with your credentials

# 2. Install dependencies
cd backend && npm install
cd ../web && npm install
cd ../flutter_app && flutter pub get

# 3. Run database migrations
cd ../backend
npm run migrate
npm run seed

# 4. Start development (backend + web concurrently)
cd ..
npm run dev
# Backend → http://localhost:3000
# Web     → http://localhost:8080

# Terminal 3 — Flutter app
cd flutter_app
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

---

## Manual Setup

### Windows

#### Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Node.js | 20.x | [nodejs.org](https://nodejs.org/) or `winget install OpenJS.NodeJS.LTS` |
| Flutter | 3.x | [flutter.dev](https://docs.flutter.dev/get-started/install/windows) |
| .NET SDK | 8.0 | `winget install Microsoft.DotNet.SDK.8` |
| Docker | Latest | [Docker Desktop](https://www.docker.com/products/docker-desktop/) (enable **WSL 2 backend**) |
| Android Studio | Latest | `winget install Google.AndroidStudio` |
| Git | Latest | `winget install Git.Git` |

#### Android SDK Setup

```powershell
# Add to your PowerShell profile ($PROFILE):
[Environment]::SetEnvironmentVariable("ANDROID_HOME", "$env:LOCALAPPDATA\Android\Sdk", "User")
[Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", "$env:LOCALAPPDATA\Android\Sdk", "User")

# Restart terminal, then verify:
flutter doctor
```

#### Clone & Install

```powershell
git clone <repo-url> Quickpass-QR
cd Quickpass-QR

# Install backend
cd backend
copy .env.example .env
npm install

# Install web frontend
cd ..\web
npm install

# Install Flutter app
cd ..\flutter_app
flutter pub get
```

#### Configure Environment

Edit `backend\.env` with your Supabase credentials (see [Supabase Setup](#supabase-setup)). The project uses `.env.dev` (local DB) and `.env.prod` (Supabase) — see [Environment Switching](#environment-switching).

#### Run Migrations

```powershell
cd backend
npm run migrate
npm run seed
```

#### Start Development

Open **three terminals**:

```powershell
# Terminal 1 — Backend API (port 3000)
cd backend
npm run dev

# Terminal 2 — Web Frontend (port 8080, proxies /api → :3000)
cd web
npm run dev

# Terminal 3 — Flutter App
cd flutter_app
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

---

### macOS

#### Prerequisites

| Tool | Install Command |
|------|----------------|
| Node.js 20 | `brew install node@20` |
| Flutter 3.x | `brew install --cask flutter` |
| .NET SDK 8 | `brew install --cask dotnet-sdk` |
| Docker Desktop | [docker.com](https://www.docker.com/products/docker-desktop/) |
| Android Studio | `brew install --cask android-studio` |
| Git | `brew install git` |

#### Android SDK Setup

```bash
# Add to ~/.zshrc:
export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_SDK_ROOT=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# Reload and verify
source ~/.zshrc
flutter doctor
```

#### Clone & Install

```bash
git clone <repo-url> Quickpass-QR
cd Quickpass-QR

cd backend && cp .env.example .env && npm install
cd ../web && npm install
cd ../flutter_app && flutter pub get
```

#### Run Migrations & Start

```bash
cd ../backend
npm run migrate
npm run seed
npm run dev

# Terminal 2 — Web (port 8080)
cd web && npm run dev

# Terminal 3 — Flutter
cd flutter_app && flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

---

### Linux

#### Prerequisites (Ubuntu/Debian)

```bash
# Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs git

# Flutter
sudo snap install flutter --classic

# .NET SDK 8
wget https://dot.net/v1/dotnet-install.sh
chmod +x dotnet-install.sh
sudo ./dotnet-install.sh --channel 8.0 --install-dir /usr/share/dotnet
sudo ln -s /usr/share/dotnet/dotnet /usr/local/bin/dotnet

# Docker
sudo apt install -y docker.io docker-compose
sudo usermod -aG docker $USER

# Android Studio
sudo snap install android-studio --classic
```

> **Restart your session** after adding user to `docker` group.

#### Android SDK Setup

```bash
# Add to ~/.bashrc:
export ANDROID_HOME=$HOME/Android/Sdk
export ANDROID_SDK_ROOT=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

source ~/.bashrc
flutter doctor
```

#### Clone & Install

```bash
git clone <repo-url> Quickpass-QR
cd Quickpass-QR

cd backend && cp .env.example .env && npm install
cd ../web && npm install
cd ../flutter_app && flutter pub get
```

#### Run Migrations & Start

```bash
cd backend
npm run migrate
npm run seed
npm run dev

# Terminal 2
cd web && npm run dev

# Terminal 3
cd flutter_app && flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

---

## Environment Switching

The project supports **dev** (local PostgreSQL) and **production** (Supabase cloud) environments via `NODE_ENV`.

The backend loads `backend/.env` first if it exists, then loads `backend/.env.<NODE_ENV>` to override. This keeps simple single-file `.env` setups working while also supporting `.env.dev` / `.env.prod`.

| Env | Base file | Override file | DB Target | Command |
|-----|-----------|---------------|-----------|---------|
| dev | `backend/.env` | `backend/.env.dev` | `localhost:5432/znc-quickpass` | `npm run dev` |
| prod | `backend/.env` | `backend/.env.prod` | Supabase cloud | `npm run prod` |

### Quick Switch

```bash
# Dev mode (local DB + Vite dev server + nodemon)
npm run dev

# Production mode (Supabase DB + built frontend)
npm run build:web   # first build the web frontend
npm run prod        # runs backend serving web/dist
```

### Docker Production Deployment

```bash
docker-compose up --build
```
This uses `NODE_ENV=production`. Copy `backend/.env.prod` to `backend/.env`, or keep `backend/.env` as base and `backend/.env.prod` as override.

---

## Supabase Setup

Quickpass uses **Supabase** for its PostgreSQL database. No local PostgreSQL is needed in production.

### Step 1: Create a Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign up/in
2. Click **"New project"**
3. Fill in:
   - **Name**: `quickpass`
   - **Database password**: Create a strong password (save it)
   - **Region**: Choose the closest one
4. Wait ~2 minutes for the project to provision

### Step 2: Get Connection String

1. In your Supabase project dashboard, go to **Project Settings → Database**
2. Find **Connection string**
3. Select **"URI"** mode
4. Copy the string — it looks like:
   ```
   postgresql://postgres:[PASSWORD]@db.[REF].supabase.co:5432/postgres
   ```

### Step 3: Configure Environment

Create `backend/.env` (base) or `backend/.env.prod` (production override) with at least these values:

```env
NODE_ENV=production
DB_CONNECTION=postgresql://postgres:YOUR_PASSWORD@db.YOUR_REF.supabase.co:5432/postgres
DB_SSL=true
JWT_SECRET=your-strong-random-secret
COOKIE_SECRET=your-strong-random-cookie-secret
QR_SECRET=your-strong-random-qr-secret
CORS_ORIGIN=https://your-frontend-domain.com
```

Production startup will fail if `DB_CONNECTION`, `JWT_SECRET`, `COOKIE_SECRET`, `QR_SECRET`, or `CORS_ORIGIN` are missing.

### Step 4: Run Migrations

```bash
cd backend
npm run migrate
npm run seed
```

### Step 5: Verify

```bash
# Check that tables were created (optional)
psql "$DB_CONNECTION" -c "\dt"
```

---

## Project Structure

```
Quickpass-QR/
├── .devcontainer/
│   ├── devcontainer.json      # VS Code dev container config
│   └── Dockerfile             # Container image (Node, Flutter, .NET, Docker CLI)
├── .agents/                   # AI agent skill definitions
├── .opencode/                 # AI agent configuration
├── backend/                   # Node.js + Express API
│   ├── src/
│   │   ├── app.js             # Express app entry point
│   │   ├── index.js           # Refactored entry (WIP, unused)
│   │   ├── config/            # DB, Firebase configuration
│   │   ├── controllers/       # auth, leave, supervisor, scan, admin
│   │   ├── middleware/        # auth (JWT), validate (Joi), errorHandler
│   │   ├── routes/            # All API route definitions
│   │   └── services/          # QR generation (HMAC-SHA256), push notifications
│   ├── knexfile.js            # DB connection config (4 environments)
│   ├── Dockerfile             # Production container (node:20-alpine)
│   └── .env.dev / .env.prod  # Environment-specific configs
├── web/                       # React 19 + TypeScript + Vite 6
│   ├── src/
│   │   ├── App.tsx            # React Router v7 route definitions
│   │   ├── main.tsx           # Entry point
│   │   ├── components/
│   │   │   ├── layout/        # AppLayout, Sidebar, SecurityShell, RequireRole, MobileBottomBar
│   │   │   ├── ui/            # shadcn/ui primitives (button, card, dialog, input, etc.)
│   │   │   └── shared/        # QrDisplay, StatusBadge
│   │   ├── pages/
│   │   │   ├── auth/          # LoginPage
│   │   │   ├── employee/      # Dashboard, RequestLeave, LeaveHistory, QrDisplay, MyProfile
│   │   │   ├── supervisor/    # SupervisorDashboard, PendingRequests
│   │   │   ├── admin/         # UserManager, Departments, Reports, AuditLog, AdminPanel
│   │   │   ├── security/      # Scanner, ScanResult, ScanHistory
│   │   │   └── guides/        # GuidesPage
│   │   ├── stores/            # Zustand (authStore, leaveStore, scanStore)
│   │   ├── lib/               # Axios client, utilities
│   │   ├── types/             # TypeScript interfaces
│   │   └── hooks/             # useMediaQuery
│   └── vite.config.ts         # Port 8080, /api proxy → :3000
├── flutter_app/               # Flutter 3.27+ mobile app
│   └── lib/
│       ├── main.dart          # Entry + MultiProvider
│       ├── config/            # Theme (Quickpass branding), app config
│       ├── models/            # Employee, LeaveRequest, ScanLog (json_serializable)
│       ├── providers/         # Auth, Leave, Supervisor, Scan (ChangeNotifier)
│       ├── services/          # API (Dio), QR, CertificatePinner
│       ├── screens/
│       │   ├── auth/          # Login, Splash
│       │   ├── employee/      # Dashboard, RequestLeave, History, QR Display, Profile
│       │   ├── supervisor/    # Dashboard, PendingRequests
│       │   ├── admin/         # AdminPanel (tabs: overview/employees/departments/leaves/reports + EmployeeDetail)
│       │   └── security/      # Scanner, ScanResult, ScanHistory
│       ├── widgets/           # StatusBadge, QrCodeWidget, LoadingIndicator, etc.
│       └── utils/             # Validators, DateFormatter, Constants, Debounce, Responsive
├── database/
│   ├── migrations/            # 15 Knex migration files (see below)
│   └── seeds/                 # 2 seed files (departments + employees)
├── scripts/                   # Setup and utility scripts (PowerShell + Bash)
│   ├── setup.ps1 / setup.sh   # Install Flutter + Android SDK into tools/
│   ├── setup_db.ps1 / .sh     # Database setup
│   ├── run.sh / stop.sh       # Start / force-stop all processes + ADB tunnel
│   ├── run_phone.ps1 / .sh    # ADB reverse tunnel for physical device testing
│   ├── test.sh / test.ps1     # Run backend + web + flutter test suites
│   ├── build_release.*        # Release build helpers
│   ├── generate-certs.sh      # Self-signed HTTPS certs for mobile camera access
│   ├── generate-keystore.sh   # Android release keystore generator
│   ├── backup-db.sh           # Database dump helper
│   └── uninstall.*            # Toolchain removal
├── .github/workflows/         # CI (backend lint+test, web lint+typecheck+build+test, flutter analyze+test) + npm audit
├── assets/brand/              # Logo and icon SVGs/PNGs
├── docs/design/               # Design documentation
├── docker-compose.yml         # Production web (nginx) + backend services (DB = Supabase cloud)
├── dev.sh                     # Dev launcher (backend + web concurrently)
├── prod.sh                    # Production launcher (backend + built web)
├── AGENTS.md                  # AI agent project guide
└── package.json               # Root scripts (dev, prod, build:web, migrate, seed)
```

### Database Migrations (14 files)

| # | File | Purpose |
|---|------|---------|
| 1 | `001_create_departments.js` | Departments table |
| 2 | `002_create_employees.js` | Employees table (with password_hash) |
| 3 | `003_create_sessions.js` | JWT session tracking |
| 4 | `004_create_leave_requests.js` | Leave requests with QR code columns |
| 5 | `005_create_qr_scan_logs.js` | QR scan audit log |
| 6 | `006_create_functions.js` | `generate_employee_id()` function |
| 7 | `007_add_is_security.js` | Security role column |
| 8 | `008_optional_department.js` | Make department optional |
| 9 | `009_add_qr_images.js` | Add QR image paths to leave_requests |
| 10 | `010_add_qr_scan_unique_constraint.js` | Enforce one scan per leave/qr_type |
| 11 | `011_create_audit_logs.js` | Audit log table for tracking actions |
| 12 | `012_add_indexes.js` | Performance indexes on hot queries |
| 13 | `013_add_approval_metadata.js` | `approved_at`/`approved_by` columns; drops `generate_employee_id()` function + sequence |
| 13 | `013_leave_requests_optional_department.js` | Makes `department_id` nullable on leave_requests |
| 14 | `014_device_fingerprint.js` | `device_fingerprint` column on `sessions` (mobile device binding) |

> Two files share the `013_` prefix and apply in lexical order — do not rename them after deployment.

---

## Environment Variables

### `backend/.env` / `backend/.env.dev` — Development

| Variable | Description | Default / Fallback |
|----------|-------------|--------------------|
| `PORT` | API server port | `3000` |
| `NODE_ENV` | Environment | `development` |
| `DB_CONNECTION` | PostgreSQL connection string | — (required) |
| `DB_SSL` | Enable SSL for DB connection | `false` |
| `JWT_SECRET` | JWT signing secret | loud dev fallback if unset |
| `COOKIE_SECRET` | Signed cookie secret | loud dev fallback if unset |
| `QR_SECRET` | QR code HMAC signing secret | loud dev fallback if unset |
| `JWT_EXPIRES_IN` | Token expiration | `24h` |
| `SESSION_EXPIRES_IN` | Session duration | `7d` |
| `QR_VALIDITY_WINDOW_MINUTES` | QR code validity window | `15` |

### `backend/.env.prod` — Production

Required in production:

| Variable | Description |
|----------|-------------|
| `DB_CONNECTION` | PostgreSQL connection string |
| `JWT_SECRET` | JWT signing secret |
| `COOKIE_SECRET` | Signed cookie secret |
| `QR_SECRET` | QR code HMAC signing secret |
| `CORS_ORIGIN` | Allowed frontend origin |

Optional:

| Variable | Description |
|----------|-------------|
| `FCM_*` | Firebase Cloud Messaging credentials |
| `HTTPS_KEY` / `HTTPS_CERT` | HTTPS server paths (port 3443 for camera access) |

---

## Available Commands

### Root

| Command | Description |
|---------|-------------|
| `npm run dev` | Backend + web concurrently (`dev.sh`, env: dev) |
| `npm run prod` | Production mode (`prod.sh`, env: production) |
| `npm run dev:backend` | Start backend only (nodemon) |
| `npm run dev:web` | Start Vite dev server only (port 8080, host 0.0.0.0) |
| `npm run build:web` | Build web frontend (`web/dist`) |
| `npm run test` | Run all test suites (`scripts/test.sh`) |
| `npm run migrate` | Run database migrations |
| `npm run seed` | Seed database with sample data |
| `npm run prepare` | Install Husky pre-commit hooks |

### Backend (`backend/`)

| Command | Description |
|---------|-------------|
| `npm run dev` | Start API in watch mode (nodemon) |
| `npm start` | Start API in production |
| `npm test` | Run tests (Jest + Supertest, coverage) |
| `npm run lint` | ESLint on `src/` |
| `npm run migrate` | Run database migrations |
| `npm run migrate:rollback` | Rollback last migration |
| `npm run seed` | Seed database with sample data |

### Web (`web/`)

| Command | Description |
|---------|-------------|
| `npm run dev` | Vite dev server on port 8080 |
| `npm run build` | TypeScript check + Vite build |
| `npm run lint` | ESLint |
| `npm run test` | Vitest unit tests |
| `npm run preview` | Preview production build |

### Flutter (`flutter_app/`)

> **Important:** The default gatepass duration was changed from **2 hours to 7 hours** across all environments (Flutter, Web, Backend). Submissions exceeding 7h receive a backend validation error: `"Duration exceeds 7 hours — HR database verification required (placeholder)"`.

| Command | Description |
|---------|-------------|
| `flutter run` | Run on connected device (uses `API_BASE_URL` from env) |
| `flutter analyze` | Static analysis |
| `flutter test` | Run unit/widget tests |
| `flutter build apk` | Build release APK |
| `flutter build appbundle` | Build Android App Bundle (recommended for Play Store) |
| `flutter build ios` | Build iOS (macOS only) |

> **Production build** uses `env.prod.json` for `API_BASE_URL`:
> ```bash
> flutter build apk --dart-define-from-file=env.prod.json
> ```
> The updated `env.prod.json` sets `API_BASE_URL` to `https://quickpass.example.com/api`.

| Command | Description |
|---------|-------------|
| `flutter run` | Run on connected device |
| `flutter analyze` | Static analysis |
| `flutter test` | Run tests |
| `flutter build apk` | Build release APK |
| `flutter build appbundle` | Build Android App Bundle |
| `flutter build ios` | Build iOS (macOS only) |

> **Default gatepass duration:** 7 hours (changed from 2h across all environments).
> Submissions >7h receive backend error: `"Duration exceeds 7 hours — HR database verification required (placeholder)"`.

> **Environment configuration:**
> - `env.prod.json` — production API URL (`https://quickpass.example.com/api`)
> - `env.dev.json` (or `env.prod.json` modified) — development: `http://10.0.2.2:3000/api` (emulator) or `http://localhost:3000/api` (physical device)
> - `backend/.env.dev` — local PostgreSQL (`znc-quickpass`)
> - `backend/.env.prod` — Supabase cloud production

> **New user onboarding:**
> ```bash
> cd Quickpass-QR
> # 1. Clone & install
> cp backend/.env.example backend/.env    # or copy .env.prod for production
> cd backend && npm install
> cd ../web && npm install
> cd ../flutter_app && flutter pub get
> # 2. Setup database (prompts for PG admin password if needed)
> .\scripts\setup_db.ps1       # uses .env.dev by default
> # 3. Start development
> cd ../backend && npm run dev
> # Terminal 2: cd web && npm run dev
> # Terminal 3: flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
> ```

### Database

| Command | Description |
|---------|-------------|
| `npm run migrate` | Apply all pending migrations |
| `npm run migrate:rollback` | Rollback last batch |
| `npm run seed` | Insert sample data (requires `bcryptjs`; run from `backend/`) |

> **Note:** Running seeds requires `bcryptjs` installed (resolves from `backend/node_modules`, root has a fallback copy).

---

## Mobile Development

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter SDK | 3.27+ ([install guide](https://docs.flutter.dev/get-started/install)) |
| Android Studio | Latest ([download](https://developer.android.com/studio)) |
| .NET SDK | 8.0 (`winget install Microsoft.DotNet.SDK.8`) |
| Physical device or emulator | — |

> **Tip**: Use `scripts/setup.ps1` (Windows) or `scripts/setup.sh` (macOS/Linux) to install Flutter + Android SDK into `tools/`.

### Verify Environment

```bash
cd flutter_app
flutter doctor
```

Ensure all checkmarks are green. Common fixes:

| Issue | Fix |
|-------|-----|
| `✗ Android SDK not found` | Set `ANDROID_HOME` to your SDK path (see OS-specific setup below) |
| `✗ No connected device` | Start an emulator or connect a physical device via USB |
| `✗ cmdline-tools missing` | Open Android Studio → SDK Manager → install `Android SDK Command-line Tools` |

### Running on an Emulator

1. Open **Android Studio** → **More Actions** → **Virtual Device Manager**
2. Create a new device (e.g., Pixel 7 — API 35)
3. Start the emulator
4. Verify with `flutter devices`

```bash
cd flutter_app
# 10.0.2.2 is the emulator alias for your host machine's localhost
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

### Running on a Physical Device

1. Enable **Developer options** and **USB debugging** on your phone
2. Connect via USB — accept the debugging prompt on your phone
3. Verify with `flutter devices`

```bash
# ADB reverse tunnel so the phone can reach the backend
scripts\run_phone.ps1

cd flutter_app
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
```

### Building on Physical Device (Local Dev URL)

When running on a real phone (not emulator), `localhost` points to the phone itself. Use your computer's LAN IP so the device can reach the backend directly.

```powershell
# Find your host LAN IP (e.g., 192.168.254.100)
flutter build apk --release --dart-define=API_BASE_URL=http://192.168.254.100:3000/api
```

Then install and run:

```powershell
flutter install
flutter run --dart-define=API_BASE_URL=http://192.168.254.100:3000/api
```

For ADB reverse tunnel (phone uses `localhost:3000`):

```powershell
scripts\run_phone.ps1
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
```

### Building for Production

```bash
# Debug APK (fast, for testing)
flutter build apk --debug

# Release APK (split by ABI for smaller size)
flutter build apk --split-per-abi

# Android App Bundle (recommended for Play Store)
flutter build appbundle

# iOS (macOS only)
flutter build ios
```

#### Android Keystore (Release Builds)

Create a keystore:

```bash
# Generate a keystore (replace placeholders)
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA \
  -keysize 2048 -validity 10000 -alias upload

# Move it to flutter_app/android/app/
```

Then create `flutter_app/android/key.properties`:

```properties
storePassword=your-store-password
keyPassword=your-key-password
keyAlias=upload
storeFile=../app/upload-keystore.jks
```

### Running Tests

```bash
# Static analysis
flutter analyze

# Unit & widget tests
flutter test

# Coverage
flutter test --coverage
```

### Common Issues

| Problem | Solution |
|---------|----------|
| `flutter pub get` fails | Check internet connection and `pubspec.yaml` syntax |
| Gradle build fails | Open `flutter_app/android/` in Android Studio to sync Gradle |
| App crashes on launch | Run `adb logcat \| grep flutter` to see crash logs |
| Camera permission denied | Go to **Settings → Apps → Quickpass → Permissions → Camera** |
| `API_BASE_URL` not working | Ensure the backend is running and the port matches (default `:3000`) |
| Emulator is slow | Enable **Hardware acceleration** in AVD settings (HAXM on Windows, Hypervisor.framework on macOS) |
| `flutter build apk` fails | Run `flutter clean && flutter pub get` and retry |
| **SDK version mismatch** | shared_preferences ^2.5.5 requires Dart SDK >=3.9.0, but this project has 3.6.0.<br>Fix: edit pubspec.yaml and change shared_preferences: ^2.5.5 to shared_preferences: ^2.0.5, then run lutter pub get. |
| `flutter build apk` fails with `Unsupported class file major version 69` or `com.android.application` plugin error | Flutter uses Android Studio embedded JDK 25 (`jbr`) instead of JDK 21. Fix: `flutter config --jdk-dir "C:\Program Files\Eclipse Adoptium\jdk-21.0.12.101-hotspot"`, set `JAVA_HOME` to that path, clear `.gradle/caches/8.5`, and ensure `gradle-wrapper.properties` uses `gradle-8.14-all.zip` (min 8.13, not 8.5). |

---

## Architecture Overview

```
┌───────────────────┐                              ┌──────────────────┐     SQL      ┌─────────────┐
│   Web App (React) │                              │  Node.js API     │ ◄──────────► │  Supabase   │
│   Port 8080       │     REST/JSON (via proxy)     │  (Express)       │   Knex.js    │  PostgreSQL │
│                   │ ◄───────────────────────────► │                  │              │             │
│ • Employee UI     │                              │ • Controllers    │              │ • Employees │
│ • Supervisor      │                              │ • QR Service     │              │ • Leave Req │
│ • Admin Panel     │                              │ • Push Notifs    │              │ • Scan Logs │
│ • Security Scanner│                              │ • Auth (JWT)     │              │ • Sessions  │
│ • QR Display      │                              │                  │              │             │
└───────────────────┘                              └────────┬─────────┘              └─────────────┘
                                                             │
                          REST/JSON (direct)                 │
┌───────────────────┐                                        │
│ Flutter App       │ ◄──────────────────────────────────────┘
│ (Android)         │
│                   │                              ┌──────────────────┐
│ • Employee UI     │                              │  Firebase Cloud  │
│ • Supervisor      │                              │  Messaging       │
│ • Admin Panel     │                              │  (Push Notifs)   │
│ • QR Scanner      │                              └──────────────────┘
│ • QR Display      │
└───────────────────┘
```

### State Management

- **Web**: Zustand stores (authStore, leaveStore, scanStore) → Axios (`@/lib/api`, cookie-based JWT with `ZNCQP_token`)
- **Flutter**: ChangeNotifier + Provider (Auth, Leave, Supervisor, Scan) → singleton Dio ApiService (`FlutterSecureStorage` for JWT)

### Workflow

1. **Employee** requests leave → status: `pending`
2. **Supervisor** approves → QR codes generated (OUT + IN, HMAC-SHA256 signed, one-time use, valid ±15 min) and QR images rendered with the brand logo (`uploads-private/qr_codes`, served via authenticated endpoints)
3. **Security** scans OUT QR at exit → status: `active`
4. **Security** scans IN QR at entry → status: `completed`
5. Unscanned QR passes past validity → status: `expired` (server-side sweep on startup, ±15 min from scheduled time)

Each OUT/IN QR can only be scanned once. The database enforces this with a unique constraint and the scan is wrapped in a transaction. Actual scan times are recorded (`out_scan_time` / `in_scan_time` on the leave, `scan_time` in `qr_scan_logs`).

### Roles

| Role | Access |
|------|--------|
| `is_admin` | Full access (all routes, employee management, departments, reports) |
| `is_supervisor` | Approve/reject department leave requests, view team calendar |
| `is_security` | Scan QR codes at gates, view scan history |
| Regular employee | Submit leaves, view history, view QR codes |

---

## Web Routes

| Path | Guard | Component | Layout |
|------|-------|-----------|--------|
| `/login` | Public | LoginPage | None |
| `/employee` | Any | EmployeeDashboard | AppLayout (sidebar) |
| `/employee/request` | Any | RequestLeavePage | AppLayout |
| `/employee/history` | Any | LeaveHistoryPage | AppLayout |
| `/employee/qr/:id` | Any | QrDisplayPage | AppLayout |
| `/employee/profile` | Any | MyProfilePage | AppLayout |
| `/supervisor` | is_supervisor/is_admin | SupervisorDashboard | AppLayout |
| `/supervisor/pending` | is_supervisor/is_admin | PendingRequestsPage | AppLayout |
| `/admin/employees` | is_admin | UserManagerPage | AppLayout |
| `/admin/departments` | is_admin | DepartmentsPage | AppLayout |
| `/admin/reports` | is_admin | ReportsPage | AppLayout |
| `/admin/audit` | is_admin | AuditLogPage | AppLayout |
| `/admin/panel` | is_admin | AdminPanelPage | AppLayout |
| `/security/scan` | is_security/is_admin | ScannerPage | SecurityShell (no sidebar) |
| `/security/result` | is_security/is_admin | ScanResultPage | SecurityShell |
| `/security/history` | is_security/is_admin | ScanHistoryPage | SecurityShell |
| `/guides` | Any | GuidesPage | AppLayout |
| `*` | — | Redirect → `/employee` | — |

---

## API Endpoints

### Health

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/health` | API health check |

### Auth

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/auth/login` | — | Login with employee ID + password |
| POST | `/api/auth/logout` | ✓ | Invalidate session |
| POST | `/api/auth/refresh` | — | Refresh JWT token |
| GET | `/api/auth/profile` | ✓ | Get current user profile |
| PUT | `/api/auth/profile` | ✓ | Update profile (name, position, email, password) |
| POST | `/api/auth/profile/photo` | ✓ | Upload profile photo (max 5MB) |
| PUT | `/api/auth/fcm-token` | ✓ | Update FCM push token |

### Leave Requests

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/leave/request` | ✓ | Submit new leave request |
| GET | `/api/leave/history` | ✓ | Get user's leave history (filterable by status) |
| GET | `/api/leave/active` | ✓ | Get current active leave |
| GET | `/api/leave/:id` | ✓ | Get leave by ID |
| GET | `/api/leave/:id/qr/:type` | ✓ | Get QR code image (OUT/IN) |
| POST | `/api/leave/:id/cancel` | ✓ | Cancel a pending/approved leave |
| DELETE | `/api/leave/:id` | admin | Delete a leave request |

### Supervisor

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/supervisor/pending` | supervisor | Pending requests (department-scoped) |
| POST | `/api/supervisor/approve/:leaveId` | supervisor | Approve and generate QR codes |
| POST | `/api/supervisor/reject/:leaveId` | supervisor | Reject with reason |
| GET | `/api/supervisor/approved` | supervisor | List approved leaves |
| GET | `/api/supervisor/history` | supervisor | Supervisor decision history |
| POST | `/api/supervisor/revoke/:leaveId` | supervisor | Revoke approval |
| GET | `/api/supervisor/team-leaves` | supervisor | Team leave calendar |

### Scanning

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/scan/validate` | security | Validate scanned QR code |
| GET | `/api/scan/history` | security | Scan log history (optional `department` filter) |
| GET | `/api/scan/history/departments` | security | Scan counts per department |
| GET | `/api/scan/stats` | security | Today's scan statistics |

### Admin

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/admin/employees` | admin | List employees (search/filter) |
| POST | `/api/admin/employees` | admin | Create employee |
| PUT | `/api/admin/employees/:id` | admin | Update employee |
| PUT | `/api/admin/employees/:id/supervisor` | admin | Toggle supervisor status |
| PUT | `/api/admin/employees/:id/admin` | admin | Toggle admin status |
| PUT | `/api/admin/employees/:id/status` | admin | Toggle active status |
| DELETE | `/api/admin/employees/:id` | admin | Delete employee |
| POST | `/api/admin/import/hr` | admin | Bulk import from CSV/HR system |
| GET | `/api/admin/departments` | admin | List departments |
| POST | `/api/admin/departments` | admin | Create department |
| PUT | `/api/admin/departments/:id` | admin | Update department |
| DELETE | `/api/admin/departments/:id` | admin | Delete department |
| GET | `/api/admin/reports` | admin | Generate reports |
| GET | `/api/admin/audit` | admin | Audit log (paginated, filterable by actor) |
| GET | `/api/admin/export` | admin | Export audit log |

### Admin Panel (operations)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/admin/panel/status` | admin | Server + DB status |
| GET | `/api/admin/panel/metrics` | admin | Request/error metrics |
| GET | `/api/admin/panel/logs` | admin | Recent log lines |
| POST | `/api/admin/panel/migrate` | admin | Run pending migrations |
| POST | `/api/admin/panel/seed` | admin | Run database seeds |
| POST | `/api/admin/panel/restart` | admin | Restart the server |

---

## Test Users

All passwords are `pass1234`.

| ID | Name | Role | Department |
|----|------|------|------------|
| 000001 | James Wilson | Employee | TSD · Technical Services Department |
| 000002 | Maria Garcia | Employee | IAD · Internal Audit Department |
| 000003 | John Lee | Employee | HRAD · Human Resource & Administration |
| 000004 | Sara Patel | Employee | FSD · Finance Services Department |
| 000005 | Alex Turner | Employee | ISD · Institutional Services Department |
| 000006 | Emily Davis | Employee | ISD · Institutional Services Department |
| 000007 | Ryan Chen | Employee | CPD · Corporate Planning Department |
| 000008 | Olivia Brown | Employee | FSD · Finance Services Department |
| 000009 | Daniel Kim | Employee | TSD · Technical Services Department |
| 000010 | Sophia Martinez | Employee | CPD · Corporate Planning Department |
| 000011 | Ethan White | Supervisor | TSD · Technical Services Department |
| 000012 | Ava Johnson | Employee | CPD · Corporate Planning Department |
| 000013 | Noah Taylor | Supervisor | HRAD · Human Resource & Administration |
| 000014 | Isabella Anderson | Supervisor | FSD · Finance Services Department |
| 000015 | Liam Thomas | Supervisor | ISD · Institutional Services Department |
| 000016 | Mia Jackson | Employee | CPD · Corporate Planning Department |
| 000017 | Lucas Harris | Supervisor | CPD · Corporate Planning Department |
| 000018 | Charlotte Martin | Supervisor | IAD · Internal Audit Department |
| 000019 | Mason Thompson | Employee | TSD · Technical Services Department |
| 000020 | Amelia Robinson | Employee | CPD · Corporate Planning Department |
| 090901 | Mike Ross | Security | ISD · Institutional Services Department |
| 090902 | Sarah Connor | Security | ISD · Institutional Services Department |
| 090903 | John Smith | Security | ISD · Institutional Services Department |
| 090904 | David Miller | Security | ISD · Institutional Services Department |
| 090905 | Chris Evans | Security | ISD · Institutional Services Department |
| 090906 | Tony Stark | Security | ISD · Institutional Services Department |
| 090907 | Natasha Romanoff | Security | ISD · Institutional Services Department |
| 090908 | Steve Rogers | Security | ISD · Institutional Services Department |
| 090909 | Bruce Banner | Security | ISD · Institutional Services Department |
| 090910 | Clint Barton | Security | ISD · Institutional Services Department |
| 999999 | System Admin | Admin + Supervisor + Security | — |

---

## Troubleshooting

### General

| Problem | Solution |
|---------|----------|
| `flutter doctor` shows missing Android SDK | Set `ANDROID_HOME` env var and install Android Studio |
| `npm run migrate` fails | Check `DB_CONNECTION` in `.env.<env>` and that Supabase allows your IP |
| `npm run seed` fails with "relation `employee_id_seq` does not exist" | Known issue: migration `013_add_approval_metadata` drops the ID sequence that the seed still references (see `AUDIT.md`) |
| `flutter pub get` fails | Ensure you're in the `flutter_app` directory |
| QR scanner not working | Grant camera permission in Android Settings → Apps → Quickpass |
| Backend won't start | Check missing required env vars (`DB_CONNECTION`, `JWT_SECRET`, `COOKIE_SECRET`, `QR_SECRET`, `CORS_ORIGIN` in production) and that port 3000 is free |
| Web app shows blank page | Run `npm run build:web` first if using production mode, or check Vite dev server is running on port 8080 |

### Supabase Connection Issues

```
Error: connect ECONNREFUSED db.xxxxx.supabase.co:5432
```

1. Go to **Supabase Dashboard → Project Settings → Database → Network**
2. Add your IP address to the allowlist
3. Ensure `DB_SSL=true` is set in `.env.prod`

### Dev Container Issues

| Problem | Solution |
|---------|----------|
| Container build fails | Allocate at least 8GB RAM to Docker in Docker Desktop settings |
| Docker-from-Docker not working | Ensure `docker-from-docker` feature is enabled in `devcontainer.json` |
| Flutter not found in container | Run `flutter --version` — the SDK is at `/opt/flutter` |
| Android SDK not found | Ensure your host has `~/Android/Sdk` and it's mounted in `devcontainer.json` |

### Port Conflicts

If port 3000 is in use:

```bash
# Find what's using port 3000 (macOS/Linux)
lsof -i :3000

# Find what's using port 3000 (Windows PowerShell)
netstat -ano | findstr :3000

# Kill it or use a different port:
$env:PORT=3001; npm run dev  # Windows PowerShell
export PORT=3001 && npm run dev  # macOS/Linux
```

---

## Security

This project follows defense-in-depth security practices across all layers.

### Backend

| Measure | Description |
|---------|-------------|
| **JWT algorithm pinning** | Tokens are signed and verified with `HS256` only — `"alg": "none"` attacks are rejected |
| **Account enumeration prevention** | Login and token verification return identical messages for invalid credentials, inactive accounts, and deactivated employees |
| **Rate limiting** | Global: 100 req/15min (skips `/api/scan` and QR refresh polling on `GET /api/leave/:id`), scan: 300 req/15min, login: 20 req/15min, auth refresh: 30 req/15min, bulk import: 5 req/hour |
| **Magic byte validation** | Uploaded files are validated by content (JPEG, PNG, GIF, WebP magic bytes), not just MIME type |
| **Password complexity** | Admin-created passwords require uppercase, lowercase, and digit (min 8 chars) |
| **QR signature verification** | HMAC-SHA256 with constant-time comparison (`crypto.timingSafeEqual`) |
| **Session rotation** | Refresh tokens are rotated on each use; old sessions are invalidated |
| **HTTP-only cookies** | `refresh_sid` cookie uses `httpOnly`, `signed`, `sameSite: strict`, and `secure` (in production) |
| **Helmet/CSP** | Security headers applied via Helmet; CSP restricts scripts, styles, and frame ancestors |
| **CORS** | Configurable origin via `CORS_ORIGIN` env var; credentials support |
| **Input validation** | Joi schemas on all routes; body size limited to 1 MB |
| **Scan integrity** | Revoking an approved leave preserves scan timestamps if the employee has already exited |

### Authorization

| Check | Enforcement |
|-------|-------------|
| **Supervisor IDOR** | Supervisors can only view leave requests within their own department |
| **Security routes** | Web `SecurityShell` requires `is_security` or `is_admin` role (frontend guard) |
| **Backend role middleware** | `requireAdmin`, `requireSupervisor`, `requireSecurity` enforce roles server-side |
| **Deactivated accounts** | Middleware invalidates sessions and returns generic `401` for deactivated users |

### Web Frontend

| Measure | Description |
|---------|-------------|
| **Role-gated routes** | Scanner/security pages require `is_security` or `is_admin` in addition to authentication |
| **No console data leaks** | QR validation responses are not logged to the browser console |
| **Dev-only routes** | `/load-preview` page stripped from production builds |
| **In-memory token** | JWT stored in JavaScript closure (not localStorage/sessionStorage) |
| **Cookie-based refresh** | Session refresh via httpOnly signed cookie |

### Flutter App

| Measure | Description |
|---------|-------------|
| **FlutterSecureStorage** | JWT tokens encrypted at rest (not SharedPreferences) |
| **Certificate pinning** | OS-level TLS validation; pinning framework available (`CertificatePinner`) |
| **Provider state cleanup** | `LeaveProvider`, `SupervisorProvider`, `ScanProvider` reset on logout |
| **No raw exceptions** | SnackBars show generic messages instead of raw error details |
| **Password validation** | Client-side enforces minimum 8 characters |
| **`FLAG_SECURE`** | Screenshots and screen recording blocked on Android |
| **`allowBackup: false`** | App data excluded from Android cloud backup |

---

## License

MIT
