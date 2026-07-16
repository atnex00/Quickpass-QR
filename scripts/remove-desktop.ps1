# ═══════════════════════════════════════════════════════════════════
# Quickpass Desktop Admin — Remove Script (Windows PowerShell)
#
# Removes Rust toolchain, MSVC build tools, Tauri build artifacts,
# and all related caches installed by setup-desktop.ps1.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File scripts/remove-desktop.ps1
#
# ═══════════════════════════════════════════════════════════════════

$ErrorActionPreference = "Stop"

$ProjectDir = Split-Path -Parent $PSScriptRoot

function Write-Log  { Write-Host "  $($args[0])" -ForegroundColor Green }
function Write-Warn { Write-Host "  $($args[0])" -ForegroundColor Yellow }
function Write-Err  { Write-Host "  $($args[0])" -ForegroundColor Red; exit 1 }
function Write-Info { Write-Host "  $($args[0])" -ForegroundColor Cyan }

function Get-FolderSizeMB {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return 0 }
  [math]::Round((Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum / 1MB, 1)
}

# ── Banner ──

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║    Quickpass Desktop Admin — Remove All      ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── 1. Uninstall Rust (toolchains + cargo registry) ──

$rustup = Get-Command "rustup" -ErrorAction SilentlyContinue
$rustupDir = "$env:USERPROFILE\.rustup"
$cargoDir  = "$env:USERPROFILE\.cargo"
$rustupSize = Get-FolderSizeMB $rustupDir
$cargoSize  = Get-FolderSizeMB $cargoDir
$rustTotal  = $rustupSize + $cargoSize

if ($rustup) {
  Write-Info "[1/7] Rust toolchain + registry ($([math]::Round($rustupSize)]MB toolchain + $([math]::Round($cargoSize)]MB registry = $([math]::Round($rustTotal)]MB)"
  Write-Info "  This removes Rust entirely from this machine."
  $response = Read-Host "  Remove? (y/N)"
  if ($response -eq 'y' -or $response -eq 'Y') {
    Write-Info "  Uninstalling Rust toolchain..."
    & rustup self uninstall -y 2>$null
    Write-Log "  Rust toolchain uninstalled"

    if (Test-Path $cargoDir) {
      Write-Info "  Removing Cargo registry cache..."
      Remove-Item -Path $cargoDir -Recurse -Force -ErrorAction SilentlyContinue
      Write-Log "  Cargo registry removed"
    }
    if (Test-Path $rustupDir) {
      Remove-Item -Path $rustupDir -Recurse -Force -ErrorAction SilentlyContinue
    }
  }
} else {
  Write-Log "  [1/7] Rust not installed, skipping"
}

# ── 2. Uninstall Visual Studio Build Tools ──

$vsRoot  = "$env:ProgramFiles\Microsoft Visual Studio\2022\BuildTools"
$vsTemp  = "$env:TEMP\vs_BuildTools.exe"
$vsSize  = Get-FolderSizeMB $vsRoot

if (Test-Path $vsRoot) {
  Write-Info "[2/7] MSVC Build Tools ($([math]::Round($vsSize)]MB)"
  Write-Info "  Uninstalling Visual Studio Build Tools..."
  $uninstaller = Join-Path $vsRoot "common7\IDE\Setup\vs_setup_bootstrapper.exe"
  if (Test-Path $uninstaller) {
    Start-Process -Wait -FilePath $uninstaller -ArgumentList "uninstall --quiet --norestart --wait" -NoNewWindow
  }
  Remove-Item -Path $vsRoot -Recurse -Force -ErrorAction SilentlyContinue
  Write-Log "  MSVC Build Tools uninstalled"
} else {
  Write-Log "  [2/7] MSVC Build Tools not installed, skipping"
}

if (Test-Path $vsTemp) {
  Remove-Item -Path $vsTemp -Force -ErrorAction SilentlyContinue
}

# ── 3. Remove Tauri build cache (target/) ──

$targetDir = Join-Path $ProjectDir "admin-desktop\src-tauri\target"
$targetSize = Get-FolderSizeMB $targetDir

if (Test-Path $targetDir) {
  Write-Info "[3/7] Tauri build cache target/ ($([math]::Round($targetSize)]MB)"
  Remove-Item -Path $targetDir -Recurse -Force -ErrorAction SilentlyContinue
  Write-Log "  target/ removed"
} else {
  Write-Log "  [3/7] target/ not found, skipping"
}

# ── 4. Remove admin-desktop node_modules ──

$nmDir = Join-Path $ProjectDir "admin-desktop\node_modules"
$nmSize = Get-FolderSizeMB $nmDir

if (Test-Path $nmDir) {
  Write-Info "[4/7] admin-desktop node_modules ($([math]::Round($nmSize)]MB)"
  Remove-Item -Path $nmDir -Recurse -Force -ErrorAction SilentlyContinue
  Write-Log "  node_modules removed"
} else {
  Write-Log "  [4/7] node_modules not found, skipping"
}

# ── 5. Remove .cargo/config.toml (linker override) ──

$cargoConfig = Join-Path $ProjectDir "admin-desktop\src-tauri\.cargo\config.toml"
if (Test-Path $cargoConfig) {
  Write-Info "[5/7] Cargo linker config"
  Remove-Item -Path $cargoConfig -Recurse -Force -ErrorAction SilentlyContinue
  Write-Log "  .cargo/config.toml removed"
} else {
  Write-Log "  [5/7] No Cargo config, skipping"
}

# ── 6. Clean VS installer temp files ──

$vsTempDir = "$env:TEMP"
$vsTempFiles = Get-ChildItem $vsTempDir -Filter "*vs_*bootstrapper*" -Directory -ErrorAction SilentlyContinue
$vsTempCount = 0
foreach ($f in $vsTempFiles) {
  Remove-Item -Path $f.FullName -Recurse -Force -ErrorAction SilentlyContinue
  $vsTempCount++
}

Write-Info "[6/7] VS installer temp files"
if ($vsTempCount -gt 0) {
  Write-Log "  $vsTempCount temp directory(s) removed"
} else {
  Write-Log "  None found, skipping"
}

# ── 7. Clean Rust installer temp files ──

$rustInit = "$env:TEMP\rustup-init.exe"
if (Test-Path $rustInit) {
  Write-Info "[7/7] Rust installer download"
  Remove-Item -Path $rustInit -Force -ErrorAction SilentlyContinue
  Write-Log "  rustup-init.exe removed"
} else {
  Write-Log "  [7/7] No Rust installer, skipping"
}

# ── Done ──

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║    All desktop build dependencies removed     ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
