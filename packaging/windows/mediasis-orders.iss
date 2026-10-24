#ifndef MyAppVersion
  #define MyAppVersion "0.0.0"
#endif

#ifndef MyAppExeName
  #define MyAppExeName "mediasis_dashboard_app.exe"
#endif

#ifndef MyAppSourceDir
  #error MyAppSourceDir must be defined.
#endif

#ifndef MyOutputDir
  #define MyOutputDir "."
#endif

#define MyAppName "mediasis orders"
#define MyAppPublisher "Mediasis"
#define MyAppURL "https://dashboard.mediasis.cr"
#define MyAppId "{{11D6E4D1-44A8-49E3-B97A-6AF99D69D52E}}"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\Mediasis Orders
DefaultGroupName=Mediasis Orders
DisableProgramGroupPage=yes
OutputDir={#MyOutputDir}
OutputBaseFilename=mediasis-orders-setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#MyAppExeName}
SetupIconFile=..\..\windows\runner\resources\app_icon.ico

[Languages]
Name: "spanish"; MessagesFile: "compiler:Languages\Spanish.isl"

[Tasks]
Name: "desktopicon"; Description: "Crear acceso directo en el escritorio"; Flags: unchecked

[Files]
Source: "{#MyAppSourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\Mediasis Orders"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\Mediasis Orders"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Abrir Mediasis Orders"; Flags: nowait postinstall skipifsilent
