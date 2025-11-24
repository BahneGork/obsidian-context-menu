; Fixed NSIS installer for Obsidian Context Menu

!include "MUI2.nsh"
!include "WinMessages.nsh"

; --------------------------------------- 
; Declare user variables
; --------------------------------------- 
Var OBSIDIAN_EXE_PATH
Var OBSIDIAN_EXE_FOLDER

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
; Function: Find Obsidian.exe
;--------------------------------
Function FindObsidianExe
  StrCpy $OBSIDIAN_EXE_PATH ""
  StrCpy $OBSIDIAN_EXE_FOLDER ""

  ; 1. Check LOCALAPPDATA
  StrCpy $0 "$LOCALAPPDATA\Obsidian\Obsidian.exe"
  IfFileExists "$0" 0 FindObsidianExe_CheckProgramFiles
    StrCpy $OBSIDIAN_EXE_PATH $0
    GetFullPathName $OBSIDIAN_EXE_FOLDER "$OBSIDIAN_EXE_PATH\.."
    Return

  FindObsidianExe_CheckProgramFiles:
  ; 2. Check Program Files
  StrCpy $0 "$PROGRAMFILES\Obsidian\Obsidian.exe"
  IfFileExists "$0" 0 FindObsidianExe_NotFound
    StrCpy $OBSIDIAN_EXE_PATH $0
    GetFullPathName $OBSIDIAN_EXE_FOLDER "$OBSIDIAN_EXE_PATH\.."
    Return

  FindObsidianExe_NotFound:
  ; 3. Ask user manually
  MessageBox MB_ICONINFORMATION|MB_OK "Obsidian.exe not found. Please locate it manually."
  Call PromptForObsidianExe

  StrCmp $OBSIDIAN_EXE_PATH "" 0 +2
    Abort "Obsidian.exe path not found. Installation aborted."

  GetFullPathName $OBSIDIAN_EXE_FOLDER "$OBSIDIAN_EXE_PATH\.."
  Return
FunctionEnd

; -------------------------------- 
; Function: Prompt user for Obsidian.exe
; --------------------------------
Function PromptForObsidianExe
  Loop_Prompt:
    ClearErrors
    FileRequest "Please select Obsidian.exe:" "$PROGRAMFILES\Obsidian\Obsidian.exe" \
      "Executable files (*.exe)|*.exe|All files (*.*)|*.*"

    IfErrors +3
      ; User picked a file → $0 contains path
      StrCmp $0 "" 0 ValidateSelection_Continue
      MessageBox MB_ICONEXCLAMATION "No file selected. Try again."
      Goto Loop_Prompt

    ; User canceled
    StrCpy $OBSIDIAN_EXE_PATH ""
    Return

  ValidateSelection_Continue:
    StrCpy $OBSIDIAN_EXE_PATH $0
    IfFileExists "$OBSIDIAN_EXE_PATH" 0 Loop_Prompt
    Return
FunctionEnd

; -------------------------------- 
; INSTALL SECTION
; --------------------------------
Section "Install"

  Call FindObsidianExe

  StrCmp $OBSIDIAN_EXE_PATH "" 0 +2
    Abort "Obsidian.exe not found. Installation aborted."

  SetOutPath "$INSTDIR"

  File "install_obsidian_context_menu.bat"
  File "uninstall_obsidian_context_menu.bat"
  File "open_obsidian_vault_helper.bat"

  SetOutPath "$INSTDIR\default_obsidian_config"
  File "default_obsidian_config\app.json"
  File "default_obsidian_config\appearance.json"
  File "default_obsidian_config\core-plugins.json"
  File "default_obsidian_config\workspace.json"

  SetOutPath "$INSTDIR"

  WriteUninstaller "$INSTDIR\uninstall.exe"
  WriteRegStr HKCU "Software\ObsidianContextMenu" "InstallPath" "$INSTDIR"

  ; Add/Remove Programs entry
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\ObsidianContextMenu" "DisplayName" "Obsidian Context Menu"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\ObsidianContextMenu" "UninstallString" "$INSTDIR\Uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\ObsidianContextMenu" "InstallLocation" "$INSTDIR"

  ; Context menu text
  StrCpy $0 "Open as Obsidian Vault"
  StrCpy $1 '"$INSTDIR\open_obsidian_vault_helper.bat" "%%1"'
  StrCpy $2 '"$INSTDIR\open_obsidian_vault_helper.bat" "%%V"'
  StrCpy $3 "$OBSIDIAN_EXE_PATH"

  ; Context menu: Directory
  WriteRegStr HKCU "Software\Classes\Directory\shell\ObsidianContextMenu" "" "$0"
  WriteRegStr HKCU "Software\Classes\Directory\shell\ObsidianContextMenu" "Icon" "$3"
  WriteRegStr HKCU "Software\Classes\Directory\shell\ObsidianContextMenu\command" "" "$1"

  ; Context menu: Directory background
  WriteRegStr HKCU "Software\Classes\Directory\Background\shell\ObsidianContextMenu" "" "$0"
  WriteRegStr HKCU "Software\Classes\Directory\Background\shell\ObsidianContextMenu" "Icon" "$3"
  WriteRegStr HKCU "Software\Classes\Directory\Background\shell\ObsidianContextMenu\command" "" "$2"

  MessageBox MB_OK "Obsidian Context Menu installed successfully."

SectionEnd

; -------------------------------- 
; UNINSTALL SECTION
; --------------------------------
Section "Uninstall"

  ReadRegStr $0 HKCU "Software\ObsidianContextMenu" "InstallPath"
  StrCmp $0 "" 0 +2
    StrCpy $0 "$INSTDIR"

  DeleteRegKey HKCU "Software\Classes\Directory\shell\ObsidianContextMenu"
  DeleteRegKey HKCU "Software\Classes\Directory\Background\shell\ObsidianContextMenu"

  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\ObsidianContextMenu"
  DeleteRegKey HKCU "Software\ObsidianContextMenu"

  RMDir /r "$0"

  Delete "$SMPROGRAMS\Obsidian Context Menu\Uninstall.lnk"
  RMDir "$SMPROGRAMS\Obsidian Context Menu"

SectionEnd
