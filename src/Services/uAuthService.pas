unit Services.uAuthService;

{$CODEPAGE UTF8}

interface

uses
  App.uAppTypes;

type
  TAuthService = class
  public
    function Login(const AUserName, APassword: string; out AUser: TCurrentUser): Boolean;
  end;

implementation

uses
  System.SysUtils,
  FireDAC.Comp.Client,
  Infra.uDatabase,
  Security.uPasswordHasher;

function TAuthService.Login(const AUserName, APassword: string; out AUser: TCurrentUser): Boolean;
var
  Q: TFDQuery;
  LHash: string;
begin
  Result := False;
  AUser := Default(TCurrentUser);

  LHash := TPasswordHasher.HashPassword(AUserName, APassword);

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := TDatabase.Connection;
    Q.SQL.Text :=
      'SELECT id, username, role FROM users ' +
      'WHERE lower(username) = lower(:u) AND password_hash = :p AND is_active = 1';
    Q.ParamByName('u').AsString := Trim(AUserName);
    Q.ParamByName('p').AsString := LHash;
    Q.Open;

    if not Q.Eof then
    begin
      AUser.Id := Q.FieldByName('id').AsInteger;
      AUser.UserName := Q.FieldByName('username').AsString;
      AUser.Role := Q.FieldByName('role').AsString;
      AUser.IsAuthenticated := True;
      Result := True;
    end;
  finally
    Q.Free;
  end;
end;

end.
