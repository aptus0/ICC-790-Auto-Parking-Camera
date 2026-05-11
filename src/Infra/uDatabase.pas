unit Infra.uDatabase;

{$CODEPAGE UTF8}

interface

uses
  FireDAC.Comp.Client;

type
  TDatabase = class
  strict private
    class var FConnection: TFDConnection;
    class procedure ExecSQL(const ASQL: string); static;
    class function ScalarInt(const ASQL: string): Integer; static;
    class procedure CreateSchema; static;
    class procedure SeedDefaults; static;
  public
    class procedure Initialize; static;
    class procedure Finalize; static;
    class function Connection: TFDConnection; static;
    class function DatabaseFile: string; static;
  end;

implementation

uses
  System.SysUtils,
  App.uAppPaths,
  Security.uPasswordHasher,
  FireDAC.Stan.Param,
  FireDAC.Phys.SQLite;

class function TDatabase.DatabaseFile: string;
begin
  Result := TAppPaths.DatabaseFile;
end;

class function TDatabase.Connection: TFDConnection;
begin
  if FConnection = nil then
    Initialize;

  Result := FConnection;
end;

class procedure TDatabase.Initialize;
begin
  if FConnection <> nil then
    Exit;

  FConnection := TFDConnection.Create(nil);
  FConnection.DriverName := 'SQLite';
  FConnection.LoginPrompt := False;
  FConnection.Params.Values['Database'] := DatabaseFile;
  FConnection.Params.Values['LockingMode'] := 'Normal';
  FConnection.Params.Values['Synchronous'] := 'Normal';
  FConnection.Connected := True;

  ExecSQL('PRAGMA foreign_keys = ON');
  CreateSchema;
  SeedDefaults;
end;

class procedure TDatabase.Finalize;
begin
  if Assigned(FConnection) then
  begin
    FConnection.Connected := False;
    FreeAndNil(FConnection);
  end;
end;

class procedure TDatabase.ExecSQL(const ASQL: string);
begin
  Connection.ExecSQL(ASQL);
end;

class function TDatabase.ScalarInt(const ASQL: string): Integer;
var
  Q: TFDQuery;
begin
  Result := 0;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := Connection;
    Q.SQL.Text := ASQL;
    Q.Open;
    if not Q.Eof then
      Result := Q.Fields[0].AsInteger;
  finally
    Q.Free;
  end;
end;

class procedure TDatabase.CreateSchema;
begin
  ExecSQL(
    'CREATE TABLE IF NOT EXISTS users (' +
    'id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    'username TEXT NOT NULL UNIQUE,' +
    'password_hash TEXT NOT NULL,' +
    'role TEXT NOT NULL DEFAULT ''Admin'',' +
    'is_active INTEGER NOT NULL DEFAULT 1,' +
    'created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP' +
    ')');

  ExecSQL(
    'CREATE TABLE IF NOT EXISTS tariffs (' +
    'id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    'vehicle_type TEXT NOT NULL UNIQUE,' +
    'first_hour_fee NUMERIC NOT NULL,' +
    'next_hour_fee NUMERIC NOT NULL,' +
    'daily_max_fee NUMERIC NOT NULL DEFAULT 0,' +
    'created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,' +
    'updated_at DATETIME' +
    ')');

  ExecSQL(
    'CREATE TABLE IF NOT EXISTS subscribers (' +
    'id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    'full_name TEXT NOT NULL,' +
    'phone TEXT,' +
    'plate TEXT NOT NULL,' +
    'start_date DATETIME NOT NULL,' +
    'end_date DATETIME NOT NULL,' +
    'monthly_fee NUMERIC NOT NULL DEFAULT 0,' +
    'status TEXT NOT NULL DEFAULT ''ACTIVE'',' +
    'created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP' +
    ')');

  ExecSQL('CREATE INDEX IF NOT EXISTS ix_subscribers_plate ON subscribers(plate)');

  ExecSQL(
    'CREATE TABLE IF NOT EXISTS parking_sessions (' +
    'id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    'plate TEXT NOT NULL,' +
    'vehicle_type TEXT NOT NULL,' +
    'parking_slot TEXT,' +
    'entry_time DATETIME NOT NULL,' +
    'exit_time DATETIME,' +
    'total_minutes INTEGER,' +
    'total_fee NUMERIC,' +
    'payment_type TEXT,' +
    'status TEXT NOT NULL DEFAULT ''INSIDE'',' +
    'user_id INTEGER,' +
    'note TEXT,' +
    'created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,' +
    'FOREIGN KEY(user_id) REFERENCES users(id)' +
    ')');

  ExecSQL('CREATE INDEX IF NOT EXISTS ix_parking_plate_status ON parking_sessions(plate, status)');
  ExecSQL('CREATE INDEX IF NOT EXISTS ix_parking_entry_time ON parking_sessions(entry_time)');

  ExecSQL(
    'CREATE TABLE IF NOT EXISTS app_settings (' +
    'setting_key TEXT PRIMARY KEY,' +
    'setting_value TEXT NOT NULL,' +
    'updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP' +
    ')');
end;

class procedure TDatabase.SeedDefaults;
var
  Q: TFDQuery;
begin
  if ScalarInt('SELECT COUNT(*) FROM users') = 0 then
  begin
    Q := TFDQuery.Create(nil);
    try
      Q.Connection := Connection;
      Q.SQL.Text := 'INSERT INTO users(username, password_hash, role) VALUES(:u, :p, :r)';
      Q.ParamByName('u').AsString := 'admin';
      Q.ParamByName('p').AsString := TPasswordHasher.HashPassword('admin', 'admin123');
      Q.ParamByName('r').AsString := 'Admin';
      Q.ExecSQL;
    finally
      Q.Free;
    end;
  end;

  if ScalarInt('SELECT COUNT(*) FROM tariffs') = 0 then
  begin
    ExecSQL('INSERT INTO tariffs(vehicle_type, first_hour_fee, next_hour_fee, daily_max_fee) VALUES(''Otomobil'', 50, 30, 0)');
    ExecSQL('INSERT INTO tariffs(vehicle_type, first_hour_fee, next_hour_fee, daily_max_fee) VALUES(''Motosiklet'', 25, 15, 0)');
    ExecSQL('INSERT INTO tariffs(vehicle_type, first_hour_fee, next_hour_fee, daily_max_fee) VALUES(''Minibus'', 70, 40, 0)');
    ExecSQL('INSERT INTO tariffs(vehicle_type, first_hour_fee, next_hour_fee, daily_max_fee) VALUES(''Kamyonet'', 90, 50, 0)');
  end;

  if ScalarInt('SELECT COUNT(*) FROM app_settings WHERE setting_key = ''capacity''') = 0 then
    ExecSQL('INSERT INTO app_settings(setting_key, setting_value) VALUES(''capacity'', ''100'')');
end;

end.
