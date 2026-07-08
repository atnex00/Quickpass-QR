# ═══════════════════════════════════════════════════════════════════
# Quickpass Uninstall Script — Windows (PowerShell)
#
# Removes project-local Android SDK + Flutter SDK installed
# by setup.ps1, and cleans up generated files.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File scripts\uninstall.ps1
#
# ═══════════════════════════════════════════════════════════════════

$ErrorActionPreference = "Stop"

$ProjectDir = Split-Path -Parent $PSScriptRoot
$ToolsDir = Join-Path $ProjectDir "tools"
$LocalProps = Join-Path $ProjectDir "flutter_app\android\local.properties"

# Colors via Write-Host
function Write-Log  { Write-Host "  $($args[0])" -ForegroundColor Green }
function Write-Warn { Write-Host "  $($args[0])" -ForegroundColor Yellow }
function Write-Err  { Write-Host "  $($args[0])" -ForegroundColor Red; exit 1 }
function Write-Info { Write-Host "  $($args[0])" -ForegroundColor Cyan }

# ── Banner ──

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║     Quickpass Environment Cleanup            ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

$HasTools = Test-Path $ToolsDir
$HasProps = Test-Path $LocalProps

if (-not $HasTools -and -not $HasProps) {
    Write-Warn "Nothing to uninstall — no project-local SDKs found."
    Write-Host ""
    exit 0
}

if ($HasTools) {
    Write-Info "Will remove:  $ToolsDir"
}
if ($HasProps) {
    Write-Info "Will remove:  $LocalProps"
}

Write-Host ""
$Reply = Read-Host " ? Remove all project-local SDKs and generated files? [y/N] "

if ($Reply -notmatch '^[yY]') {
    Write-Log "Cancelled."
    exit 0
}

# ── Remove tools/ ──

if ($HasTools) {
    Write-Host ""
    Write-Info "Removing $ToolsDir ..."
    try {
        Remove-Item -LiteralPath $ToolsDir -Recurse -Force -ErrorAction Stop
        Write-Log "Removed tools/"
    } catch {
        Write-Warn "Could not fully remove tools/ (some files may be in use): $_"
    }
}

# ── Remove local.properties ──

if ($HasProps) {
    Write-Host ""
    Write-Info "Removing $LocalProps ..."
    Remove-Item -LiteralPath $LocalProps -Force -ErrorAction SilentlyContinue
    Write-Log "Removed local.properties"
}

# ── Done ──

Write-Host ""
Write-Log "Cleanup complete."
Write-Info "System-wide installations (Java, Git, etc.) are not affected."
Write-Host ""
