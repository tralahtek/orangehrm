;----------------------------------------------------------------------------------------------
; OrangeHRM is a comprehensive Human Resource Management (HRM) System that captures
; all the essential functionalities required for any enterprise.
; Copyright (C) 2006 OrangeHRM Inc., http://www.orangehrm.com
;
; OrangeHRM is free software; you can redistribute it and/or modify it under the terms of
; the GNU General Public License as published by the Free Software Foundation; either
; version 2 of the License, or (at your option) any later version.
;
; OrangeHRM is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
; See the GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License along with this program;
; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
; Boston, MA  02110-1301, USA
;----------------------------------------------------------------------------------------------

;---------------------------------------------------------
; OrangeHRM Appliance for Windows NSIS installer script
; Uses NSIS Modern User Interface
;
; Modified by Mohanjith
;
; See readme in this folder for details on how to use this
; script to compile the installer.
;----------------------------------------------------------
  ; Compression
  SetCompressor "lzma"

;--------------------------------
; Product Details

  !define ProductName "OrangeHRM"
  !define ProductVersion "4.8"

  !define Organization "OrangeHRM Inc."

  ; Register details

  BrandingText "${Organization}"
  Name "${ProductName} ${ProductVersion}"
  Caption "${ProductName} ${ProductVersion} Setup (Deprecated)"

;--------------------------------
; Directory structure

  !define SourceLocation "../SOURCE"
  !define OrangeHRMPath "orangehrm-${ProductVersion}"
  !define XamppPath "xampp"

;--------------------------------
; Output

  OutFile "../../orangehrm-${ProductVersion}.exe"

;--------------------------------
; Includes

  ; Modern UI

  !include "MUI.nsh"

  ; Macros
    XPStyle on
    !include nsDialogs.nsh
    !include LogicLib.nsh
  !include "Include\WordFunc.nsh"
  !include "Include\StrRep.nsh"
  !include "Include\ReplaceInFile.nsh"
  !include "Include\CheckUserEmailAddress.nsh"
  !include "Include\CheckContactNumber.nsh"  
  !include "Include\Ports.nsh"
  !include "Include\servicelib.nsh"
  !include "Include\WriteToFile.nsh"

  ; InstallOptions
    !include "Registration.nsdinc"
  ReserveFile "AdminUserDetails.ini"
  ReserveFile "ContactDetails.ini"
  #ReserveFile "CheckApacheAlreadyInstalled.ini"

;--------------------------------
; Register macros

  !insertmacro WordReplace
  !insertmacro MUI_RESERVEFILE_INSTALLOPTIONS
  
;--------------------------------
; Global variables

  Var /GLOBAL UserName
  Var /GLOBAL PasswordHash

  Var /GLOBAL ContactName
  Var /GLOBAL ContactEmail
  Var /GLOBAL Coments
  Var /GLOBAL Updates
  Var /GLOBAL PostStr
  Var /GLOBAL DefaultInstallDir
  Var /GLOBAL VerifiedInallDirectory
  
  Var /GLOBAL CompanyName

;--------------------------------
;General

  ; Default installation folder
  InstallDir "$PROGRAMFILES\OrangeHRM\${ProductVersion}"
  Page custom check_os_version

  ; Get installation folder from registry if available
  InstallDirRegKey HKCU "Software\OrangeHRM\${ProductVersion}" ""

;--------------------------------
; Interface Settings

  ; Icons
  !define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\orange-install.ico"
  !define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\orange-uninstall.ico"
  !define SHORTCUT_ICON "$INSTDIR\logo.ico"

  ; Header
  !define MUI_HEADERIMAGE "${NSISDIR}\Contrib\Graphics\Icons\orange-uninstall.ico"
  !define MUI_HEADERIMAGE_RIGHT
  !define MUI_HEADERIMAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Header\orange-r.bmp"
  !define MUI_HEADERIMAGE_UNBITMAP "${NSISDIR}\Contrib\Graphics\Header\orange-uninstall-r.bmp"

  ; Wizard
  !define MUI_WELCOMEFINISHPAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Wizard\orange.bmp"
  !define MUI_UNWELCOMEFINISHPAGE_BITMAP "${NSISDIR}\Contrib\Graphics\Wizard\orange-uninstall.bmp"

  !define MUI_ABORTWARNING

;--------------------------------
; Pages

  !define MUI_WELCOMEPAGE_TITLE "Welcome to OrangeHRM ${ProductVersion} Setup \r\n(Deprecated)"
  !define MUI_WELCOMEPAGE_TITLE_3LINES
  !define MUI_WELCOMEPAGE_TEXT "OrangeHRM EXE version has been deprecated. \r\n\r\nOrangeHRM EXE version no longer supported from March 2021 onwards. Download the ZIP / docker version to install the OrangeHRM Opensource Application. \r\n\r\nSetup will guide you through the installation of OrangeHRM ${ProductVersion}. \r\n\r\nIt is recommended that you close all other applications before starting Setup. This will make it possibel to update relevent system files without having to reboot your computer. \r\n\r\nClick Next to continue."
  !define MUI_PAGE_CUSTOMFUNCTION_SHOW wel_show
  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_LICENSE "${SourceLocation}\content\license.txt"
  !insertmacro MUI_PAGE_COMPONENTS
  
  Page custom  AdminUserDetailsEnter AdminUserDetailsEnterValidate
  
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  
  Page custom ContactDetailsEnter ContactDetailsEnterValidate	
  
  !define MUI_FINISHPAGE_NOAUTOCLOSE
  !define MUI_FINISHPAGE_RUN
  !define MUI_FINISHPAGE_RUN_NOTCHECKED
  !define MUI_FINISHPAGE_RUN_TEXT "Run OrangeHRM"
  !define MUI_FINISHPAGE_RUN_FUNCTION "LaunchLink"
  !insertmacro MUI_PAGE_FINISH

  !insertmacro MUI_UNPAGE_WELCOME
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  !insertmacro MUI_UNPAGE_FINISH

;--------------------------------
; Languages

  !insertmacro MUI_LANGUAGE "English"

;--------------------------------
; Utility functions

Function LaunchLink

ExecShell "" "$INSTDIR\start.vbs"

FunctionEnd

  Function buildUnixPath

    Var /GLOBAL UNIXINSTDIR
    ${WordReplace} "$INSTDIR" "\" "/" "E+" $UNIXINSTDIR

  FunctionEnd


Function check_os_version
		ReadEnvStr $0 ProgramW6432
		StrCmp $0 "" thirtyTwoBit sixtyFourBit
		sixtyFourBit:
		    StrCpy $INSTDIR "$PROGRAMFILES64\OrangeHRM\${ProductVersion}"
			StrCpy $DefaultInstallDir "$INSTDIR"
			Abort
		thirtyTwoBit:
			StrCpy $DefaultInstallDir "$INSTDIR"
FunctionEnd

Function .onVerifyInstDir
		StrCmp $VerifiedInallDirectory true PathGood 0
			ReadEnvStr $0 ProgramW6432
			StrCmp $0 "" thirtyTwoBit sixtyFourBit
			sixtyFourBit:
				StrCmp $DefaultInstallDir $INSTDIR PathGood 0
					MessageBox MB_OK "Make sure you don't select a location inside Program Files (x86)"
					StrCpy $VerifiedInallDirectory true
					Abort
			thirtyTwoBit:
		PathGood:
FunctionEnd

Function Func_save_data
	
	${NSD_GetText} $hCtl_Registration_TextBox3 $0
	${NSD_GetState} $hCtl_Registration_CheckBox1 $1
	StrCpy $CompanyName "$0"
	${If} $1 == 1
		nsExec::ExecToLog '"$INSTDIR\mysql\bin\mysql" -u root -D orangehrm_mysql -e "UPDATE hs_hr_config SET `value`= $\'on$\' WHERE `key`=$\'beacon.activation_acceptance_status$\'"'
	${Else} 
		nsExec::ExecToLog '"$INSTDIR\mysql\bin\mysql" -u root -D orangehrm_mysql -e "UPDATE hs_hr_config SET `value`= $\'off$\' WHERE `key`=$\'beacon.activation_acceptance_status$\'"'
	${EndIf}
	
	nsExec::ExecToLog '"$INSTDIR\mysql\bin\mysql" -u root -D orangehrm_mysql -e "INSERT INTO `ohrm_organization_gen_info`(`name`) VALUES ( $\' $CompanyName $\')"'
	
    
FunctionEnd

Function wel_show
         ; FindWindow $1 "#32770" "" $HWNDPARENT
         ; Cannot use FindWindow here because it finds the wrong
         ; dialog handle when pressing the back button!
         !if "${MUI_SYSVERSION}" >= 2.0
         StrCpy $1 $mui.WelcomePage
         !else
         StrCpy $1 $MUI_HWND
         !endif
         SetCtlColors $1 '' '0xFFFFFF'
 
         GetDlgItem $2 $1 1201
         SetCtlColors $2 '0xFF0000' '0xFFFFFF'
 
        ;  GetDlgItem $2 $1 1202
        ;  SetCtlColors $2 '0xFFFF00' '0xFFFFFF'
        ;  CreateFont $1 "$(^Font)" "10" ""
        ;  SendMessage $2 ${WM_SETFONT} $1 0
FunctionEnd



;--------------------------------
; Installer Sections

!include "installer.nsi"

;--------------------------------
; Uninstaller Sections

!include "uninstaller.nsi"
