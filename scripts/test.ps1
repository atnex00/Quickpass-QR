param(
  [switch]$PassThru
)

$ErrorActionPreference = "Stop"
$ROOT_DIR = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$ANY_FAILED = $false

function Write-Summary($tier, $result) {
  if ($result -eq 0) {
    Write-Host "  [PASS] $tier"
  } else {
    Write-Host "  [FAIL] $tier" -ForegroundColor Red
    $script:ANY_FAILED = $true
  }
}

$logDir = if ($env:TEMP) { $env:TEMP } else { "/tmp" }

Write-Host ""
Write-Host "=============================="
Write-Host "      Quickpass Test Suite"
Write-Host "=============================="
Write-Host ""

# Backend
Write-Host "Backend tests..."
$backendLog = "$logDir\quickpass-backend-test.log"
Set-Location "$ROOT_DIR\backend"
$result = 0
npm test 2>&1 | Tee-Object -FilePath $backendLog | Out-Null
if ($LASTEXITCODE -ne 0) { $result = 1 }
Write-Summary "Backend" $result

# Web
Write-Host "Web tests..."
$webLog = "$logDir\quickpass-web-test.log"
Set-Location "$ROOT_DIR\web"
$result = 0
npx vitest run 2>&1 | Tee-Object -FilePath $webLog | Out-Null
if ($LASTEXITCODE -ne 0) { $result = 1 }
Write-Summary "Web" $result

# Flutter (optional)
Write-Host "Flutter tests..."
$flutterLog = "$logDir\quickpass-flutter-test.log"
$flutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if ($flutterCmd) {
  Set-Location "$ROOT_DIR\flutter_app"
  $result = 0
  flutter test 2>&1 | Tee-Object -FilePath $flutterLog | Out-Null
  if ($LASTEXITCODE -ne 0) { $result = 1 }
  Write-Summary "Flutter" $result
} else {
  Write-Host "  [SKIP] Flutter (SDK not found)"
}

Set-Location $ROOT_DIR

Write-Host ""
if (-not $ANY_FAILED) {
  Write-Host "=============================="
  Write-Host "      All tests passed"
  Write-Host "=============================="
} else {
  Write-Host "=============================="
  Write-Host "      Some tests failed"
  Write-Host "=============================="
  Write-Host ""
  Write-Host "Check log files for details:"
  Write-Host "  Backend:  $backendLog"
  Write-Host "  Web:      $webLog"
  Write-Host "  Flutter:  $flutterLog"
}

if (-not $PassThru) { exit [int]$ANY_FAILED }
