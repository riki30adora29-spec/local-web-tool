@echo off
chcp 65001 >nul
echo ========================================
echo   {{PROJECT_NAME}} — 一键启动
echo ========================================
echo.

echo [1/2] 启动后端服务...
:: ⚠️  WSL bash -c 是非交互 shell，不动 ~/.bashrc。如果 node 在 ~/.local/bin 下，
::     需要用完整路径替代 `node`，例如 /home/user/.local/bin/node
::     检测方法: 进 WSL 运行 `which node` 看输出
start "{{PROJECT_NAME}}-后端" /min wsl -d {{WSL_DISTRO}} -- bash -c "cd {{PROJECT_PATH}} && node server.js"
echo       后端已在 WSL 后台启动，等待就绪...

:: 等 3 秒让服务起来
timeout /t 3 /nobreak >nul

echo [2/2] 打开浏览器...
start http://localhost:{{PORT}}

echo.
echo ========================================
echo   浏览器已打开 → http://localhost:{{PORT}}
echo   关闭本窗口不影响使用
echo   按任意键关闭...
echo ========================================
pause >nul
