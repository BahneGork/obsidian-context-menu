@echo off
setlocal

:: ============================================================================
:: Uninstaller for the "Open as Obsidian Vault" Windows Context Menu
:: ============================================================================

echo Removing 'Open as Obsidian Vault' registry keys...

reg delete "HKEY_CLASSES_ROOT\Directory\shell\Obsidian" /f > nul 2>&1
reg delete "HKEY_CLASSES_ROOT\Directory\Background\shell\Obsidian" /f > nul 2>&1

echo.
echo ============================================================================
echo Successfully removed the context menu entries.
echo ============================================================================
echo.
pause
exit /b 0
