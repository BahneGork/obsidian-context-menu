; -------------------------------------------------------------------------------------------------------------
; NSIS Script for Obsidian Context Menu Installer
; -------------------------------------------------------------------------------------------------------------

; General Installer Settings
Name "Obsidian Context Menu"
OutFile "ObsidianContextMenu-Setup.exe"
InstallDir "$LOCALAPPDATA\ObsidianContextMenu" ; Default installation path
RequestExecutionLevel admin

!include "MUI2.nsh" ; For modern UI support
!include "MUI.nsh"  ; Defines core MUI macros like MUI_PAGE_WELCOME

!insertmacro MUI_LANGUAGE "English" ; Request administrator privileges



!define MUI_WELCOMEPAGE_TITLE "Welcome to the Obsidian Context Menu Installer"
!define MUI_WELCOMEPAGE_TEXT "This wizard will guide you through the installation of the Obsidian Context Menu utility.$\n$\nClick Next to continue."
!insertmacro MUI_PAGE_WELCOME

!insertmacro MUI_PAGE_DIRECTORY

!insertmacro MUI_PAGE_INSTFILES

!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_FINISHPAGE_TEXT "Obsidian Context Menu has been successfully installed. You can now right-click on any folder to open it as an Obsidian vault."
!insertmacro MUI_PAGE_FINISH

; Uninstaller Settings
UninstallText "This will completely remove the Obsidian Context Menu entries from your system."
UninstallCaption "Uninstall Obsidian Context Menu"

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH



; -------------------------------------------------------------------------------------------------------------
; Functions
; -------------------------------------------------------------------------------------------------------------

; Function to find Obsidian.exe
; Sets $OBSIDIAN_EXE_PATH and $OBSIDIAN_EXE_FOLDER
Function FindObsidianExe
  StrCpy $OBSIDIAN_EXE_PATH ""
  StrCpy $OBSIDIAN_EXE_FOLDER ""

  ; 1. Check default AppData\Local location
  ReadRegStr $OBSIDIAN_EXE_FOLDER HKLM "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{61AD05DC-4089-4D66-8A33-EB5C7F46B18D}_is1" "InstallLocation"
  IfFileExists "$OBSIDIAN_EXE_FOLDER\Obsidian.exe" FindObsidianExe_Found
  StrCpy $OBSIDIAN_EXE_FOLDER "$LOCALAPPDATA\Obsidian"
  IfFileExists "$OBSIDIAN_EXE_FOLDER\Obsidian.exe" FindObsidianExe_Found

  ; 2. Ask user if not found
  MessageBox MB_ICONINFORMATION|MB_OK "Obsidian.exe not found in common locations. Please locate it manually."
  DirText "Please locate your Obsidian.exe file."
  Call PromptForObsidianExe

  FindObsidianExe_Found:
    GetFullPathName $OBSIDIAN_EXE_FOLDER "$OBSIDIAN_EXE_PATH\.."
    Return

  SelectFilePage:
    ClearErrors
    FileRequest "Please select your Obsidian.exe file:" "$PROGRAMFILES\Obsidian\Obsidian.exe" "Executable files (*.exe)|*.exe|All files (*.*)|*.*"
    IfErrors 0 SelectFilePage_Found
    Abort "Obsidian.exe not selected. Installation aborted."

  SelectFilePage_Found:
    StrCpy $OBSIDIAN_EXE_PATH $R0
    IfFileExists "$OBSIDIAN_EXE_PATH" SelectFilePage_Return
    MessageBox MB_ICONEXCLAMATION|MB_OK "The selected file does not exist. Please try again."
    Goto SelectFilePage

  SelectFilePage_Return:
    Return
FunctionEnd

; Function to handle file selection (if manual location is needed)
Function PromptForObsidianExe
  Loop_Prompt:
    ClearErrors
    FileRequest "Please select your Obsidian.exe file:" "$PROGRAMFILES\Obsidian\Obsidian.exe" "Executable files (*.exe)|*.exe|All files (*.*)|*.*"
    IfErrors 0 ValidateSelection
    ; User cancelled FileRequest
    StrCpy $OBSIDIAN_EXE_PATH "" ; Clear path to indicate abortion
    Return ; Exit function

  ValidateSelection:
    StrCpy $OBSIDIAN_EXE_PATH $R0
    IfFileExists "$OBSIDIAN_EXE_PATH" Return
    MessageBox MB_ICONEXCLAMATION|MB_OK "The selected file does not exist. Please try again."
    Goto Loop_Prompt
FunctionEnd

; -------------------------------------------------------------------------------------------------------------
; Installer Section
; -------------------------------------------------------------------------------------------------------------
Section "Obsidian Context Menu Installation"

  ; Call function to find Obsidian.exe path
  Call FindObsidianExe

  ; Check if Obsidian.exe path was found
  StrCmp $OBSIDIAN_EXE_PATH "" 0 +2
  Abort "Obsidian.exe path not found. Installation aborted."

  ; Create installation directory
  SetOutPath $INSTDIR

  ; Copy files to installation directory
  File "install_obsidian_context_menu.bat"
  File "uninstall_obsidian_context_menu.bat"
  File "open_obsidian_vault_helper.bat"
  ; Copy default_obsidian_config folder and its contents
  SetOutPath "$INSTDIR\default_obsidian_config"
  File "/oname=app.json" "default_obsidian_config\app.json"
  File "/oname=appearance.json" "default_obsidian_config\appearance.json"
  File "/oname=core-plugins.json" "default_obsidian_config\core-plugins.json"
  File "/oname=workspace.json" "default_obsidian_config\workspace.json"

  ; Go back to main install dir
  SetOutPath $INSTDIR

  ; Write uninstaller
  WriteUninstaller "$INSTDIR\uninstall.exe"

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
  WriteRegStr HKLM "Software\Classes\Directory\shell\Obsidian" "" "$0"
  WriteRegExpandStr HKLM "Software\Classes\Directory\shell\Obsidian" "Icon" "$3"
  WriteRegStr HKLM "Software\Classes\Directory\shell\Obsidian\command" "" "$1"

  ; Directory\Background\shell (right-click in folder background)
  WriteRegStr HKLM "Software\Classes\Directory\Background\shell\Obsidian" "" "$0"
  WriteRegExpandStr HKLM "Software\Classes\Directory\Background\shell\Obsidian" "Icon" "$3"
  WriteRegStr HKLM "Software\Classes\Directory\Background\shell\Obsidian\command" "" "$2"

  MessageBox MB_ICONINFORMATION|MB_OK "Obsidian Context Menu has been successfully installed."

SectionEnd

; -------------------------------------------------------------------------------------------------------------
; Uninstaller Section
; -------------------------------------------------------------------------------------------------------------
Section "Uninstall"

  ; Delete Registry Entries
  DeleteRegKey HKLM "Software\Classes\Directory\shell\Obsidian"
  DeleteRegKey HKLM "Software\Classes\Directory\Background\shell\Obsidian"

  ; Delete Files
  Delete "$INSTDIR\install_obsidian_context_menu.bat"
  Delete "$INSTDIR\uninstall_obsidian_context_menu.bat"
  Delete "$INSTDIR\open_obsidian_vault_helper.bat"
  Delete "$INSTDIR\uninstall.exe"

  ; Delete Default Config Files
  Delete "$INSTDIR\default_obsidian_config\app.json"
  Delete "$INSTDIR\default_obsidian_config\appearance.json"
  Delete "$INSTDIR\default_obsidian_config\core-plugins.json"
  Delete "$INSTDIR\default_obsidian_config\workspace.json"
  RMDir "$INSTDIR\default_obsidian_config"

  ; Delete Installation Directory
  RMDir "$INSTDIR"

  MessageBox MB_ICONINFORMATION|MB_OK "Obsidian Context Menu has been completely uninstalled."

SectionEnd
