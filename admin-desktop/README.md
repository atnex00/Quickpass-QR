# Quickpass Admin — Desktop App

Tauri v2 desktop wrapper for the Quickpass admin control panel.

## Prerequisites

- [Rust](https://rustup.rs) 1.77+ (install via `rustup.rs`)
- Node.js 18+

## Setup

```bash
# Install Node dependencies
cd admin-desktop && npm install

# Build the web frontend first (Tauri bundles web/dist)
cd ../web && npm run build
```

## Development

Run two terminals:

```bash
# Terminal 1 — Vite dev server (hot reload)
cd web && npm run dev

# Terminal 2 — Tauri dev (opens native window)
cd admin-desktop && npm run dev
```

The Tauri window loads `http://localhost:8080` (the Vite dev server) and proxies API calls to `http://localhost:3000`.

## Build

```bash
cd web && npm run build
cd admin-desktop && npm run build
```

Output: `admin-desktop/src-tauri/target/release/bundle/msi/QuickpassAdmin_1.0.0_x64.msi`

## Configuration

The desktop app targets the backend at `http://localhost:3000` by default. To change:

```bash
# Pass via environment variable
QUICKPASS_API_URL=https://api.your-server.com npm run dev
```

Or edit the fallback in `web/src/lib/api.ts`.
