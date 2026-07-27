# Quickpass QR — Flutter App

QR-based gate pass and leave management system for employees.

## Features

- **Employee Dashboard** — Submit leave requests, view history, display QR passes
- **Supervisor Dashboard** — Approve/reject pending leave requests from team members
- **Admin Panel** — Manage employees, departments, view reports and analytics
- **QR Scanner** — Scan OUT/IN QR codes at security gates with camera or manual entry
- **Dark Mode** — Full Material 3 light and dark theme support
- **Offline Token** — JWT stored securely with automatic refresh queue

## Tech Stack

- **Framework:** Flutter 3.27+  
- **State:** Provider + ChangeNotifier  
- **HTTP:** Dio with interceptor-based auth and token refresh  
- **QR:** mobile_scanner (scan), qr_flutter (display)  
- **Security:** flutter_secure_storage, certificate pinning (configurable)  
- **Serialization:** json_serializable + build_runner  

## Setup

```bash
cd flutter_app
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Run with the API URL pointing to your backend:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

For a physical device:

```bash
flutter run --dart-define=API_BASE_URL=http://YOUR_IP:3000/api
```

## Commands

| Command | Purpose |
|---|---|
| `flutter run` | Run on connected device |
| `flutter analyze` | Static analysis |
| `flutter test` | Run all tests |
| `flutter test --coverage` | Run tests with coverage |
| `dart run build_runner build` | Generate `.g.dart` files |
| `dart format lib/ test/` | Format all Dart files |

## Architecture

```
lib/
├── config/        — App config, theme, colors
├── models/        — Data models with JSON serialization
├── providers/     — ChangeNotifier state managers
├── screens/       — UI screens (admin, auth, employee, security, supervisor)
├── services/      — API client, QR validation, certificate pinning
├── utils/         — Constants, validators, formatters, debouncer
└── widgets/       — Reusable UI components
```
