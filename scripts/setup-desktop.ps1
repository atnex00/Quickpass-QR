# ═══════════════════════════════════════════════════════════════════
# Quickpass Desktop Admin — Setup Script (Windows PowerShell)
#
# Installs Rust toolchain and MSVC build tools needed to compile
# the Tauri v2 desktop wrapper for the admin control panel.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File scripts/setup-desktop.ps1
#
# ═══════════════════════════════════════════════════════════════════

$ErrorActionPreference = "Stop"

$ProjectDir = Split-Path -Parent $PSScriptRoot

function Write-Log  { Write-Host "  $($args[0])" -ForegroundColor Green }
function Write-Warn { Write-Host "  $($args[0])" -ForegroundColor Yellow }
function Write-Err  { Write-Host "  $($args[0])" -ForegroundColor Red; exit 1 }
function Write-Info { Write-Host "  $($args[0])" -ForegroundColor Cyan }

# ── Banner ──

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║    Quickpass Desktop Admin — Setup           ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── 1. Check WebView2 ──

Write-Info "[1/4] Checking WebView2..."
$webview = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" -Name "pv" -ErrorAction SilentlyContinue
if ($webview) {
  Write-Log "  WebView2 already installed (version $($webview.pv))"
} else {
  Write-Warn "  WebView2 not found. Downloading..."
  $url = "https://go.microsoft.com/fwlink/p/?LinkId=2124703"
  $installer = "$env:TEMP\MicrosoftEdgeWebview2Setup.exe"
  Invoke-WebRequest -Uri $url -OutFile $installer
  Start-Process -Wait -FilePath $installer -ArgumentList "/silent /install"
  Write-Log "  WebView2 installed"
}

# ── 2. Install Rust ──

Write-Info "[2/4] Checking Rust toolchain..."
$rustc = Get-Command "rustc" -ErrorAction SilentlyContinue
if ($rustc) {
  $ver = & rustc --version
  Write-Log "  Rust already installed: $ver"
} else {
  Write-Warn "  Rust not found. Installing via rustup..."
  $url = "https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe"
  $installer = "$env:TEMP\rustup-init.exe"
  Invoke-WebRequest -Uri $url -OutFile $installer
  Start-Process -Wait -FilePath $installer -ArgumentList "-y --default-toolchain stable"
  $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
  Write-Log "  Rust installed: $(rustc --version)"
}

# ── 3. Install MSVC Build Tools ──

Write-Info "[3/4] Checking MSVC build tools..."
$cl = Get-Command "cl" -ErrorAction SilentlyContinue
if ($cl) {
  Write-Log "  MSVC build tools already available"
} else {
  Write-Warn "  MSVC build tools not found. Installing Visual Studio Build Tools..."
  Write-Warn "  This downloads ~1 GB and may take several minutes."
  $url = "https://aka.ms/vs/17/release/vs_BuildTools.exe"
  $installer = "$env:TEMP\vs_BuildTools.exe"
  Invoke-WebRequest -Uri $url -OutFile $installer
  $workloadArgs = "--installPath `"$env:ProgramFiles\Microsoft Visual Studio\2022\BuildTools`" --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --quiet --norestart --wait"
  Start-Process -Wait -FilePath $installer -ArgumentList $workloadArgs
  Write-Log "  MSVC build tools installed"
}

# ── 4. Install admin-desktop npm deps ──

Write-Info "[4/4] Installing npm dependencies..."
Push-Location (Join-Path $ProjectDir "admin-desktop")
npm install
if ($LASTEXITCODE -ne 0) { Write-Err "npm install failed" }
Pop-Location
Write-Log "  npm dependencies installed"

# ── Done ──

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║    Setup complete!                            ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Log "  Build the desktop app:"
Write-Log "    npm run desktop:build"
Write-Log ""
Write-Log "  Or run in development mode (two terminals):"
Write-Log "    npm run dev:web"
Write-Log "    npm run desktop:dev"
Write-Host ""
