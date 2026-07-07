# ═══════════════════════════════════════════════════════════════════
# ZANECO QuickPass — Database Setup Script (Windows)
#
# Creates the PostgreSQL database, runs migrations, seeds data,
# and optionally creates an admin user.
#
# Usage:
#   .\scripts\setup_db.ps1                    # uses .env.dev
#   $env:NODE_ENV="production"; .\scripts\setup_db.ps1
#
# ═══════════════════════════════════════════════════════════════════

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $PSCommandPath
$ProjectDir = Split-Path -Parent $ScriptDir
$BackendDir = Join-Path $ProjectDir "backend"

# ── Colors ──
function Write-Log  { Write-Host "  $($args[0])" -ForegroundColor Green }
function Write-Warn { Write-Host "  $($args[0])" -ForegroundColor Yellow }
function Write-Err  { Write-Host "  $($args[0])" -ForegroundColor Red; exit 1 }
function Write-Info { Write-Host "  $($args[0])" -ForegroundColor Cyan }

# ── Load env ──

$NodeEnv = if ($env:NODE_ENV) { $env:NODE_ENV } else { "development" }
$EnvFile = Join-Path $BackendDir ".env.$NodeEnv"

if ($NodeEnv -eq "development" -and -not (Test-Path $EnvFile)) {
    $EnvFile = Join-Path $BackendDir ".env.dev"
}

if (-not (Test-Path $EnvFile)) {
    Write-Err "Environment file not found: $EnvFile"
}

$DbConnection = (Get-Content $EnvFile | Select-String "^DB_CONNECTION=") -replace "^DB_CONNECTION=", ""
$DbConnection = $DbConnection.Trim('"', "'")

if (-not $DbConnection) {
    Write-Err "DB_CONNECTION not found in $EnvFile"
}

# ── Parse connection string ──
# postgresql://user:password@host:port/database

$Pattern = '^postgresql://([^:]+):([^@]+)@([^:]+):([0-9]+)/(.+)$'
$Match = [regex]::Match($DbConnection, $Pattern)

if (-not $Match.Success) {
    # Try without port
    $Pattern = '^postgresql://([^:]+):([^@]+)@([^/]+)/(.+)$'
    $Match = [regex]::Match($DbConnection, $Pattern)
    if (-not $Match.Success) {
        Write-Err "Cannot parse DB_CONNECTION string: $DbConnection"
    }
    $DbPort = "5432"
} else {
    $DbPort = $Match.Groups[4].Value
}

$DbUser    = $Match.Groups[1].Value
$DbPass    = $Match.Groups[2].Value
$DbHost    = $Match.Groups[3].Value
$DbName    = $Match.Groups[$Match.Groups.Count - 1].Value

Write-Log "Environment:   $NodeEnv"
Write-Log "Host:          $DbHost`:$DbPort"
Write-Log "Database:      $DbName"
Write-Log "User:          $DbUser"
Write-Host ""

# ── Check PostgreSQL ──

Write-Info "Checking PostgreSQL connection..."
$env:PGPASSWORD = $DbPass

$TestQuery = & psql -h $DbHost -p $DbPort -U $DbUser -d postgres -c "SELECT 1" 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Log "PostgreSQL is running"
} else {
    Write-Err "Cannot connect to PostgreSQL at ${DbHost}:${DbPort}`nMake sure PostgreSQL is installed and running."
}
Write-Host ""

# ── Create database if not exists ──

Write-Info "Checking if database '$DbName' exists..."
$DbExists = & psql -h $DbHost -p $DbPort -U $DbUser -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$DbName'" 2>&1

if ($DbExists.Trim() -eq "1") {
    Write-Log "Database '$DbName' already exists"
} else {
    Write-Info "Creating database '$DbName'..."
    & createdb -h $DbHost -p $DbPort -U $DbUser $DbName
    Write-Log "Database '$DbName' created"
}
Write-Host ""

Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue

# ── Run migrations ──

Write-Info "Running migrations..."
Push-Location $BackendDir
$env:NODE_ENV = "dev"
& npx.cmd knex migrate:latest --knexfile knexfile.js
if ($LASTEXITCODE -ne 0) {
    Pop-Location
    Write-Err "Migrations failed"
}
Pop-Location
Write-Log "Migrations complete"
Write-Host ""

# ── Run seeds ──

Write-Info "Running seeds..."
Push-Location $BackendDir
& npx.cmd knex seed:run --knexfile knexfile.js
if ($LASTEXITCODE -ne 0) {
    Pop-Location
    Write-Err "Seeds failed"
}
Pop-Location
Write-Log "Seeds complete"
Write-Host ""

# ── Admin user prompt ──

Write-Host ""
Write-Host "  ┌────────────────────────────────────────────┐" -ForegroundColor Cyan
Write-Host "  │  Create admin user?                         │" -ForegroundColor Cyan
Write-Host "  └────────────────────────────────────────────┘" -ForegroundColor Cyan
Write-Host ""
Write-Info "Email:    admin@zaneco.ph"
Write-Info "Password: admin123"
Write-Info "ID:       999999"
Write-Host ""
$Reply = Read-Host " ? Create admin user? [Y/n] "
if ($Reply -eq "" -or $Reply -match "^[Yy]") {
    Write-Info "Creating admin user..."
    Push-Location $BackendDir
    $env:NODE_ENV = "dev"
    & node scripts/createAdmin.js
    Pop-Location
    Write-Log "Admin user created"
} else {
    Write-Warn "Skipped admin user creation"
    Write-Warn "Run later:  cd backend && node scripts/createAdmin.js"
}
Write-Host ""

# ── Done ──

Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║     Database setup complete                  ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Info "Start the backend:  cd backend && npm run dev"
Write-Host ""
