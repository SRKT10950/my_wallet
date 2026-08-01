# My Wallet Local PWA Server Bootstrapper (PowerShell)
Write-Host "=============================================================" -ForegroundColor Green
Write-Host "            My Wallet PWA Local Web Server                  " -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Green
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Building Web PWA..." -ForegroundColor Yellow
Set-Location "$ScriptDir"
flutter build web --release

Write-Host ""
Write-Host "Starting Web Server on http://localhost:8080 ..." -ForegroundColor Cyan
Set-Location "$ScriptDir\build\web"
python -m http.server 8080
