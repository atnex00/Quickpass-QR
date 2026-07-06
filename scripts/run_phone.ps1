# ============================================================
# Quickpass Phone Runner - Windows (PowerShell)
#
# Runs the Flutter app on a physical Android device connected via USB,
# with an ADB reverse tunnel so the phone can reach the backend API
# running on this machine.
#
# Prerequisites:
#   1. Run .\scripts\setup.ps1 first (installs Android SDK + Flutter)
#   2. Enable Developer Options & USB Debugging on your phone
#   3. Connect phone via USB and accept the RSA fingerprint
#   4. Make sure the backend is running on port 3000
#
# Usage:
#   .\scripts\run_phone.ps1
#
# ============================================================

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $PSCommandPath
$ProjectDir = Split-Path -Parent $ScriptDir
$Properties = Join-Path $ProjectDir "flutter_app\android\local.properties"

# -- Colors --
function Write-Log  { Write-Host "  $($args[0])" -ForegroundColor Green }
function Write-Warn { Write-Host "  $($args[0])" -ForegroundColor Yellow }
function Write-Err  { Write-Host "  $($args[0])" -ForegroundColor Red; exit 1 }
function Write-Info { Write-Host "  $($args[0])" -ForegroundColor Cyan }

# -- Resolve SDK paths from local.properties --

function Resolve-SdkPath($key, $fallback) {
    if (Test-Path $Properties) {
        $lines = Get-Content $Properties
        foreach ($line in $lines) {
            if ($line -match "^$key=(.+)") {
                return $matches[1]
            }
        }
    }
    return $fallback
}

$AndroidSdkDir = Resolve-SdkPath "sdk.dir" (Join-Path $ProjectDir "tools\android-sdk")
$FlutterDir    = Resolve-SdkPath "flutter.sdk" (Join-Path $ProjectDir "tools\flutter")
$Adb           = Join-Path $AndroidSdkDir "platform-tools\adb.exe"
$Flutter       = Join-Path $FlutterDir "bin\flutter.bat"

# -- Environment --

$env:ANDROID_HOME = $AndroidSdkDir

# Prefer bundled JDK, then system Java
$BundledJdk = Join-Path $ProjectDir "tools\jdk"
if (Test-Path (Join-Path $BundledJdk "bin\javac.exe")) {
    $env:JAVA_HOME = $BundledJdk
}

# -- Check dependencies --

if (-not (Test-Path $Flutter)) {
    Write-Err "Flutter SDK not found at $FlutterDir`n  Run .\scripts\setup.ps1 to install it."
}
if (-not (Test-Path $Adb)) {
    Write-Err "ADB not found at $Adb`n  Run .\scripts\setup.ps1 to install the Android SDK."
}

# -- Find connected device --

$Devices = & $Adb devices | Select-String "device$"
$Device = $null
foreach ($line in $Devices) {
    $parts = $line -split "\s+"
    if ($parts.Count -ge 2 -and $parts[1] -eq "device" -and $parts[0] -ne "List") {
        $Device = $parts[0]
        break
    }
}

if (-not $Device) {
    Write-Host ""
    Write-Err "No Android device detected.`n`n  1. Enable Developer Options on your phone:`n     Settings -> About Phone -> Tap Build Number 7 times`n  2. Enable USB Debugging:`n     Settings -> Developer Options -> USB Debugging`n  3. Connect your phone via USB and accept the RSA prompt`n  4. Verify with: $Adb devices"
}

Write-Host ""
Write-Host "  +------------------------------------------+" -ForegroundColor Cyan
Write-Host "  |   Quickpass - Phone Runner               |" -ForegroundColor Cyan
Write-Host "  +------------------------------------------+" -ForegroundColor Cyan
Write-Host ""
Write-Info "Device:     $Device"
Write-Info "Project:    $ProjectDir"
Write-Host ""

# -- Set up ADB reverse tunnel --

Write-Info "Setting up ADB reverse tunnel (phone:3000 -> host:3000)..."
$TunnelResult = & $Adb reverse tcp:3000 tcp:3000 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Log "ADB reverse tunnel established"
} else {
    Write-Warn "Failed to set up reverse tunnel - is the port already in use?"
}

# -- Cleanup on exit --

try {
    # -- Run --
    Push-Location (Join-Path $ProjectDir "flutter_app")
    Write-Info "Starting Flutter on $Device..."
    Write-Host ""
    & $Flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
} finally {
    Pop-Location
    Write-Info "Cleaning up ADB reverse tunnel..."
    & $Adb reverse --remove tcp:3000 2>&1 | Out-Null
    Write-Log "Done"
}
