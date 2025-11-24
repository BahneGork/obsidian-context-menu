@echo off
setlocal

:: ============================================================================
:: Uninstaller for the "Open as Obsidian Vault" Windows Context Menu
:: ============================================================================

echo Removing 'Open as Obsidian Vault' registry keys...

reg delete "HKEY_CLASSES_ROOT\Directory\shell\Obsidian" /f > nul 2>&1
reg delete "HKEY_CLASSES_ROOT\Directory\Background\shell\Obsidian" /f > nul 2>&1

:: Define the permanent installation directory
set "INSTALL_DIR=%LOCALAPPDATA%\ObsidianContextMenu"

:: Remove the permanent installation directory if it exists
if exist "%INSTALL_DIR%" (
    echo Removing installation directory "%INSTALL_DIR%"...
    rmdir /S /Q "%INSTALL_DIR%" >nul 2>&1
)

echo.
echo ============================================================================
echo Successfully removed the context menu entries and installation directory.
echo ============================================================================
echo.
pause
exit /b 0
