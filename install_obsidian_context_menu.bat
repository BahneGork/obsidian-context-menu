@echo off
setlocal
set "HELPER_SCRIPT_PATH=%~dp0open_obsidian_vault_helper.bat"

:: ============================================================================ 
:: Installer for the "Open as Obsidian Vault" Windows Context Menu
:: ============================================================================ 

echo Searching for Obsidian.exe...
set "OBSIDIAN_PATH=%LOCALAPPDATA%\Obsidian\Obsidian.exe"

if not exist "%OBSIDIAN_PATH%" (
    echo.
    echo Obsidian.exe not found in the default location.
    echo Please drag and drop your Obsidian.exe file here and press Enter:
    echo (You can find it by right-clicking your Obsidian shortcut and selecting 'Open file location')
    echo.
    set /p "OBSIDIAN_PATH="
)

:: Remove quotes if the user dragged-and-dropped the file
set OBSIDIAN_PATH=%OBSIDIAN_PATH:"=%

if not exist "%OBSIDIAN_PATH%" (
    echo.
    echo ERROR: The specified path is not valid. Aborting.
    pause
    exit /b 1
)

echo Found Obsidian at: %OBSIDIAN_PATH%
echo Adding registry keys...

:: Escape backslashes for the registry command
set REG_OBSIDIAN_PATH=%OBSIDIAN_PATH:\=\% 

:: Add registry key for right-clicking on a folder
reg add "HKEY_CLASSES_ROOT\Directory\shell\Obsidian" /v "" /t REG_SZ /d "Open as Obsidian Vault" /f > nul
reg add "HKEY_CLASSES_ROOT\Directory\shell\Obsidian" /v "Icon" /t REG_EXPAND_SZ /d "%OBSIDPATH%" /f > nul 2>&1
reg add "HKEY_CLASSES_ROOT\Directory\shell\Obsidian" /v "Icon" /t REG_SZ /d "%OBSIDIAN_PATH%" /f > nul
reg add "HKEY_CLASSES_ROOT\Directory\shell\Obsidian\command" /v "" /t REG_SZ /d "cmd.exe /c ""%HELPER_SCRIPT_PATH%"" ""%%1""""" /f > nul

:: Add registry key for right-clicking inside a folder's background
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\Obsidian" /v "" /t REG_SZ /d "Open as Obsidian Vault" /f > nul
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\Obsidian" /v "Icon" /t REG_EXPAND_SZ /d "%OBSIDPATH%" /f > nul 2>&1
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\Obsidian" /v "Icon" /t REG_SZ /d "%OBSIDIAN_PATH%" /f > nul
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\Obsidian\command" /v "" /t REG_SZ /d "cmd.exe /c ""%HELPER_SCRIPT_PATH%"" ""%%V""""" /f > nul

echo.
echo ============================================================================ 
echo Successfully added 'Open as Obsidian Vault' to the context menu!
echo ============================================================================ 
echo.
pause
exit /b 0
