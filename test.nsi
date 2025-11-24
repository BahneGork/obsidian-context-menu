; Simple NSIS Test Script
Name "Test Installer"
OutFile "TestInstaller.exe"
RequestExecutionLevel admin

Section "Test"
  MessageBox MB_OK "Hello from NSIS!"
SectionEnd
