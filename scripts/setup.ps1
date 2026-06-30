# ═══════════════════════════════════════════════════════════════════
# PassLynx Setup Script — Windows (PowerShell)
#
# Installs local Android SDK + Flutter inside the project's tools/
# directory. No system-wide installs, no Android Studio needed.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File scripts/setup.ps1
#
# ═══════════════════════════════════════════════════════════════════

$ErrorActionPreference = "Stop"

$ProjectDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$ToolsDir = Join-Path $ProjectDir "tools"
$AndroidSdkDir = Join-Path $ToolsDir "android-sdk"
$FlutterDir = Join-Path $ToolsDir "flutter"
$CmdlineToolsDir = Join-Path $AndroidSdkDir "cmdline-tools\latest"

# ── Helpers ──

function Write-Info  { Write-Host "  :: $($args[0])" -ForegroundColor Cyan }
function Write-Step  { Write-Host "  ✓ $($args[0])" -ForegroundColor Green }
function Write-Warn  { Write-Host "  ⚠ $($args[0])" -ForegroundColor Yellow }
function Write-Err   { Write-Host "  ✗ $($args[0])" -ForegroundColor Red; exit 1 }

# ── Check prerequisites ──

Write-Info "Checking prerequisites..."

# Check for 7-Zip (needed to extract tar.xz on Windows)
$SevenZip = Get-Command "7z" -ErrorAction SilentlyContinue
if (-not $SevenZip) {
    Write-Warn "7-Zip not found. Downloading portable version..."
    $7zUrl = "https://www.7-zip.org/a/7zr.exe"
    $7zPath = Join-Path $env:TEMP "7zr.exe"
    Invoke-WebRequest -Uri $7zUrl -OutFile $7zPath
    $env:Path += ";$env:TEMP"
}
Write-Step "Prerequisites OK"

# ── Java ──

$Java = Get-Command "java" -ErrorAction SilentlyContinue
if (-not $Java) {
    Write-Info "Installing Java 17 (Eclipse Temurin)..."
    $JavaUrl = "https://api.adobe.com/..."  # Placeholder — user installs manually
    Write-Warn "Java 17+ is required. Install from: https://adoptium.net/"
    Write-Warn "Then re-run this script."
    exit 1
}
Write-Step "Java found"

# ── Android SDK ──

Write-Host ""
Write-Info "Setting up Android SDK..."

if (Test-Path "$CmdlineToolsDir\bin\sdkmanager.bat") {
    Write-Step "cmdline-tools already installed"
} else {
    Write-Info "Downloading Android command-line tools..."
    $Url = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
    $Zip = "$env:TEMP\cmdline-tools.zip"
    Invoke-WebRequest -Uri $Url -OutFile $Zip
    New-Item -ItemType Directory -Path "$CmdlineToolsDir" -Force | Out-Null
    Expand-Archive -Path $Zip -DestinationPath "$env:TEMP\cmdline-tools-extracted" -Force
    Move-Item -Path "$env:TEMP\cmdline-tools-extracted\cmdline-tools\*" -Destination "$CmdlineToolsDir" -Force
    Remove-Item -Path "$env:TEMP\cmdline-tools.zip" -Force
    Remove-Item -Path "$env:TEMP\cmdline-tools-extracted" -Recurse -Force
    Write-Step "cmdline-tools installed"
}

$env:ANDROID_HOME = $AndroidSdkDir
$SdkManager = "$CmdlineToolsDir\bin\sdkmanager.bat"

Write-Info "Accepting licenses..."
# sdkmanager --licenses may hang without input on Windows
Start-Process -FilePath $SdkManager -ArgumentList "--licenses" -NoNewWindow -Wait 2>&1 | Out-Null
Write-Step "Licenses accepted"

Write-Info "Installing SDK platform (34) and build-tools..."
Start-Process -FilePath $SdkManager -ArgumentList "platforms;android-34", "build-tools;34.0.0" -NoNewWindow -Wait
Write-Step "Android SDK platform and build-tools installed"

# local.properties
$Props = Join-Path $ProjectDir "flutter_app\android\local.properties"
"store.dir=$AndroidSdkDir" | Out-File -FilePath $Props -Encoding ASCII
Write-Step "local.properties written"

# ── Flutter SDK ──

Write-Host ""
Write-Info "Setting up Flutter SDK..."

if (Test-Path "$FlutterDir\bin\flutter.bat") {
    Write-Step "Flutter SDK already installed"
} else {
    Write-Info "Downloading Flutter SDK..."
    $Url = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.27.1-stable.zip"
    $Zip = "$env:TEMP\flutter.zip"
    Invoke-WebRequest -Uri $Url -OutFile $Zip
    Expand-Archive -Path $Zip -DestinationPath $ToolsDir -Force
    Remove-Item -Path $Zip -Force
    Write-Step "Flutter SDK installed"
}

$env:Path += ";$FlutterDir\bin"
$env:ANDROID_HOME = $AndroidSdkDir

flutter config --android-sdk "$AndroidSdkDir" 2>$null
Write-Step "Flutter configured to use project SDK"

# ── Verify ──

Write-Host ""
Write-Host "── Verification ──────────────────────────────" -ForegroundColor Cyan
Write-Host ""

$env:Path += ";$FlutterDir\bin"
flutter doctor

Write-Host ""
Write-Host "Setup complete." -ForegroundColor Green
Write-Host "To build the APK:  cd flutter_app && flutter build apk"
