@echo off
:: Capture script directory BEFORE enabling delayed expansion
set "SCRIPT_DIR=%~dp0"
setlocal enabledelayedexpansion

:: Get the path to the folder that was clicked in Explorer
set "TARGET_FOLDER=%~1"

:: Define the source directory for default Obsidian config files
set "DEFAULT_CONFIG_SOURCE=!SCRIPT_DIR!default_obsidian_config"

:: Check if the .obsidian folder already exists in the target folder
if not exist "%TARGET_FOLDER%\.obsidian\" (
    echo Initializing new Obsidian vault in "%TARGET_FOLDER%"...
    mkdir "%TARGET_FOLDER%\.obsidian\"
    
    :: Copy default config files
    if exist "%DEFAULT_CONFIG_SOURCE%\app.json" copy /Y "%DEFAULT_CONFIG_SOURCE%\app.json" "%TARGET_FOLDER%\.obsidian\" >nul
    if exist "%DEFAULT_CONFIG_SOURCE%\appearance.json" copy /Y "%DEFAULT_CONFIG_SOURCE%\appearance.json" "%TARGET_FOLDER%\.obsidian\" >nul
    if exist "%DEFAULT_CONFIG_SOURCE%\core-plugins.json" copy /Y "%DEFAULT_CONFIG_SOURCE%\core-plugins.json" "%TARGET_FOLDER%\.obsidian\" >nul
    if exist "%DEFAULT_CONFIG_SOURCE%\workspace.json" copy /Y "%DEFAULT_CONFIG_SOURCE%\workspace.json" "%TARGET_FOLDER%\.obsidian\" >nul
    
    echo Default Obsidian config files copied.
) else (
    echo .obsidian folder already exists in "%TARGET_FOLDER%". Skipping initialization.
)

:: Call JScript to register the vault in obsidian.json
echo Registering vault in Obsidian.json...
echo Debug log location: %TEMP%\obsidian_vault_register_debug.log
echo.

:: Set script path
set "REGISTER_SCRIPT=!SCRIPT_DIR!register_obsidian_vault.js"

:: Run JScript and capture output
set "TEMP_OUTPUT=%TEMP%\obsidian_register_output.txt"
cscript.exe //NoLogo "!REGISTER_SCRIPT!" "!TARGET_FOLDER!" > "!TEMP_OUTPUT!" 2>&1

:: Display the output
type "!TEMP_OUTPUT!"
echo.

:: Extract VAULT_ID and status from output (format: VAULT_ID:xxx:NEW or VAULT_ID:xxx:EXISTING)
set "VAULT_ID="
set "VAULT_STATUS="
for /f "tokens=2,3 delims=:" %%i in ('type "!TEMP_OUTPUT!" ^| findstr "VAULT_ID:"') do (
    set "VAULT_ID=%%i"
    set "VAULT_STATUS=%%j"
)

:: Clean up temp file
del "!TEMP_OUTPUT!" 2>nul

if not defined VAULT_ID (
    echo.
    echo ERROR: Failed to register vault or retrieve vault ID
    echo Check debug log at: %TEMP%\obsidian_vault_register_debug.log
    echo.
    pause
    goto :eof
)

echo Opening vault with ID: !VAULT_ID!

:: If this is a NEW vault, close Obsidian first so it reloads obsidian.json
if "!VAULT_STATUS!"=="NEW" (
    echo New vault detected - closing Obsidian to reload vault list...
    tasklist /FI "IMAGENAME eq Obsidian.exe" 2>NUL | find /I /N "Obsidian.exe">NUL
    if !ERRORLEVEL!==0 (
        taskkill /IM Obsidian.exe /F >NUL 2>&1
        timeout /T 2 /NOBREAK >NUL
    )
)

:: Find Obsidian installation
set "OBSIDIAN_EXE="
if exist "%LOCALAPPDATA%\Obsidian\Obsidian.exe" (
    set "OBSIDIAN_EXE=%LOCALAPPDATA%\Obsidian\Obsidian.exe"
) else if exist "%PROGRAMFILES%\Obsidian\Obsidian.exe" (
    set "OBSIDIAN_EXE=%PROGRAMFILES%\Obsidian\Obsidian.exe"
) else if exist "%PROGRAMFILES(X86)%\Obsidian\Obsidian.exe" (
    set "OBSIDIAN_EXE=%PROGRAMFILES(X86)%\Obsidian\Obsidian.exe"
)

:: Open vault in Obsidian (will open new window if already running)
echo Opening vault in new window...
if defined OBSIDIAN_EXE (
    start "Obsidian" "!OBSIDIAN_EXE!" "obsidian://open?vault=!VAULT_ID!"
) else (
    :: Fallback to protocol handler
    start "" "obsidian://open?vault=!VAULT_ID!"
)

endlocal
