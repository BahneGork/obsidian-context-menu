@echo off
setlocal
set "HELPER_SCRIPT_PATH=%~dp0open_obsidian_vault_helper.bat"

set "INSTALL_DIR=%LOCALAPPDATA%\ObsidianContextMenu"
echo.
echo Installing files to "%INSTALL_DIR%"...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"

copy /Y "%~dp0install_obsidian_context_menu.bat" "%INSTALL_DIR%\" >nul
copy /Y "%~dp0uninstall_obsidian_context_menu.bat" "%INSTALL_DIR%\" >nul
copy /Y "%~dp0open_obsidian_vault_helper.bat" "%INSTALL_DIR%\" >nul
copy /Y "%~dp0register_obsidian_vault.ps1" "%INSTALL_DIR%\" >nul
xcopy /E /I /Y "%~dp0default_obsidian_config\" "%INSTALL_DIR%\default_obsidian_config\" >nul 2>&1

:: Update HELPER_SCRIPT_PATH to point to the installed location
set "HELPER_SCRIPT_PATH=%INSTALL_DIR%\open_obsidian_vault_helper.bat"

echo Installation complete. You can safely delete the downloaded files now.
echo Use the uninstaller in "%INSTALL_DIR%" if needed.
echo.

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



:: Add registry key for right-clicking on a folder
reg add "HKEY_CLASSES_ROOT\Directory\shell\Obsidian" /v "" /t REG_SZ /d "Open as Obsidian Vault" /f > nul
reg add "HKEY_CLASSES_ROOT\Directory\shell\Obsidian" /v "Icon" /t REG_EXPAND_SZ /d "\"%OBSIDIAN_PATH%\"" /f > nul
reg add "HKEY_CLASSES_ROOT\Directory\shell\Obsidian\command" /v "" /t REG_SZ /d "\"\"%HELPER_SCRIPT_PATH%\"\" \"\"%%1\"\"" /f > nul

:: Add registry key for right-clicking inside a folder's background
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\Obsidian" /v "" /t REG_SZ /d "Open as Obsidian Vault" /f > nul
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\Obsidian" /v "Icon" /t REG_EXPAND_SZ /d "\"%OBSIDIAN_PATH%\"" /f > nul
reg add "HKEY_CLASSES_ROOT\Directory\Background\shell\Obsidian\command" /v "" /t REG_SZ /d "\"\"%HELPER_SCRIPT_PATH%\"\" \"\"%%V\"\"" /f > nul

echo.
echo ============================================================================ 
echo Successfully added 'Open as Obsidian Vault' to the context menu!
echo ============================================================================ 
echo.
pause
exit /b 0
