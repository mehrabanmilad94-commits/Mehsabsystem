[Setup]
AppName=MEHSAB Comprehensive Accounting System
AppVersion=1.0.0
AppPublisher=MEHSAB Software Solutions
AppPublisherURL=https://www.mehsab.ir
AppSupportURL=https://support.mehsab.ir
AppUpdatesURL=https://www.mehsab.ir/updates
DefaultDirName={autopf}\MEHSAB
DefaultGroupName=MEHSAB Accounting
AllowNoIcons=yes
LicenseFile=License.txt
InfoBeforeFile=Readme.txt
OutputDir=Setup
OutputBaseFilename=MEHSAB_Setup
SetupIconFile=Resources\MEHSAB.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
MinVersion=10.0.17763
PrivilegesRequired=admin

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "farsi"; MessagesFile: "compiler:Languages\Farsi.isl"

[CustomMessages]
farsi.WelcomeLabel2=به نصب‌کننده سیستم جامع حسابداری و مالی MEHSAB خوش آمدید.%n%nاین برنامه شامل تمامی ماژول‌های مورد نیاز برای مدیریت مالی و حسابداری کسب و کار شما است.
farsi.ClickNext=برای ادامه روی بعدی کلیک کنید.
farsi.BeveledLabel=سیستم حسابداری MEHSAB - نسخه 1.0

[Dirs]
Name: "{app}"
Name: "{app}\bin"
Name: "{app}\Reports"
Name: "{app}\Templates"
Name: "{app}\Database"
Name: "{app}\Backups"
Name: "{app}\Backups\Daily"
Name: "{app}\Backups\Weekly"
Name: "{app}\Backups\Monthly"
Name: "{app}\Logs"
Name: "{app}\Documentation"
Name: "{app}\Resources"
Name: "{commonappdata}\MEHSAB"
Name: "{commonappdata}\MEHSAB\Config"

[Files]
; Main Application Files
Source: "MEHSAB.Presentation.WPF.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "MEHSAB.Application.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "MEHSAB.Domain.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "MEHSAB.Infrastructure.dll"; DestDir: "{app}"; Flags: ignoreversion

; .NET Runtime (if not already installed)
Source: "Prerequisites\dotnet-runtime-8.0-win-x64.exe"; DestDir: "{tmp}"; Flags: deleteafterinstall

; SQL Server Express LocalDB
Source: "Prerequisites\SqlLocalDB.msi"; DestDir: "{tmp}"; Flags: deleteafterinstall

; Database Scripts
Source: "Database\MEHSAB_Database_ERD.sql"; DestDir: "{app}\Database"; Flags: ignoreversion
Source: "Database\InitialData.sql"; DestDir: "{app}\Database"; Flags: ignoreversion
Source: "Database\ChartOfAccounts.sql"; DestDir: "{app}\Database"; Flags: ignoreversion

; Configuration Files
Source: "appsettings.json"; DestDir: "{app}"; Flags: ignoreversion
Source: "appsettings.Production.json"; DestDir: "{app}"; Flags: ignoreversion

; Report Templates
Source: "Reports\*.mrt"; DestDir: "{app}\Reports"; Flags: ignoreversion recursesubdirs
Source: "Reports\*.rdlc"; DestDir: "{app}\Reports"; Flags: ignoreversion recursesubdirs

; Import/Export Templates
Source: "Templates\Excel\*.xlsx"; DestDir: "{app}\Templates\Excel"; Flags: ignoreversion
Source: "Templates\CSV\*.csv"; DestDir: "{app}\Templates\CSV"; Flags: ignoreversion

; Documentation
Source: "Documentation\*.pdf"; DestDir: "{app}\Documentation"; Flags: ignoreversion
Source: "MEHSAB_Installation_Guide.md"; DestDir: "{app}\Documentation"; DestName: "Installation_Guide.md"; Flags: ignoreversion

; Resources
Source: "Resources\MEHSAB.ico"; DestDir: "{app}\Resources"; Flags: ignoreversion
Source: "Resources\Logo.png"; DestDir: "{app}\Resources"; Flags: ignoreversion

; Dependencies
Source: "Dependencies\*.dll"; DestDir: "{app}"; Flags: ignoreversion

[Registry]
Root: HKCU; Subkey: "Software\MEHSAB"; ValueType: string; ValueName: "InstallPath"; ValueData: "{app}"
Root: HKCU; Subkey: "Software\MEHSAB"; ValueType: string; ValueName: "Version"; ValueData: "1.0.0"
Root: HKCU; Subkey: "Software\MEHSAB"; ValueType: dword; ValueName: "FirstRun"; ValueData: 1

[Icons]
Name: "{group}\MEHSAB حسابداری"; Filename: "{app}\MEHSAB.Presentation.WPF.exe"; WorkingDir: "{app}"; IconFilename: "{app}\Resources\MEHSAB.ico"
Name: "{group}\راهنمای کاربری"; Filename: "{app}\Documentation\User_Manual.pdf"
Name: "{group}\پشتیبانی فنی"; Filename: "https://support.mehsab.ir"
Name: "{group}\حذف نرم‌افزار"; Filename: "{uninstallexe}"
Name: "{autodesktop}\MEHSAB حسابداری"; Filename: "{app}\MEHSAB.Presentation.WPF.exe"; WorkingDir: "{app}"; IconFilename: "{app}\Resources\MEHSAB.ico"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "ایجاد میانبر روی دسکتاپ"; GroupDescription: "میانبرها:"
Name: "quicklaunchicon"; Description: "ایجاد میانبر در Quick Launch"; GroupDescription: "میانبرها:"; Flags: unchecked

[Run]
; Install .NET Runtime if not present
Filename: "{tmp}\dotnet-runtime-8.0-win-x64.exe"; Parameters: "/quiet /norestart"; StatusMsg: "در حال نصب .NET Runtime..."; Check: NeedsDotNetRuntime

; Install SQL Server LocalDB if not present
Filename: "msiexec.exe"; Parameters: "/i ""{tmp}\SqlLocalDB.msi"" /quiet /norestart IACCEPTSQLLOCALDBLICENSETERMS=YES"; StatusMsg: "در حال نصب SQL Server LocalDB..."; Check: NeedsSqlLocalDB

; Create Database
Filename: "{app}\MEHSAB.Presentation.WPF.exe"; Parameters: "--setup-database"; StatusMsg: "در حال ایجاد پایگاه داده..."; Flags: nowait

; Launch application after installation
Filename: "{app}\MEHSAB.Presentation.WPF.exe"; Description: "اجرای MEHSAB حسابداری"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: files; Name: "{app}\Logs\*.log"
Type: files; Name: "{commonappdata}\MEHSAB\Config\*.json"

[Code]
function NeedsDotNetRuntime(): Boolean;
var
  Version: String;
begin
  Result := not RegQueryStringValue(HKLM, 'SOFTWARE\dotnet\Setup\InstalledVersions\x64\sharedhost', 'Version', Version) or (CompareVersion(Version, '8.0.0') < 0);
end;

function NeedsSqlLocalDB(): Boolean;
var
  Version: String;
begin
  Result := not RegQueryStringValue(HKLM, 'SOFTWARE\Microsoft\Microsoft SQL Server Local DB\Installed Versions\15.0', 'Version', Version);
end;

function CompareVersion(V1, V2: String): Integer;
var
  P, N1, N2: Integer;
begin
  Result := 0;
  while (Result = 0) and ((V1 <> '') or (V2 <> '')) do
  begin
    P := Pos('.', V1);
    if P > 0 then
    begin
      N1 := StrToInt(Copy(V1, 1, P - 1));
      Delete(V1, 1, P);
    end
    else if V1 <> '' then
    begin
      N1 := StrToInt(V1);
      V1 := '';
    end
    else
    begin
      N1 := 0;
    end;

    P := Pos('.', V2);
    if P > 0 then
    begin
      N2 := StrToInt(Copy(V2, 1, P - 1));
      Delete(V2, 1, P);
    end
    else if V2 <> '' then
    begin
      N2 := StrToInt(V2);
      V2 := '';
    end
    else
    begin
      N2 := 0;
    end;

    if N1 < N2 then
      Result := -1
    else if N1 > N2 then
      Result := 1;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ConnectionString: String;
  ResultCode: Integer;
begin
  if CurStep = ssPostInstall then
  begin
    // Create initial configuration
    ConnectionString := 'Server=(localdb)\MSSQLLocalDB;Database=MEHSAB;Integrated Security=true;';
    
    // Save connection string to config file
    SaveStringToFile(ExpandConstant('{commonappdata}\MEHSAB\Config\connection.txt'), ConnectionString, False);
    
    // Set folder permissions
    Exec(ExpandConstant('{sys}\icacls.exe'), ExpandConstant('"{commonappdata}\MEHSAB" /grant Users:(OI)(CI)F'), '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  end;
end;

function InitializeSetup(): Boolean;
begin
  Result := True;
  
  // Check Windows version
  if (GetWindowsVersion < $0A000000) then // Windows 10 (10.0)
  begin
    MsgBox('این نرم‌افزار نیاز به Windows 10 یا جدیدتر دارد.', mbError, MB_OK);
    Result := False;
  end;
end;

procedure InitializeWizard();
begin
  // Set RTL layout for Persian language
  if ActiveLanguage = 'farsi' then
  begin
    WizardForm.FlipChildren(True);
  end;
end;