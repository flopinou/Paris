@echo off
cd /d "%~dp0"

REM Copy data files to cities\data\PAR
set "TARGET=%~dp0..\..\cities\data\PAR"
echo [Paris Mod] Copying data files to cities\data\PAR...
if not exist "%TARGET%" mkdir "%TARGET%"
xcopy /E /Y "%~dp0data\PAR\*" "%TARGET%\" >nul
echo [Paris Mod] Data files copied successfully.

REM Check pmtiles.exe
if exist "pmtiles.exe" goto :START_SERVER

echo [Paris Mod] 'pmtiles.exe' not found. Checking for download tools...
set "DOWNLOAD_SUCCESS=0"

REM Use CURL if available 
where curl >nul 2>nul
if %errorlevel% equ 0 (
    echo [Paris Mod] Found curl. Attempting download...
    curl -L -f -o pmtiles.zip "https://github.com/protomaps/go-pmtiles/releases/download/v1.30.0/go-pmtiles_1.30.0_Windows_x86_64.zip"
    if not errorlevel 1 set "DOWNLOAD_SUCCESS=1"
)

REM Fallback to PowerShell 
if "%DOWNLOAD_SUCCESS%"=="0" (
    echo [Paris Mod] Curl missing or failed. Using PowerShell...
    powershell -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri 'https://github.com/protomaps/go-pmtiles/releases/download/v1.30.0/go-pmtiles_1.30.0_Windows_x86_64.zip' -OutFile 'pmtiles.zip'"
)

if not exist "pmtiles.zip" (
    echo [Paris Mod] Error: Download failed with both curl and PowerShell.
    echo Please manually download: https://github.com/protomaps/go-pmtiles/releases/download/v1.30.0/go-pmtiles_1.30.0_Windows_x86_64.zip
    pause
    exit /b 1
)

REM Extracting
echo [Paris Mod] Extracting pmtiles.exe...
set "EXTRACT_SUCCESS=0"

where tar >nul 2>nul
if %errorlevel% equ 0 (
    REM Use TAR if available 
    tar -xf pmtiles.zip pmtiles.exe
    if not errorlevel 1 set "EXTRACT_SUCCESS=1"
)

if "%EXTRACT_SUCCESS%"=="0" (
    REM Fallback to PowerShell
    echo [Paris Mod] 'tar' not found or failed. Trying PowerShell...
    if exist "temp_pmtiles" rmdir /s /q "temp_pmtiles"
    powershell -Command "Expand-Archive -Path 'pmtiles.zip' -DestinationPath 'temp_pmtiles' -Force"
    
    if exist "temp_pmtiles\pmtiles.exe" (
        copy /Y "temp_pmtiles\pmtiles.exe" . >nul
    )
    if exist "temp_pmtiles" rmdir /s /q "temp_pmtiles"
)

REM Clean up zip
if exist "pmtiles.zip" del "pmtiles.zip"

REM Verify extraction
if not exist "pmtiles.exe" (
    echo [Paris Mod] Error: Extraction failed or pmtiles.exe not found.
    pause
    exit /b 1
)

echo [Paris Mod] pmtiles.exe installed successfully.

:START_SERVER
REM Start tile server
echo [Paris Mod] Starting tile server on port 8080...
pmtiles.exe serve . --port 8080 --cors=*