unit App.uAppPaths;

{$CODEPAGE UTF8}

interface

type
  TAppPaths = class
  public
    class function AppDataFolder: string; static;
    class function DatabaseFile: string; static;
  end;

implementation

uses
  System.SysUtils,
  System.IOUtils;

class function TAppPaths.AppDataFolder: string;
begin
  Result := TPath.Combine(TPath.GetDocumentsPath, 'ParkFlowPro');
  if not TDirectory.Exists(Result) then
    TDirectory.CreateDirectory(Result);
end;

class function TAppPaths.DatabaseFile: string;
begin
  Result := TPath.Combine(AppDataFolder, 'parkflowpro.db');
end;

end.
