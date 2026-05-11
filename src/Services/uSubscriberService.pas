unit Services.uSubscriberService;

{$CODEPAGE UTF8}

interface

uses
  App.uAppTypes;

type
  TSubscriberService = class
  public
    function NormalizePlate(const APlate: string): string;
    function IsActiveSubscriber(const APlate: string): Boolean;
    function GetAll: TArray<TSubscriberView>;
    procedure AddSubscriber(const AFullName, APhone, APlate: string; AStartDate, AEndDate: TDateTime; AMonthlyFee: Currency);
    function CountActiveSubscribers: Integer;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  FireDAC.Comp.Client,
  Infra.uDatabase;

function TSubscriberService.NormalizePlate(const APlate: string): string;
begin
  Result := UpperCase(Trim(APlate));
  while Pos('  ', Result) > 0 do
    Result := StringReplace(Result, '  ', ' ', [rfReplaceAll]);
end;

function TSubscriberService.IsActiveSubscriber(const APlate: string): Boolean;
var
  Q: TFDQuery;
begin
  Result := False;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := TDatabase.Connection;
    Q.SQL.Text :=
      'SELECT id FROM subscribers ' +
      'WHERE upper(plate) = upper(:plate) ' +
      'AND status = ''ACTIVE'' ' +
      'AND :today BETWEEN start_date AND end_date ' +
      'LIMIT 1';
    Q.ParamByName('plate').AsString := NormalizePlate(APlate);
    Q.ParamByName('today').AsDateTime := Date;
    Q.Open;
    Result := not Q.Eof;
  finally
    Q.Free;
  end;
end;

function TSubscriberService.CountActiveSubscribers: Integer;
var
  Q: TFDQuery;
begin
  Result := 0;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := TDatabase.Connection;
    Q.SQL.Text := 'SELECT COUNT(*) AS c FROM subscribers WHERE status = ''ACTIVE'' AND :today BETWEEN start_date AND end_date';
    Q.ParamByName('today').AsDateTime := Date;
    Q.Open;
    Result := Q.FieldByName('c').AsInteger;
  finally
    Q.Free;
  end;
end;

function TSubscriberService.GetAll: TArray<TSubscriberView>;
var
  Q: TFDQuery;
  L: TList<TSubscriberView>;
  S: TSubscriberView;
begin
  L := TList<TSubscriberView>.Create;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := TDatabase.Connection;
    Q.SQL.Text :=
      'SELECT id, full_name, phone, plate, start_date, end_date, monthly_fee, status ' +
      'FROM subscribers ORDER BY end_date DESC, full_name';
    Q.Open;

    while not Q.Eof do
    begin
      S.Id := Q.FieldByName('id').AsInteger;
      S.FullName := Q.FieldByName('full_name').AsString;
      S.Phone := Q.FieldByName('phone').AsString;
      S.Plate := Q.FieldByName('plate').AsString;
      S.StartDate := Q.FieldByName('start_date').AsDateTime;
      S.EndDate := Q.FieldByName('end_date').AsDateTime;
      S.MonthlyFee := Q.FieldByName('monthly_fee').AsCurrency;
      S.Status := Q.FieldByName('status').AsString;
      L.Add(S);
      Q.Next;
    end;

    Result := L.ToArray;
  finally
    Q.Free;
    L.Free;
  end;
end;

procedure TSubscriberService.AddSubscriber(const AFullName, APhone, APlate: string; AStartDate, AEndDate: TDateTime; AMonthlyFee: Currency);
var
  Q: TFDQuery;
begin
  if Trim(AFullName) = '' then
    raise Exception.Create('Abone adı boş olamaz.');

  if NormalizePlate(APlate) = '' then
    raise Exception.Create('Plaka boş olamaz.');

  if AEndDate < AStartDate then
    raise Exception.Create('Bitiş tarihi başlangıç tarihinden önce olamaz.');

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := TDatabase.Connection;
    Q.SQL.Text :=
      'INSERT INTO subscribers(full_name, phone, plate, start_date, end_date, monthly_fee, status) ' +
      'VALUES(:full_name, :phone, :plate, :start_date, :end_date, :monthly_fee, ''ACTIVE'')';
    Q.ParamByName('full_name').AsString := Trim(AFullName);
    Q.ParamByName('phone').AsString := Trim(APhone);
    Q.ParamByName('plate').AsString := NormalizePlate(APlate);
    Q.ParamByName('start_date').AsDateTime := AStartDate;
    Q.ParamByName('end_date').AsDateTime := AEndDate;
    Q.ParamByName('monthly_fee').AsCurrency := AMonthlyFee;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

end.
