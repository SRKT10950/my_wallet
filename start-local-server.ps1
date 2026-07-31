# mWallet Enterprise Local Server Bootstrapper (PowerShell)
Write-Host "=============================================================" -ForegroundColor Green
Write-Host "  mWallet Enterprise Local Server (Windows Local Hosting)    " -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Database: mWallet" -ForegroundColor Yellow
Write-Host "Secret Key: hs_live_8cxzSYAq9aUv79HxDbADCdJ23yLtIWhQ" -ForegroundColor Yellow
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host "Starting Backend API Server (Port 4000)..." -ForegroundColor Cyan
Start-Process cmd -ArgumentList "/k cd /d `"$ScriptDir\apps\backend`" && npm start"

Write-Host "Starting Frontend Web App (Port 3000)..." -ForegroundColor Cyan
Start-Process cmd -ArgumentList "/k cd /d `"$ScriptDir\apps\frontend`" && npm run dev"

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Green
Write-Host "  Local Server is running!" -ForegroundColor Green
Write-Host "  - Local Web App Access:   http://localhost:3000" -ForegroundColor White
Write-Host "  - API Health Endpoint:    http://localhost:4000/api/v1/health" -ForegroundColor White
Write-Host "=============================================================" -ForegroundColor Green
