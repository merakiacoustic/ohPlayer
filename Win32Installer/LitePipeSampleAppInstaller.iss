; Script generated by the Inno Setup Script Wizard.
; SEE THE DOCUMENTATION FOR DETAILS ON CREATING INNO SETUP SCRIPT FILES!

#define MyAppName "LitePipeSampleApp"
#define MyAppPublisher "OpenHome"
#define MyAppURL "http://www.openhome.org/"
#define MyAppExeName "LitePipetestApp.exe"

; MySrcDir *must* be defined on the 'iscc' command line, via the '/d' option
; to give the full path to the directory holdinf the Win32 and Win32Insatller
; directories.
#ifndef MySrcDir
#error ERROR: The 'MySrcDir' location must be defined. 
#endif 

; MyAppVersion *must* be defined on the 'iscc' command line, via the '/d' option
; to set the release version.
#ifndef MyAppVersion
#error ERROR: The 'MyAppVersion' location must be defined. 
#endif

; Default to a Release build unless a Debug build is explicittly asked for.
#ifdef Debug
#define ReleaseType "Debug"
#else
#define ReleaseType "Release"
#endif

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
; (To generate a new GUID, click Tools | Generate GUID inside the IDE.)
AppId={{D0768E82-C330-46A1-BF8B-17D230C021EE}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
;AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={pf}\{#MyAppName}
DefaultGroupName={#MyAppName}
LicenseFile={#MySrcDir}\Win32\LitePipeSampleAppEULA.txt
DisableDirPage=auto
DisableProgramGroupPage=auto
OutputDir={#MySrcDir}\Win32Installer
OutputBaseFilename=setup
Compression=lzma
SolidCompression=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "{#MySrcDir}\Win32\Win32\{#ReleaseType}\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#MySrcDir}\dependencies\Windows-x86\ohMediaPlayer\res\*"; DestDir: "{app}\res"; Flags: ignoreversion recursesubdirs createallsubdirs

; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent

[Registry]
Root: HKCU; Subkey: "Software\OpenHome"; Flags: uninsdeletekeyifempty
Root: HKCU; Subkey: "Software\OpenHome\LitePipeTestApp"; Flags: uninsdeletekey
