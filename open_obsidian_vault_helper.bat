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

:: Open the vault in Obsidian using the path parameter
:: Obsidian will register it automatically on first open
echo Opening vault in Obsidian...

:: URL-encode the path for use in URI
for /f "usebackq delims=" %%A in (`powershell -Command "[uri]::EscapeDataString('!TARGET_FOLDER!')"`) do set "ENCODED_PATH=%%A"

:: Open using path - Obsidian will register it automatically
start "" "obsidian://open?path=!ENCODED_PATH!"

echo.
echo Vault opened! Obsidian will register it automatically on first access.

endlocal
