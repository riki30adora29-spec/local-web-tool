@echo off
chcp 65001 >nul
echo 正在关闭后端服务...
wsl -d {{WSL_DISTRO}} -- bash -c "pkill -f 'node server.js' 2>/dev/null; echo '已关闭'"
echo 完成
pause >nul
