@echo off
setlocal enabledelayedexpansion

:: --- 1. FORCE ADMINISTRATIVE PRIVILEGES ---
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator Privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: --- 2. SWITCH WORKING DIRECTORY TO SCRIPT LOCATION ---
cd /d "%~dp0"

:: --- CONFIGURATION VARS ---
set "SERVER_IP=150.136.84.97"
set "SERVER_KEY=Tz4YZeFEWpCozKYmxOcuQ08ZSeC04iUX4Glo7mYfPvQ="
set "UNATTENDED_PW=kX9#mP2$vL7!qR4"
set "CONFIG_PATH=C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk.toml"
set "CONFIG_PATH2=C:\Windows\ServiceProfiles\LocalService\AppData\Roaming\RustDesk\config\RustDesk2.toml"


echo [1/5] Launching Silent RustDesk Installation...
start "" "%~dp0rustdesk.exe" --silent-install

echo [2/5] Waiting for installation files to land in Program Files...
:WAIT_FOR_INSTALL
timeout /t 2 /nobreak >nul
if not exist "C:\Program Files\RustDesk\rustdesk.exe" (
    goto WAIT_FOR_INSTALL
)

echo Files installed! Giving service 5 seconds to finalize initialization...
timeout /t 5 /nobreak >nul

echo [3/5] Stopping RustDesk service and processes to unlock config...
net stop RustDesk /y >nul 2>&1
taskkill /F /IM rustdesk.exe /T >nul 2>&1

echo [4/5] Injecting custom ID ('%COMPUTERNAME%login'), into rustdesk.toml...
(
  echo id = '%COMPUTERNAME%login'
  echo custom-rendezvous-server = '%SERVER_IP%'
  echo key = '%SERVER_KEY%'
  echo password = ''
  echo salt = ''
  echo key_pair = [
  echo   [],
  echo   [],
  echo ]
  echo key_confirmed = false
  echo.
  echo [keys_confirmed]
  echo "%SERVER_IP%:21116" = true
  echo rs-ny = true
) > "%CONFIG_PATH%"

echo Injecting Server IP and Key into RustDesk2.toml...
(
  echo rendezvous_server = '%SERVER_IP%:21116'
  echo nat_type = 1
  echo serial = 0
  echo unlock_pin = ''
  echo.
  echo [options]
  echo custom-rendezvous-server = '%SERVER_IP%'
  echo key = '%SERVER_KEY%'
  echo wol-listen-port = '9'
  echo enable-wol = 'Y'
  echo.
  echo [keys_confirmed]
  echo "%SERVER_IP%:21116" = true
  echo rs-ny = true
) >"%CONFIG_PATH2%"

echo Restarting RustDesk service...
net start RustDesk

:: Turn off delayed expansion so CMD ignores the ! character
endlocal 

echo [5/5] Setting permanent unattended password...
"C:\Program Files\RustDesk\rustdesk.exe" --password "kX9#mP2$vL7!qR4"

echo ===================================================
echo SUCCESS! Installed silently and ID set to '%COMPUTERNAME%login'
echo ===================================================
pause