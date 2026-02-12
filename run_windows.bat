@echo off
cd /d "%~dp0"

REM --- AUTO-UPDATE ---
echo [Paris Mod] Checking for updates...

set "LOCAL_VERSION="
for /f "tokens=2 delims=:," %%a in ('findstr /c:"\"version\"" manifest.json') do set "LOCAL_VERSION=%%~a"
for /f "tokens=* delims= " %%a in ("%LOCAL_VERSION%") do set "LOCAL_VERSION=%%a"

if "%LOCAL_VERSION%"=="" goto :START_MOD

where curl >nul 2>nul
if %errorlevel% neq 0 goto :START_MOD

curl -s -H "User-Agent: ParisModUpdater" https://api.github.com/repos/flopinou/paris-sb/releases/latest > release_info.json

set "REMOTE_VERSION="
for /f "tokens=2 delims=:," %%a in ('findstr /c:"\"tag_name\"" release_info.json') do set "REMOTE_VERSION=%%~a"
for /f "tokens=* delims= \"" %%a in ("%REMOTE_VERSION%") do set "REMOTE_VERSION=%%a"
del release_info.json

if "%REMOTE_VERSION%"=="" goto :START_MOD

if "%LOCAL_VERSION%" == "%REMOTE_VERSION%" goto :START_MOD

echo.
echo [Paris Mod] NEW VERSION AVAILABLE: %REMOTE_VERSION% (Current: %LOCAL_VERSION%)
echo.
set /p "CHOICE=Do you want to update now? (y/n): "
if /i not "%CHOICE%"=="y" goto :START_MOD

echo [Paris Mod] Downloading update...
set "DOWNLOAD_URL=https://github.com/flopinou/paris-sb/releases/download/%REMOTE_VERSION%/Paris.zip"

curl -L -o update.zip "%DOWNLOAD_URL%"
if %errorlevel% neq 0 goto :START_MOD

where tar >nul 2>nul
if %errorlevel% neq 0 (
    echo [Paris Mod] Error: 'tar' not found.
    goto :START_MOD
)

if exist "update_temp" rmdir /s /q "update_temp"
mkdir "update_temp"
tar -xf update.zip -C "update_temp"

cd update_temp
for /d %%D in (*) do set "EXTRACTED_DIR=%%D"
cd ..

if exist "update_temp\%EXTRACTED_DIR%\Paris" (
    xcopy /E /Y "update_temp\%EXTRACTED_DIR%\Paris\*" .
) else (
    xcopy /E /Y "update_temp\%EXTRACTED_DIR%\*" .
)

rmdir /s /q "update_temp"
del update.zip
echo [Paris Mod] Update complete!
pause
exit /b 0

:START_MOD
REM --- DATA COPY ---
set "TARGET=%~dp0..\..\cities\data\PAR"
if not exist "%TARGET%" mkdir "%TARGET%"
xcopy /E /Y "%~dp0data\PAR\*" "%TARGET%\" >nul

REM --- PMTILES CHECK ---
if not exist "pmtiles.exe" (
    echo [Paris Mod] 'pmtiles.exe' not found. Downloading latest...

    where curl >nul 2>nul
    if %errorlevel% neq 0 exit /b 1

    curl -s -H "User-Agent: ParisModUpdater" https://api.github.com/repos/protomaps/go-pmtiles/releases/latest > pmtiles_release.json
    
    set "PMTILES_TAG="
    for /f "tokens=2 delims=:," %%a in ('findstr /c:"\"tag_name\"" pmtiles_release.json') do set "PMTILES_TAG=%%~a"
    for /f "tokens=* delims= \"" %%a in ("%PMTILES_TAG%") do set "PMTILES_TAG=%%a"
    del pmtiles_release.json

    if "%PMTILES_TAG%"=="" exit /b 1

    set "PMTILES_VER=%PMTILES_TAG:v=%"
    curl -L -o pmtiles.zip "https://github.com/protomaps/go-pmtiles/releases/download/%PMTILES_TAG%/go-pmtiles_%PMTILES_VER%_Windows_x86_64.zip"

    where tar >nul 2>nul
    if %errorlevel% neq 0 exit /b 1

    tar -xf pmtiles.zip
    if exist "pmtiles.zip" del "pmtiles.zip"

    if not exist "pmtiles.exe" exit /b 1
)

REM --- START SERVER ---
echo [Paris Mod] Starting tile server on port 8080...
pmtiles.exe serve . --port 8080 --cors=*