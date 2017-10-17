@echo off

:start
ping -n 2 114.114.114.114 | find "TTL=" >nul

if errorlevel 1 (
echo 离线
rasdial 宽带连接 05510740672 666888

) else (
echo 在线
TIMEOUT 60
)
goto:start
