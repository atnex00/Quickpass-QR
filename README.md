# Quickpass — Smart Gatepass & Leave Management

<p align="center">
  <img src="assets/brand/logo.svg" alt="Quickpass Logo" width="400" />
</p>

<p align="center">
  <strong>A QR code-based employee leave management system</strong><br />
  Flutter (Android) + Node.js/Express + Supabase (PostgreSQL)
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-Android-brightgreen" alt="Platform: Android" />
  <img src="https://img.shields.io/badge/backend-Node.js%2020-339933" alt="Backend: Node.js 20" />
  <img src="https://img.shields.io/badge/database-PostgreSQL-4169E1" alt="Database: PostgreSQL" />
  <img src="https://img.shields.io/badge/flutter-3.x-02569B" alt="Flutter: 3.x" />
</p>

---

## Table of Contents

- [Quick Start (Dev Container)](#quick-start-dev-container)
- [Manual Setup](#manual-setup)
  - [Windows](#windows)
  - [macOS](#macos)
  - [Linux](#linux)
- [Supabase Setup](#supabase-setup)
- [Project Structure](#project-structure)
- [Environment Variables](#environment-variables)
- [Available Commands](#available-commands)
- [Architecture Overview](#architecture-overview)
- [API Endpoints](#api-endpoints)
- [Brand Identity](#brand-identity)
- [Troubleshooting](#troubleshooting)

---

## Quick Start (Dev Container)

**Requires**: [VS Code](https://code.visualstudio.com/) + [Docker Desktop](https://www.docker.com/products/docker-desktop/)

```bash
git clone <repo-url> QRpass
cd QRpass
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
# 1. Set up Supabase credentials (see Supabase Setup section)
cp backend/.env.example backend/.env
# Edit backend/.env with your Supabase connection string

# 2. Install dependencies (runs automatically via postCreateCommand)
cd backend && npm install
cd ../flutter_app && flutter pub get

# 3. Run database migrations
cd ../backend
npx knex migrate:latest
npx knex seed:run

# 4. Start development
# Terminal 1 — Backend
npm run dev

# Terminal 2 — Flutter app
cd ../flutter_app
flutter run
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
git clone <repo-url> QRpass
cd QRpass

# Backend
cd backend
copy .env.example .env
npm install

# Flutter app
cd ..\flutter_app
flutter pub get
```

#### Configure Environment

Edit `backend\.env` with your Supabase credentials (see [Supabase Setup](#supabase-setup)).

#### Run Migrations

```powershell
cd backend
npx knex migrate:latest --knexfile knexfile.js
npx knex seed:run --knexfile knexfile.js
```

#### Start Development

Open **two terminals**:

```powershell
# Terminal 1 — Backend API
cd backend
npm run dev

# Terminal 2 — Flutter App
cd flutter_app
flutter run
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
git clone <repo-url> QRpass
cd QRpass

# Backend
cd backend
cp .env.example .env
npm install

# Flutter app
cd ../flutter_app
flutter pub get
```

#### Run Migrations

```bash
cd ../backend
npx knex migrate:latest
npx knex seed:run
```

#### Start Development

```bash
# Terminal 1
cd backend && npm run dev

# Terminal 2
cd flutter_app && flutter run
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
git clone <repo-url> QRpass
cd QRpass

cd backend && cp .env.example .env && npm install
cd ../flutter_app && flutter pub get
```

#### Run Migrations & Start

```bash
cd ../backend
npx knex migrate:latest
npx knex seed:run
npm run dev
# In another terminal:
cd flutter_app && flutter run
```

---

## Supabase Setup

Quickpass uses **Supabase** for its PostgreSQL database. No local PostgreSQL is needed.

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

Replace the placeholder in `backend/.env`:

```env
DB_CONNECTION=postgresql://postgres:YOUR_PASSWORD@db.YOUR_REF.supabase.co:5432/postgres
DB_SSL=true
```

### Step 4: Run Migrations

```bash
cd backend
npx knex migrate:latest
npx knex seed:run
```

### Step 5: Verify

```bash
# Check that tables were created (optional)
psql "$DB_CONNECTION" -c "\dt"
```

---

## Project Structure

```
QRpass/
├── .devcontainer/
│   ├── devcontainer.json      # VS Code dev container config
│   └── Dockerfile             # Container image (Node, Flutter, .NET, Docker CLI)
├── backend/
│   ├── src/
│   │   ├── app.js             # Express app entry point
│   │   ├── config/            # DB, Firebase configuration
│   │   ├── controllers/       # Route handlers (auth, leave, supervisor, scan, admin)
│   │   ├── middleware/        # Auth, validation, error handling
│   │   ├── routes/            # Express route definitions
│   │   └── services/          # QR generation, push notifications
│   ├── knexfile.js            # DB connection config
│   ├── Dockerfile             # Production container
│   └── .env.example           # Environment template
├── flutter_app/
│   └── lib/
│       ├── main.dart          # App entry point with MultiProvider
│       ├── config/            # Theme (Quickpass branding), app config
│       ├── models/            # Employee, LeaveRequest, ScanLog
│       ├── providers/         # Auth, Leave, Supervisor, Scan state
│       ├── services/          # API, Auth, QR, Notification services
│       ├── screens/
│       │   ├── auth/          # Login, Splash
│       │   ├── employee/      # Dashboard, Request Leave, History, QR Display
│       │   ├── supervisor/    # Dashboard, Pending Requests, Approve/Reject
│       │   └── security/      # QR Scanner, Scan Result
│       ├── widgets/           # StatusBadge, QrCodeWidget, LoadingIndicator
│       └── utils/             # Validators, DateFormatter, Constants
├── database/
│   ├── migrations/            # Knex migration files (6 tables)
│   └── seeds/                 # Sample data (8 departments, 10 employees)
├── assets/
│   └── brand/                 # Logo and icon SVGs
├── docker-compose.yml         # Production services (backend)
└── README.md                  # You are here
```

---

## Environment Variables

### `backend/.env`

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | API server port | `3000` |
| `NODE_ENV` | Environment | `development` |
| `DB_CONNECTION` | Supabase PostgreSQL connection string | *(required)* |
| `DB_SSL` | Enable SSL for DB connection | `true` |
| `JWT_SECRET` | JWT signing secret | *(change in production)* |
| `JWT_EXPIRES_IN` | Token expiration | `24h` |
| `SESSION_EXPIRES_IN` | Session duration | `7d` |
| `QR_SECRET` | QR code HMAC signing secret | *(change in production)* |
| `QR_VALIDITY_WINDOW_MINUTES` | QR code validity window | `15` |
| `FCM_*` | Firebase Cloud Messaging credentials | *(optional)* |

---

## Available Commands

### Backend

| Command | Description |
|---------|-------------|
| `npm run dev` | Start API in watch mode (nodemon) |
| `npm start` | Start API in production |
| `npm test` | Run tests (Jest) |
| `npm run migrate` | Run database migrations |
| `npm run migrate:rollback` | Rollback last migration |
| `npm run seed` | Seed database with sample data |

### Flutter

| Command | Description |
|---------|-------------|
| `flutter run` | Run on connected device |
| `flutter test` | Run tests |
| `flutter build apk` | Build release APK |
| `flutter build appbundle` | Build Android App Bundle |

### Database

| Command | Description |
|---------|-------------|
| `npx knex migrate:latest` | Apply all pending migrations |
| `npx knex migrate:rollback` | Rollback last batch |
| `npx knex seed:run` | Insert sample data |

---

## Architecture Overview

```
┌────────────────┐     REST/JSON     ┌──────────────────┐     SQL      ┌─────────────┐
│  Flutter App   │ ◄──────────────►  │  Node.js API     │ ◄──────────► │  Supabase   │
│  (Android)     │    JWT Auth        │  (Express)       │   Knex.js    │  PostgreSQL │
│                │                    │                  │              │             │
│ • Employee UI  │                    │ • Controllers    │              │ • Employees │
│ • Supervisor   │                    │ • QR Service     │              │ • Leave Req │
│ • QR Scanner   │                    │ • Push Notifs    │              │ • Scan Logs │
│ • QR Display   │                    │ • Auth (JWT)     │              │             │
└────────────────┘                    └────────┬─────────┘              └─────────────┘
                                               │
                                               ▼
                                      ┌──────────────────┐
                                      │  Firebase Cloud   │
                                      │  Messaging        │
                                      │  (Push Notifs)    │
                                      └──────────────────┘
```

### Workflow

1. **Employee** requests leave → status: `pending`
2. **Supervisor** approves → QR codes generated (OUT + IN)
3. **Security** scans OUT QR at exit → status: `active`
4. **Security** scans IN QR at entry → status: `completed`

QR codes are valid ±15 minutes from the scheduled time and use HMAC-SHA256 signing to prevent tampering. Each QR is one-time use.

---

## API Endpoints

### Auth
| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/auth/login` | Login with employee ID + password |
| POST | `/api/auth/logout` | Invalidate session |
| POST | `/api/auth/refresh` | Refresh JWT token |
| GET | `/api/auth/profile` | Get current user profile |
| PUT | `/api/auth/fcm-token` | Update FCM push token |

### Leave Requests
| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/leave/request` | Submit new leave request |
| GET | `/api/leave/history` | Get user's leave history |
| GET | `/api/leave/active` | Get current active leave |
| GET | `/api/leave/:id` | Get leave by ID |

### Supervisor
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/supervisor/pending` | Pending requests (department-scoped) |
| POST | `/api/supervisor/approve/:leaveId` | Approve and generate QR codes |
| POST | `/api/supervisor/reject/:leaveId` | Reject with reason |
| GET | `/api/supervisor/team-leaves` | Team leave calendar |

### Scanning
| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/scan/validate` | Validate scanned QR code |
| GET | `/api/scan/history` | Scan log history |

### Admin
| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/admin/employees` | List employees (search/filter) |
| POST | `/api/admin/employees` | Create employee |
| PUT | `/api/admin/employees/:id` | Update employee |
| PUT | `/api/admin/employees/:id/supervisor` | Toggle supervisor status |
| POST | `/api/admin/import/hr` | Bulk import from CSV/HR system |
| GET | `/api/admin/departments` | List departments |
| GET | `/api/admin/reports` | Generate reports |

---

## Brand Identity

<p align="center">
  <img src="assets/brand/icon.svg" alt="Quickpass Icon" width="120" />
</p>

| Element | Value |
|---------|-------|
| **Name** | **Quickpass** — *Pass* + *Lynx* (sharp vision, tracking) |
| **Tagline** | *Smart Gatepass & Leave Management* |
| **Primary** | `#1B2A4A` (Deep Navy) — Trust, security |
| **Secondary** | `#0D9488` (Teal) — Growth, approval |
| **Accent** | `#F59E0B` (Amber) — Warnings, attention |
| **Success** | `#10B981` (Emerald) — Approved, completed |
| **Error** | `#EF4444` (Red) — Rejected, invalid |
| **Font** | [Poppins](https://fonts.google.com/specimen/Poppins) |
| **Icon** | Lynx eye integrated with QR code corner pattern |

---

## Troubleshooting

### General

| Problem | Solution |
|---------|----------|
| `flutter doctor` shows missing Android SDK | Set `ANDROID_HOME` env var and install Android Studio |
| `knex migrate:latest` fails | Check `DB_CONNECTION` in `.env` and that Supabase allows your IP (Settings → Database → Network) |
| `flutter pub get` fails | Ensure you're in the `flutter_app` directory |
| QR scanner not working | Grant camera permission in Android Settings → Apps → Quickpass |
| Backend won't start | Check that port 3000 is free: `lsof -i :3000` |

### Supabase Connection Issues

```
Error: connect ECONNREFUSED db.xxxxx.supabase.co:5432
```

1. Go to **Supabase Dashboard → Project Settings → Database → Network**
2. Add your IP address to the allowlist
3. Ensure `DB_SSL=true` is set in `.env`

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
# Find what's using port 3000
lsof -i :3000
# Kill it or use a different port:
export PORT=3001 && npm run dev
```

---

## Cleanup

When you're done with the project, remove the locally installed SDKs:

### Linux / macOS

```bash
# Remove Android SDK (symlink + real dir)
rm tools/android-sdk
rm -rf ~/.local/share/quickpass-android-sdk

# Remove Flutter SDK
rm -rf tools/flutter

# Remove Gradle build cache (~5GB+)
rm -rf ~/.gradle/caches/

# Optional: remove Dart pub cache (~600MB, shared by all Dart projects)
rm -rf ~/.pub-cache/
```

### Windows (PowerShell)

```powershell
# Remove Flutter SDK
Remove-Item -Recurse -Force tools\flutter

# Remove Android SDK
Remove-Item -Recurse -Force tools\android-sdk
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Android\Sdk"

# Optional: Gradle cache
Remove-Item -Recurse -Force "$env:USERPROFILE\.gradle\caches"

# Optional: Dart pub cache
Remove-Item -Recurse -Force "$env:USERPROFILE\.pub-cache"
```

**What's kept:** All source code (`backend/`, `flutter_app/`, `web/`, `scripts/`, `database/`) stays intact. The setup scripts remain so you can reinstall later with `./scripts/setup.sh`.

---

## License

MIT
