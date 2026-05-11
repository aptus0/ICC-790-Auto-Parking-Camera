unit Security.uPasswordHasher;

{$CODEPAGE UTF8}

interface

type
  TPasswordHasher = class
  public
    class function HashPassword(const AUserName, APassword: string): string; static;
  end;

implementation

uses
  System.SysUtils,
  System.Hash;

class function TPasswordHasher.HashPassword(const AUserName, APassword: string): string;
begin
  // Demo/proje başlangıcı için SHA-256. Üretimde kullanıcı başı salt + PBKDF2/Argon2 tercih edin.
  Result := THashSHA2.GetHashString(UpperCase(Trim(AUserName)) + ':' + APassword);
end;

end.
