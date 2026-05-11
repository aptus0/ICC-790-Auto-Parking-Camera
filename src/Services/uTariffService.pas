unit Services.uTariffService;

{$CODEPAGE UTF8}

interface

uses
  App.uAppTypes;

type
  TTariffService = class
  public
    function GetAll: TArray<TTariff>;
    function GetByVehicleType(const AVehicleType: string; out ATariff: TTariff): Boolean;
    procedure SaveTariff(const AVehicleType: string; AFirstHourFee, ANextHourFee, ADailyMaxFee: Currency);
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  FireDAC.Comp.Client,
  Infra.uDatabase;

function TTariffService.GetAll: TArray<TTariff>;
var
  Q: TFDQuery;
  L: TList<TTariff>;
  T: TTariff;
begin
  L := TList<TTariff>.Create;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := TDatabase.Connection;
    Q.SQL.Text := 'SELECT id, vehicle_type, first_hour_fee, next_hour_fee, daily_max_fee FROM tariffs ORDER BY vehicle_type';
    Q.Open;

    while not Q.Eof do
    begin
      T.Id := Q.FieldByName('id').AsInteger;
      T.VehicleType := Q.FieldByName('vehicle_type').AsString;
      T.FirstHourFee := Q.FieldByName('first_hour_fee').AsCurrency;
      T.NextHourFee := Q.FieldByName('next_hour_fee').AsCurrency;
      T.DailyMaxFee := Q.FieldByName('daily_max_fee').AsCurrency;
      L.Add(T);
      Q.Next;
    end;

    Result := L.ToArray;
  finally
    Q.Free;
    L.Free;
  end;
end;

function TTariffService.GetByVehicleType(const AVehicleType: string; out ATariff: TTariff): Boolean;
var
  Q: TFDQuery;
begin
  Result := False;
  ATariff := Default(TTariff);

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := TDatabase.Connection;
    Q.SQL.Text := 'SELECT id, vehicle_type, first_hour_fee, next_hour_fee, daily_max_fee FROM tariffs WHERE vehicle_type = :t';
    Q.ParamByName('t').AsString := AVehicleType;
    Q.Open;

    if not Q.Eof then
    begin
      ATariff.Id := Q.FieldByName('id').AsInteger;
      ATariff.VehicleType := Q.FieldByName('vehicle_type').AsString;
      ATariff.FirstHourFee := Q.FieldByName('first_hour_fee').AsCurrency;
      ATariff.NextHourFee := Q.FieldByName('next_hour_fee').AsCurrency;
      ATariff.DailyMaxFee := Q.FieldByName('daily_max_fee').AsCurrency;
      Result := True;
    end;
  finally
    Q.Free;
  end;
end;

procedure TTariffService.SaveTariff(const AVehicleType: string; AFirstHourFee, ANextHourFee, ADailyMaxFee: Currency);
var
  Q: TFDQuery;
begin
  if Trim(AVehicleType) = '' then
    raise Exception.Create('Araç tipi boş olamaz.');

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := TDatabase.Connection;
    Q.SQL.Text :=
      'INSERT INTO tariffs(vehicle_type, first_hour_fee, next_hour_fee, daily_max_fee, updated_at) ' +
      'VALUES(:vehicle_type, :first_hour_fee, :next_hour_fee, :daily_max_fee, CURRENT_TIMESTAMP) ' +
      'ON CONFLICT(vehicle_type) DO UPDATE SET ' +
      'first_hour_fee = excluded.first_hour_fee, ' +
      'next_hour_fee = excluded.next_hour_fee, ' +
      'daily_max_fee = excluded.daily_max_fee, ' +
      'updated_at = CURRENT_TIMESTAMP';
    Q.ParamByName('vehicle_type').AsString := Trim(AVehicleType);
    Q.ParamByName('first_hour_fee').AsCurrency := AFirstHourFee;
    Q.ParamByName('next_hour_fee').AsCurrency := ANextHourFee;
    Q.ParamByName('daily_max_fee').AsCurrency := ADailyMaxFee;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

end.
