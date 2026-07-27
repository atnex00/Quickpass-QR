# ============================================================
# Quickpass Release Builder - Windows (PowerShell)
#
# Builds a production APK with version from git + build number.
#
# Usage:
#   .\scripts\build_release.ps1          # APK (default)
#   .\scripts\build_release.ps1 -Type appbundle  # AAB
#   .\scripts\build_release.ps1 -Type apk        # APK explicitly
#
# Prerequisites:
#   - Run .\scripts\setup.ps1 first
#   - Create flutter_app\env.prod.json with your API URL
#   - Have a signing keystore ready for Play Store release
# ============================================================

param(
    [ValidateSet("apk", "appbundle")]
    [string]$Type = "apk"
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $PSCommandPath
$ProjectDir = Split-Path -Parent $ScriptDir
$FlutterApp = Join-Path $ProjectDir "flutter_app"

# -- Helper --
function Write-Log  { Write-Host "  $($args[0])" -ForegroundColor Green }
function Write-Info { Write-Host "  $($args[0])" -ForegroundColor Cyan }
function Write-Err  { Write-Host "  $($args[0])" -ForegroundColor Red; exit 1 }

# -- Derive version from git --
Push-Location $ProjectDir
$gitTag = git describe --tags --always 2>$null
$gitCommits = git rev-list --count HEAD 2>$null
Pop-Location

if (-not $gitCommits) { $gitCommits = "1" }
$buildNumber = [int]$gitCommits

# Use tag as version name (e.g. v1.2.3), fall back to 1.0.0
$versionName = if ($gitTag -match '^v?(\d+\.\d+\.\d+)') { $matches[1] } else { "1.0.0" }

Write-Host ""
Write-Host "  +------------------------------------------+" -ForegroundColor Cyan
Write-Host "  |   Quickpass - Release Builder             |" -ForegroundColor Cyan
Write-Host "  +------------------------------------------+" -ForegroundColor Cyan
Write-Host ""
Write-Info "Version:     $versionName+$buildNumber"
Write-Info "Build type:  $Type"
Write-Info "Flutter app: $FlutterApp"
Write-Host ""

# -- Determine Flutter path --
$Properties = Join-Path $FlutterApp "android\local.properties"
$FlutterDir = $null
if (Test-Path $Properties) {
    $lines = Get-Content $Properties
    foreach ($line in $lines) {
        if ($line -match "^flutter\.sdk=(.+)") { $FlutterDir = $matches[1]; break }
    }
}
if (-not $FlutterDir) { $FlutterDir = Join-Path $ProjectDir "tools\flutter" }
$Flutter = Join-Path $FlutterDir "bin\flutter.bat"
if (-not (Test-Path $Flutter)) {
    Write-Err "Flutter not found at $FlutterDir. Run .\scripts\setup.ps1"
}

# -- Check env.prod.json --
$EnvFile = Join-Path $FlutterApp "env.prod.json"
if (-not (Test-Path $EnvFile)) {
    Write-Warn "env.prod.json not found at $EnvFile"
    Write-Warn "Creating default (update your API URL before building)"
    @{ "API_BASE_URL" = "http://localhost:3000/api" } | ConvertTo-Json | Set-Content $EnvFile
}

# -- Build --
Push-Location $FlutterApp
try {
    Write-Info "Building $Type..."
    Write-Host ""

    & $Flutter build $Type `
        --dart-define-from-file=env.prod.json `
        --build-name=$versionName `
        --build-number=$buildNumber

    if ($LASTEXITCODE -eq 0) {
        Write-Log "Build succeeded!"
        $outputDir = Join-Path $FlutterApp "build\app\outputs\flutter-apk"
        if ($Type -eq "appbundle") { $outputDir = Join-Path $FlutterApp "build\app\outputs\bundle\release" }
        Write-Log "Output: $outputDir"
    } else {
        Write-Err "Build failed"
    }
} finally {
    Pop-Location
}
