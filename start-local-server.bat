@echo off
TITLE mWallet Enterprise Local Server Bootstrapper
echo =============================================================
echo   mWallet Enterprise Local Server (Windows Local Hosting)    
echo =============================================================
echo.
echo Database: mWallet
echo Secret Key: hs_live_8cxzSYAq9aUv79HxDbADCdJ23yLtIWhQ
echo.
echo Starting Backend API Server (Port 4000)...
start "mWallet Backend API (Port 4000)" cmd /k "cd /d %~dp0apps\backend && npm start"

echo Starting Frontend Web App (Port 3000)...
start "mWallet Frontend PWA (Port 3000)" cmd /k "cd /d %~dp0apps\frontend && npm run dev"

echo.
echo =============================================================
echo   Local Server is starting up!                               
echo   - Local Web App Access:   http://localhost:3000            
echo   - Local Network Access:   http://[YOUR-LOCAL-IP]:3000      
echo   - API Health Endpoint:    http://localhost:4000/api/v1/health
echo =============================================================
pause
