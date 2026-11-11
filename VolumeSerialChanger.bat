@echo off
title Volume Serial Changer
setlocal EnableDelayedExpansion

:: ---- Admin check ----
net session >nul 2>&1
if %errorlevel% neq 0 goto notadmin

:: ---- Find VolumeID (Sysinternals) next to this script ----
set "VOLID="
if exist "%~dp0Volumeid64.exe" set "VOLID=%~dp0Volumeid64.exe"
if not defined VOLID if exist "%~dp0Volumeid.exe" set "VOLID=%~dp0Volumeid.exe"
if not defined VOLID goto novolid

:menu
cls
set "DRIVE="
set "OPT="
set "NEWSERIAL="
echo ==========================================
echo         VOLUME SERIAL CHANGER
echo ==========================================
echo.
echo Current volumes:
echo ------------------------------------------
for /f %%d in ('powershell -nologo -command "(Get-PSDrive -PSProvider FileSystem).Name"') do call :showvol %%d
echo ------------------------------------------
echo.
set /p DRIVE=Enter drive letter to change (e.g. D): 
if not defined DRIVE goto menu
set "DRIVE=%DRIVE:~0,1%:"
if not exist "%DRIVE%\" goto baddrive

echo.
echo  1) Generate a random serial
echo  2) Enter a custom serial (format XXXX-XXXX, hex)
echo  3) Quit
echo.
set /p OPT=Choose an option: 
if "%OPT%"=="1" goto random
if "%OPT%"=="2" goto custom
if "%OPT%"=="3" exit /b 0
goto menu

:random
for /f %%i in ('powershell -nologo -command "'{0:X4}-{1:X4}' -f (Get-Random -Max 65536),(Get-Random -Max 65536)"') do set "NEWSERIAL=%%i"
goto confirm

:custom
set /p NEWSERIAL=Enter new serial (XXXX-XXXX): 
if not defined NEWSERIAL goto menu
goto confirm

:confirm
echo.
echo About to change %DRIVE% to serial: %NEWSERIAL%
set /p CONFIRM=Continue? (Y/N): 
if /i not "%CONFIRM%"=="Y" goto menu

"%VOLID%" /accepteula %DRIVE% %NEWSERIAL%
if %errorlevel% neq 0 echo [!] VolumeID reported an error. Check the serial format and try again.

echo.
echo Serial for %DRIVE% now:
vol %DRIVE% | find "Serial"
echo.
echo NOTE: Changing the system drive (usually C:) may need a reboot to take effect.
echo.
pause
goto menu

:showvol
for /f "tokens=*" %%s in ('vol %1: 2^>nul ^| find "Serial"') do echo  %1:  %%s
goto :eof

:baddrive
echo [!] Drive %DRIVE% not found.
pause
goto menu

:notadmin
echo [!] Please right-click this file and choose "Run as administrator".
pause
exit /b 1

:novolid
echo [!] Volumeid.exe / Volumeid64.exe not found next to this script.
echo     Download VolumeID from Microsoft Sysinternals and put it in this folder:
echo     https://learn.microsoft.com/sysinternals/downloads/volumeid
pause
exit /b 1
