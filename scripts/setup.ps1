# ═══════════════════════════════════════════════════════════════════
# Quickpass Setup Script — Windows (PowerShell)
#
# Installs system dependencies and optionally Android SDK + Flutter
# inside the project's tools/ directory. No system-wide installs,
# no Android Studio needed.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File scripts/setup.ps1
#
# You'll be prompted whether to install mobile SDKs. Answer 'n' if
# you're only working on the web frontend (web/).
#
# ═══════════════════════════════════════════════════════════════════

$ErrorActionPreference = "Stop"

$ProjectDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$ToolsDir = Join-Path $ProjectDir "tools"
$AndroidSdkDir = Join-Path $ToolsDir "android-sdk"
$FlutterDir = Join-Path $ToolsDir "flutter"
$CmdlineToolsDir = Join-Path $AndroidSdkDir "cmdline-tools\latest"

# Colors via Write-Host
function Write-Log  { Write-Host "  $($args[0])" -ForegroundColor Green }
function Write-Warn { Write-Host "  $($args[0])" -ForegroundColor Yellow }
function Write-Err  { Write-Host "  $($args[0])" -ForegroundColor Red; exit 1 }
function Write-Info { Write-Host "  $($args[0])" -ForegroundColor Cyan }

# ── Banner ──

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║     Quickpass Environment Setup              ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Info "Project: $ProjectDir"
Write-Host ""

# ── System Dependencies ──

Write-Info "Checking system dependencies..."

$Missing = @()

# Check curl
if (-not (Get-Command "curl" -ErrorAction SilentlyContinue)) {
    $Missing += "curl"
}

# Check git
if (-not (Get-Command "git" -ErrorAction SilentlyContinue)) {
    $Missing += "git"
}

# Check Java 17+
$JavaOk = $false
$JavaCmd = Get-Command "java" -ErrorAction SilentlyContinue
if ($JavaCmd) {
    $JavaVer = (& java -version 2>&1) -join "`n"
    if ($JavaVer -match '"(\d+)') {
        $JavaOk = [int]$Matches[1] -ge 17
    }
}

if (-not $JavaOk) {
    $Missing += "java (17+)"
}

if ($Missing.Count -gt 0) {
    Write-Warn " Missing dependencies: $($Missing -join ', ')"
    Write-Host ""
    Write-Warn " Install the following manually:"
    Write-Warn "   - Java 17+: https://adoptium.net/temurin/releases/?version=17"
    Write-Warn "   - curl:    bundled in Windows 10/11"
    Write-Warn "   - git:     https://git-scm.com/download/win"
    Write-Host ""
    Write-Warn " After installing, re-run this script."
    exit 1
}

# Download 7-Zip portable if not found
if (-not (Get-Command "7z" -ErrorAction SilentlyContinue)) {
    Write-Info "7-Zip not found. Downloading portable version..."
    $7zUrl = "https://www.7-zip.org/a/7zr.exe"
    $7zPath = "$env:TEMP\7zr.exe"
    curl.exe -fsSL $7zUrl -o $7zPath
    $env:Path += ";$env:TEMP"
    Write-Log "7-Zip portable downloaded"
}

Write-Log "All system dependencies found"
Write-Host ""

# ── Prompt for mobile SDKs ──

Write-Host "  ── Mobile Development ─────────────────────────" -ForegroundColor Cyan
Write-Host ""
Write-Info "This project includes a Flutter Android app in flutter_app/."
Write-Info "If you only need the web frontend (web/), you can skip this."
Write-Host ""
$Reply = Read-Host " ? Install Android SDK + Flutter SDK for mobile development? [y/N] "

if ($Reply -notmatch '^[yY]') {
    Write-Host ""
    Write-Log "Skipped mobile SDKs."
    Write-Info "To install them later, re-run with:  .\scripts\setup.ps1"
    Write-Host ""
    exit 0
}

# ── Android SDK ──

Write-Host ""
Write-Info "Setting up Android SDK..."

New-Item -ItemType Directory -Path $CmdlineToolsDir -Force | Out-Null

if (Test-Path "$CmdlineToolsDir\bin\sdkmanager.bat") {
    Write-Log "cmdline-tools already installed"
} else {
    Write-Info "Downloading Android command-line tools..."
    $CmdlineUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
    $CmdlineZip = "$env:TEMP\cmdline-tools.zip"

    curl.exe -fsSL $CmdlineUrl -o $CmdlineZip
    Expand-Archive -Path $CmdlineZip -DestinationPath "$env:TEMP\cmdline-tools-extracted" -Force
    Move-Item -Path "$env:TEMP\cmdline-tools-extracted\cmdline-tools\*" -Destination $CmdlineToolsDir -Force
    Remove-Item -Path $CmdlineZip -Force
    Remove-Item -Path "$env:TEMP\cmdline-tools-extracted" -Recurse -Force
    Write-Log "cmdline-tools installed"
}

$env:ANDROID_HOME = $AndroidSdkDir
$SdkManager = "$CmdlineToolsDir\bin\sdkmanager.bat"

Write-Info "Accepting Android licenses..."
Start-Process -FilePath $SdkManager -ArgumentList "--licenses" -NoNewWindow -Wait 2>&1 | Out-Null
Write-Log "Licenses accepted"

Write-Info "Installing Android SDK platform and build tools..."
Start-Process -FilePath $SdkManager -ArgumentList "platforms;android-34", "build-tools;34.0.0" -NoNewWindow -Wait
Write-Log "Android SDK platform (34) and build-tools installed"

# Write local.properties for the Flutter project
$Props = Join-Path $ProjectDir "flutter_app\android\local.properties"
"sdk.dir=$AndroidSdkDir" | Out-File -FilePath $Props -Encoding ASCII
Write-Log "local.properties written"

# ── Flutter SDK ──

Write-Host ""
Write-Info "Setting up Flutter SDK..."

if (Test-Path "$FlutterDir\bin\flutter.bat") {
    Write-Log "Flutter SDK already installed"
} else {
    Write-Info "Downloading Flutter SDK..."
    $FlutterUrl = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.27.1-stable.zip"
    $FlutterZip = "$env:TEMP\flutter.zip"

    curl.exe -fsSL $FlutterUrl -o $FlutterZip
    Expand-Archive -Path $FlutterZip -DestinationPath $ToolsDir -Force
    Remove-Item -Path $FlutterZip -Force
    Write-Log "Flutter SDK installed at $FlutterDir"
}

$env:Path += ";$FlutterDir\bin"
$env:ANDROID_HOME = $AndroidSdkDir

flutter config --android-sdk "$AndroidSdkDir" 2>$null
Write-Log "Flutter configured to use project SDK"

flutter precache --android 2>$null | Out-Null

# ── Verify ──

Write-Host ""
Write-Host "  ── Verification ──────────────────────────────" -ForegroundColor Cyan
Write-Host ""

$env:Path += ";$FlutterDir\bin"
flutter doctor 2>&1

Write-Host ""
Write-Log "Setup complete."
Write-Info "To build the APK:  cd flutter_app && flutter build apk"
Write-Host ""
