@echo off
setlocal enabledelayedexpansion

:: Get the path to the folder that was clicked in Explorer
set "TARGET_FOLDER=%~1"
:: Get the name of the folder, which will be the vault name
for %%F in ("%TARGET_FOLDER%") do set "VAULT_NAME=%%~nxF"

:: Define the source directory for default Obsidian config files
:: %~dp0 refers to the directory where this helper script itself is located.
set "DEFAULT_CONFIG_SOURCE=%~dp0default_obsidian_config"

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

:: Finally, open the vault in Obsidian
:: URL-encode the VAULT_NAME to handle spaces and special characters
for /f "usebackq delims=" %%A in (`powershell -Command "[uri]::EscapeDataString('!VAULT_NAME!')"`) do set "ENCODED_VAULT_NAME=%%A"

start "" "obsidian://open?vault=!ENCODED_VAULT_NAME!"

endlocal
