@echo off

:start
ping -n 2 114.114.114.114 | find "TTL=" >nul

if errorlevel 1 (
echo ÀëÏß
rasdial ¿í´øÁ¬½Ó phone pwd

) else (
echo ÔÚÏß
TIMEOUT 60
)
goto:start
