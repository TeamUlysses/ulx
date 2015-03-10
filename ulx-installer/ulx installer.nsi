; example2.nsi
;
; This script is based on example1.nsi, but it remember the directory,
; has uninstall support and (optionally) installs start menu shortcuts.
;
; It will install example2.nsi into a directory that the user selects,

;--------------------------------


;--------------------------------
;Include Modern UI

  !include "MUI.nsh"

;--------------------------------
;General

!define ULX_VERSION 3.62
!define ULIB_VERSION 2.52

; The file to write
OutFile "install-ulx-v3_62.exe"

; The name of the installer
Name "ULX Installer"

; The default installation directory
InstallDir C:\srcds\orangebox\garrysmod\addons\

;--------------------------------
;Interface Configuration

!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "nsis.bmp" ; optional
!define MUI_ABORTWARNING

;--------------------------------
;Pages

!insertmacro MUI_PAGE_LICENSE "license.txt"
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"


Function .onInit
  MessageBox MB_OK "This installer will install ULib version ${ULIB_VERSION} and ULX version ${ULX_VERSION}"
  ReadRegStr $INSTDIR HKCU "Software\Valve\Steam" "ModInstallPath"
  StrCmp $INSTDIR "" 0 hasReg
    StrCpy $INSTDIR "C:\srcds\orangebox\garrysmod\addons\"
  hasReg:
  StrCpy $INSTDIR "$INSTDIR\..\garrysmod\garrysmod\addons\"
FunctionEnd

Function .onInstSuccess
  MessageBox MB_OK "If you're not running a listen server, please see the readme in the garrysmod root for instruction on adding users.$\nUse 'ulx help' in the console to see a list of commands, say '!menu' for a menu."
FunctionEnd


;--------------------------------

; The stuff to install
Section "Dummy" SecDummy

  ; Set output path to the installation directory.
  SetOutPath $INSTDIR

  ; Put file there
  SetOutPath "$INSTDIR\ulib"
  File /r "..\ulib\*.*"
  SetOutPath "$INSTDIR\ulx"
  File /r "..\ulx\*.*"

SectionEnd

;--------------------------------
;Descriptions

  ;Language strings
  LangString DESC_SecDummy ${LANG_ENGLISH} "section."

  ;Assign language strings to sections
  !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecDummy} $(DESC_SecDummy)
  !insertmacro MUI_FUNCTION_DESCRIPTION_END
