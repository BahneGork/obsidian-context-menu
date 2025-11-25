@echo off
setlocal enabledelayedexpansion

:: Get the path to the folder that was clicked in Explorer
set "TARGET_FOLDER=%~1"

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

:: Find Python executable
set "PYTHON_EXE="
for /f "delims=" %%p in ('where python.exe 2^>nul') do if not defined PYTHON_EXE set "PYTHON_EXE=%%p"
if not defined PYTHON_EXE (
    echo ERROR: Python executable not found. Please ensure Python is installed and in your PATH.
    pause
    goto :eof
)

:: Call Python script to register the vault in obsidian.json
echo Registering vault in Obsidian.json...
echo Debug log location: %TEMP%\obsidian_vault_register_debug.log
echo.

:: Run Python script and capture output
set "TEMP_OUTPUT=%TEMP%\obsidian_register_output.txt"
"%PYTHON_EXE%" "%~dp0register_obsidian_vault.py" "!TARGET_FOLDER!" > "!TEMP_OUTPUT!" 2>&1

:: Display the output
type "!TEMP_OUTPUT!"
echo.

:: Extract VAULT_ID from output
set "VAULT_ID="
for /f "tokens=2 delims=:" %%i in ('type "!TEMP_OUTPUT!" ^| findstr "VAULT_ID:"') do set "VAULT_ID=%%i"

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

:: Finally, open the vault in Obsidian using the vault ID
start "" "obsidian://open?vault=!VAULT_ID!"

endlocal
