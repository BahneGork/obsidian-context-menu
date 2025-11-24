; Fixed NSIS installer for Obsidian Context Menu

!include "MUI2.nsh"
!include "WinMessages.nsh"
!include "FileFunc.nsh"
!include "nsDialogs.nsh"

; --------------------------------------- 
; Declare user variables
; --------------------------------------- 
Var OBSIDIAN_EXE_PATH
Var OBSIDIAN_EXE_FOLDER

Var OBSIDIAN_PATH_HWND

Name "Obsidian Context Menu"
OutFile "ObsidianContextMenu-Setup.exe"
InstallDir "$LOCALAPPDATA\ObsidianContextMenu"
InstallDirRegKey HKCU "Software\ObsidianContextMenu" "InstallPath"
RequestExecutionLevel user ; per-user install; change to admin if you need HKLM

;--------------------------------
; Pages
;--------------------------------
!insertmacro MUI_PAGE_WELCOME
Page custom ObsidianPathPage ObsidianPathPageLeave
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

;--------------------------------
; Function: .onInit - Initialize installer
;--------------------------------
Function .onInit
  Call FindObsidianExe
FunctionEnd

Function FindObsidianExe
  MessageBox MB_OK "FindObsidianExe called."
  StrCpy $OBSIDIAN_EXE_PATH "$PROGRAMFILES\Obsidian\Obsidian.exe"
  Return
FunctionEnd

; -------------------------------- 
; Custom page: Obsidian Path Selection
; --------------------------------
Function ObsidianPathPage
  ; Only show this page if Obsidian.exe wasn't found automatically
  StrCmp $OBSIDIAN_EXE_PATH "" 0 ObsidianPathPage_Skip
  
  !insertmacro MUI_HEADER_TEXT "Obsidian Path" "Please select the path to Obsidian.exe"
  
  nsDialogs::Create 1018
  Pop $0
  
  ${NSD_CreateLabel} 0 0 100% 20u "Please select the path to Obsidian.exe:"
  Pop $0
  
  StrCpy $1 "$PROGRAMFILES\Obsidian\Obsidian.exe"
  
  ${NSD_CreateText} 0 25u 75% 12u "$1"
  Pop $OBSIDIAN_PATH_HWND
  
  ${NSD_CreateButton} 76% 24u 23% 14u "Browse..."
  Pop $0
  ${NSD_OnClick} $0 OnBrowseClick
  
  nsDialogs::Show
  
  ObsidianPathPage_Skip:
FunctionEnd

Function ObsidianPathPageLeave
  ; Only validate if the page was shown
  StrCmp $OBSIDIAN_EXE_PATH "" 0 ObsidianPathPageLeave_Skip
  
  ${NSD_GetText} $OBSIDIAN_PATH_HWND $OBSIDIAN_EXE_PATH
  StrCmp $OBSIDIAN_EXE_PATH "" ObsidianPathPageLeave_Error 0
  IfFileExists "$OBSIDIAN_EXE_PATH" ObsidianPathPageLeave_OK ObsidianPathPageLeave_Error
  
  ObsidianPathPageLeave_Error:
    MessageBox MB_ICONEXCLAMATION "Please select a valid Obsidian.exe file."
    Abort
  
  ObsidianPathPageLeave_OK:
  ${GetParent} "$OBSIDIAN_EXE_PATH" $OBSIDIAN_EXE_FOLDER
  
  ObsidianPathPageLeave_Skip:
FunctionEnd

Function OnBrowseClick
  ; Get current text as initial directory
  ${NSD_GetText} $OBSIDIAN_PATH_HWND $1
  ${GetParent} "$1" $2
  StrCmp $2 "" 0 +2
    StrCpy $2 "$PROGRAMFILES\Obsidian"
  
  ; Use Windows file dialog
  nsDialogs::SelectFileDialog open "$2" "Executable files (*.exe)|*.exe|All files (*.*)|*.*"
  Pop $0
  StrCmp $0 "" OnBrowseClick_End 0
  StrCmp $0 "error" OnBrowseClick_End 0
  ${NSD_SetText} $OBSIDIAN_PATH_HWND $0
  
  OnBrowseClick_End:
FunctionEnd



; -------------------------------- 
; INSTALL SECTION
; --------------------------------
Section "Install"

  ; Obsidian path should already be set by .onInit or custom page
  StrCmp $OBSIDIAN_EXE_PATH "" 0 +2
    Abort "Obsidian.exe path not found. Installation aborted."

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
  StrCpy $1 'cmd.exe /c """$INSTDIR\open_obsidian_vault_helper.bat"" "%1""'
  StrCpy $2 'cmd.exe /c """$INSTDIR\open_obsidian_vault_helper.bat"" "%V""'
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
  ; Also delete old keys from batch installer, if they exist
  DeleteRegKey HKCU "Software\Classes\Directory\shell\Obsidian"
  DeleteRegKey HKCU "Software\Classes\Directory\Background\shell\Obsidian"

  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\ObsidianContextMenu"
  DeleteRegKey HKCU "Software\ObsidianContextMenu"

  RMDir /r "$0"

  Delete "$SMPROGRAMS\Obsidian Context Menu\Uninstall.lnk"
  RMDir "$SMPROGRAMS\Obsidian Context Menu"

SectionEnd
