@echo off
echo Opening in Microsoft Edge...
start msedge http://localhost:{{PORT}}
echo.
echo URL: http://localhost:{{PORT}}
echo.
echo If this doesn't work:
echo   1. Make sure the server is running (double-click start.bat first)
echo   2. Check WSL networking mode: mirrored mode uses localhost, NAT mode uses WSL IP
pause
