; Fixed NSIS installer for Obsidian Context Menu
; Reference/source: /mnt/data/ObsidianContextMenuInstaller.nsi
; ------------------------------------------------------------------
; This script uses Modern UI 2 (MUI2), writes an uninstall entry, installs
; files (recursively from the folder next to the script), registers a
; per-user context-menu entry and supports clean uninstallation.
; Edit the File/SetOutPath lines below to match your build layout.
; ------------------------------------------------------------------

!include "MUI2.nsh"
!include "WinMessages.nsh"

Name "Obsidian Context Menu"
OutFile "ObsidianContextMenu-Setup.exe"
InstallDir "$LOCALAPPDATA\ObsidianContextMenu"
InstallDirRegKey HKCU "Software\ObsidianContextMenu" "InstallPath"
RequestExecutionLevel user ; per-user install; change to admin if you need HKLM

;--------------------------------
; Pages
;--------------------------------
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM ; confirmation on uninstall (optional)

!insertmacro MUI_LANGUAGE "English"

;--------------------------------
; Functions to find Obsidian.exe
;--------------------------------
Function FindObsidianExe
  StrCpy $OBSIDIAN_EXE_PATH ""
  StrCpy $OBSIDIAN_EXE_FOLDER ""

  ; 1. Check common AppData\Local location
  StrCpy $0 "$LOCALAPPDATA\Obsidian\Obsidian.exe" ; Use a temporary variable
  IfFileExists $0 0 FindObsidianExe_CheckProgramFiles
  StrCpy $OBSIDIAN_EXE_PATH $0
  GetFullPathName $OBSIDIAN_EXE_FOLDER "$OBSIDIAN_EXE_PATH\.."
  Return

  FindObsidianExe_CheckProgramFiles:
  ; 2. Check common Program Files location
  StrCpy $0 "$PROGRAMFILES\Obsidian\Obsidian.exe" ; Use a temporary variable
  IfFileExists $0 0 FindObsidianExe_NotFound
  StrCpy $OBSIDIAN_EXE_PATH $0
  GetFullPathName $OBSIDIAN_EXE_FOLDER "$OBSIDIAN_EXE_PATH\.."
  Return

  FindObsidianExe_NotFound:
  ; 3. Ask user if not found
  MessageBox MB_ICONINFORMATION|MB_OK "Obsidian.exe not found in common locations. Please locate it manually."
  Call PromptForObsidianExe

  ; If user selected a file, $OBSIDIAN_EXE_PATH will be set
  StrCmp $OBSIDIAN_EXE_PATH "" 0 FindObsidianExe_FoundManual ; If not empty, proceed
  Abort "Obsidian.exe path not found. Installation aborted." ; User cancelled or did not select

  FindObsidianExe_FoundManual:
    GetFullPathName $OBSIDIAN_EXE_FOLDER "$OBSIDIAN_EXE_PATH\.."
    Return
FunctionEnd

Function PromptForObsidianExe
  Loop_Prompt:
    ClearErrors
    FileRequest "Please select your Obsidian.exe file:" "$PROGRAMFILES\Obsidian\Obsidian.exe" "Executable files (*.exe)|*.exe|All files (*.*)|*.*"
    IfErrors 0 ValidateSelection
    ; User cancelled FileRequest
    StrCpy $OBSIDIAN_EXE_PATH "" ; Clear path to indicate abortion
    Return ; Exit function

  ValidateSelection:
    StrCmp $R0 "" 0 ValidateSelection_Continue ; If $R0 is empty, it means no file was selected
    MessageBox MB_ICONEXCLAMATION|MB_OK "No file was selected. Please try again."
    Goto Loop_Prompt

  ValidateSelection_Continue:
    StrCpy $OBSIDIAN_EXE_PATH $R0
    IfFileExists "$OBSIDIAN_EXE_PATH" Return
    MessageBox MB_ICONEXCLAMATION|MB_OK "The selected file does not exist. Please try again."
    Goto Loop_Prompt
FunctionEnd
Section "Install"

  ; Call function to find Obsidian.exe path
  Call FindObsidianExe

  ; Check if Obsidian.exe path was found
  StrCmp $OBSIDIAN_EXE_PATH "" 0 +2
  Abort "Obsidian.exe path not found. Installation aborted."

  ; Create installation directory
  SetOutPath "$INSTDIR"

  ; Copy files to installation directory
  File "install_obsidian_context_menu.bat"
  File "uninstall_obsidian_context_menu.bat"
  File "open_obsidian_vault_helper.bat"
  ; Copy default_obsidian_config folder and its contents
  SetOutPath "$INSTDIR\default_obsidian_config"
  File "default_obsidian_config\app.json"
  File "default_obsidian_config\appearance.json"
  File "default_obsidian_config\core-plugins.json"
  File "default_obsidian_config\workspace.json"

  ; Go back to main install dir
  SetOutPath $INSTDIR

  ; Write uninstaller
  WriteUninstaller "$INSTDIR\uninstall.exe"

  ; Write install path to HKCU so we can find it later (for uninstall)
  WriteRegStr HKCU "Software\ObsidianContextMenu" "InstallPath" "$INSTDIR"

  ; Register Add/Remove Programs entry under HKCU (per-user)
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\ObsidianContextMenu" "DisplayName" "Obsidian Context Menu"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\ObsidianContextMenu" "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\ObsidianContextMenu" "InstallLocation" "$INSTDIR"

  ; ---------------------------------------------------------------------------
  ; Registry Entries (Context Menu)
  ; ---------------------------------------------------------------------------

  ; Context Menu Item Text
  StrCpy $0 "Open as Obsidian Vault"

  ; Command to execute
  StrCpy $1 '"$INSTDIR\open_obsidian_vault_helper.bat" "%%1"' ; For Directory\shell
  StrCpy $2 '"$INSTDIR\open_obsidian_vault_helper.bat" "%%V"' ; For Directory\Background\shell

  ; Icon path
  StrCpy $3 '"$OBSIDIAN_EXE_PATH"'

  ; Directory\shell (right-click on folder)
  WriteRegStr HKCU "Software\Classes\Directory\shell\ObsidianContextMenu" "" "$0"
  WriteRegExpandStr HKCU "Software\Classes\Directory\shell\ObsidianContextMenu" "Icon" "$3"
  WriteRegStr HKCU "Software\Classes\Directory\shell\ObsidianContextMenu\command" "" "$1"

  ; Directory\Background\shell (right-click in folder background)
  WriteRegStr HKCU "Software\Classes\Directory\Background\shell\ObsidianContextMenu" "" "$0"
  WriteRegExpandStr HKCU "Software\Classes\Directory\Background\shell\ObsidianContextMenu" "Icon" "$3"
  WriteRegStr HKCU "Software\Classes\Directory\Background\shell\ObsidianContextMenu\command" "" "$2"

  MessageBox MB_ICONINFORMATION|MB_OK "Obsidian Context Menu has been successfully installed."

SectionEnd
;--------------------------------
; Uninstaller
;--------------------------------
Section "Uninstall"
  ; Read install path from registry if needed
  ReadRegStr $0 HKCU "Software\ObsidianContextMenu" "InstallPath"
  StrCmp $0 "" 0 +2
    StrCpy $0 "$INSTDIR"

  ; Remove context menu registry keys (per-user)
  DeleteRegKey HKCU "Software\Classes\*\shell\ObsidianContextMenu"
  DeleteRegKey HKCU "Software\Classes\Directory\shell\ObsidianContextMenu"

  ; Remove Add/Remove Programs entry
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\ObsidianContextMenu"

  ; Remove the installer registry key we wrote
  DeleteRegKey HKCU "Software\ObsidianContextMenu"

  ; Delete installed files and folders
  ; Use RMDir /r to remove directories recursively
  ; Be careful: $0 should be the actual install path
  IfFileExists "$INSTDIR\*" 0 +2
    RMDir /r "$INSTDIR"

  ; If we wrote a Start Menu shortcut folder, remove it
  Delete "$SMPROGRAMS\Obsidian Context Menu\Uninstall.lnk"
  RMDir "$SMPROGRAMS\Obsidian Context Menu"

SectionEnd

;--------------------------------
; EOF
;--------------------------------