unit Services.uSettingsService;

{$CODEPAGE UTF8}

interface

type
  TSettingsService = class
  public
    function GetValue(const AKey, ADefault: string): string;
    procedure SetValue(const AKey, AValue: string);
    function GetCapacity: Integer;
    procedure SetCapacity(ACapacity: Integer);
  end;

implementation

uses
  System.SysUtils,
  FireDAC.Comp.Client,
  Infra.uDatabase;

function TSettingsService.GetValue(const AKey, ADefault: string): string;
var
  Q: TFDQuery;
begin
  Result := ADefault;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := TDatabase.Connection;
    Q.SQL.Text := 'SELECT setting_value FROM app_settings WHERE setting_key = :k';
    Q.ParamByName('k').AsString := AKey;
    Q.Open;
    if not Q.Eof then
      Result := Q.FieldByName('setting_value').AsString;
  finally
    Q.Free;
  end;
end;

procedure TSettingsService.SetValue(const AKey, AValue: string);
var
  Q: TFDQuery;
begin
  if Trim(AKey) = '' then
    raise Exception.Create('Ayar anahtarı boş olamaz.');

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := TDatabase.Connection;
    Q.SQL.Text :=
      'INSERT INTO app_settings(setting_key, setting_value, updated_at) VALUES(:k, :v, CURRENT_TIMESTAMP) ' +
      'ON CONFLICT(setting_key) DO UPDATE SET setting_value = excluded.setting_value, updated_at = CURRENT_TIMESTAMP';
    Q.ParamByName('k').AsString := Trim(AKey);
    Q.ParamByName('v').AsString := AValue;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

function TSettingsService.GetCapacity: Integer;
begin
  Result := StrToIntDef(GetValue('capacity', '100'), 100);
end;

procedure TSettingsService.SetCapacity(ACapacity: Integer);
begin
  if ACapacity < 1 then
    raise Exception.Create('Kapasite en az 1 olmalıdır.');

  SetValue('capacity', IntToStr(ACapacity));
end;

end.
