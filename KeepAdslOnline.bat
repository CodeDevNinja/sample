@echo off

:start
ping -n 2 114.114.114.114 | find "TTL=" >nul

if errorlevel 1 (
echo ����
rasdial ������� 05510740672 666888

) else (
echo ����
TIMEOUT 60
)
goto:start
