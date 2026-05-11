unit Services.uParkingService;

{$CODEPAGE UTF8}

interface

uses
  App.uAppTypes,
  Services.uTariffService,
  Services.uSubscriberService;

type
  TParkingService = class
  strict private
    FTariffService: TTariffService;
    FSubscriberService: TSubscriberService;
    function InternalCalculateFee(const APlate, AVehicleType: string; AEntryTime, AExitTime: TDateTime; out ATotalMinutes: Integer): Currency;
  public
    constructor Create;
    destructor Destroy; override;

    function NormalizePlate(const APlate: string): string;
    function IsVehicleInside(const APlate: string): Boolean;
    procedure RegisterEntry(const APlate, AVehicleType, AParkingSlot, ANote: string; AUserId: Integer);
    function GetOpenSession(const APlate: string; out ASessionId: Integer; out AVehicleType, AParkingSlot: string; out AEntryTime: TDateTime; out AElapsedMinutes: Integer; out AEstimatedFee: Currency): Boolean;
    procedure CloseSession(const APlate, APaymentType: string; out ATotalMinutes: Integer; out ATotalFee: Currency);
    function CalculateFeePreview(const APlate: string; out ATotalMinutes: Integer): Currency;
    function GetInsideVehicles: TArray<TInsideVehicleView>;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  System.Generics.Collections,
  System.Math,
  FireDAC.Comp.Client,
  Infra.uDatabase;

constructor TParkingService.Create;
begin
  inherited Create;
  FTariffService := TTariffService.Create;
  FSubscriberService := TSubscriberService.Create;
end;

destructor TParkingService.Destroy;
begin
  FSubscriberService.Free;
  FTariffService.Free;
  inherited Destroy;
end;

function TParkingService.NormalizePlate(const APlate: string): string;
begin
  Result := UpperCase(Trim(APlate));
  while Pos('  ', Result) > 0 do
    Result := StringReplace(Result, '  ', ' ', [rfReplaceAll]);
end;

function TParkingService.IsVehicleInside(const APlate: string): Boolean;
var
  Q: TFDQuery;
begin
  Result := False;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := TDatabase.Connection;
    Q.SQL.Text := 'SELECT id FROM parking_sessions WHERE upper(plate) = upper(:plate) AND status = ''INSIDE'' LIMIT 1';
    Q.ParamByName('plate').AsString := NormalizePlate(APlate);
    Q.Open;
    Result := not Q.Eof;
  finally
    Q.Free;
  end;
end;

procedure TParkingService.RegisterEntry(const APlate, AVehicleType, AParkingSlot, ANote: string; AUserId: Integer);
var
  Q: TFDQuery;
  LPlate: string;
begin
  LPlate := NormalizePlate(APlate);

  if LPlate = '' then
    raise Exception.Create('Plaka boş olamaz.');

  if Trim(AVehicleType) = '' then
    raise Exception.Create('Araç tipi boş olamaz.');

  if IsVehicleInside(LPlate) then
    raise Exception.Create('Bu plaka zaten içeride görünüyor. Önce çıkış işlemi yapılmalıdır.');

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := TDatabase.Connection;
    Q.SQL.Text :=
      'INSERT INTO parking_sessions(plate, vehicle_type, parking_slot, entry_time, status, user_id, note) ' +
      'VALUES(:plate, :vehicle_type, :parking_slot, :entry_time, ''INSIDE'', :user_id, :note)';
    Q.ParamByName('plate').AsString := LPlate;
    Q.ParamByName('vehicle_type').AsString := Trim(AVehicleType);
    Q.ParamByName('parking_slot').AsString := Trim(AParkingSlot);
    Q.ParamByName('entry_time').AsDateTime := Now;
    Q.ParamByName('user_id').AsInteger := AUserId;
    Q.ParamByName('note').AsString := Trim(ANote);
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

function TParkingService.InternalCalculateFee(const APlate, AVehicleType: string; AEntryTime, AExitTime: TDateTime; out ATotalMinutes: Integer): Currency;
var
  Tariff: TTariff;
  ExtraMinutes: Integer;
  ExtraHours: Integer;
begin
  ATotalMinutes := MinutesBetween(AExitTime, AEntryTime);
  if ATotalMinutes < 1 then
    ATotalMinutes := 1;

  if FSubscriberService.IsActiveSubscriber(APlate) then
    Exit(0);

  if not FTariffService.GetByVehicleType(AVehicleType, Tariff) then
    raise Exception.Create('Bu araç tipi için tarife bulunamadı: ' + AVehicleType);

  if ATotalMinutes <= 60 then
    Result := Tariff.FirstHourFee
  else
  begin
    ExtraMinutes := ATotalMinutes - 60;
    ExtraHours := Ceil(ExtraMinutes / 60);
    Result := Tariff.FirstHourFee + (ExtraHours * Tariff.NextHourFee);
  end;

  if (Tariff.DailyMaxFee > 0) and (Result > Tariff.DailyMaxFee) then
    Result := Tariff.DailyMaxFee;
end;

function TParkingService.GetOpenSession(const APlate: string; out ASessionId: Integer; out AVehicleType, AParkingSlot: string; out AEntryTime: TDateTime; out AElapsedMinutes: Integer; out AEstimatedFee: Currency): Boolean;
var
  Q: TFDQuery;
begin
  Result := False;
  ASessionId := 0;
  AVehicleType := '';
  AParkingSlot := '';
  AEntryTime := 0;
  AElapsedMinutes := 0;
  AEstimatedFee := 0;

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := TDatabase.Connection;
    Q.SQL.Text :=
      'SELECT id, vehicle_type, parking_slot, entry_time FROM parking_sessions ' +
      'WHERE upper(plate) = upper(:plate) AND status = ''INSIDE'' ' +
      'ORDER BY entry_time DESC LIMIT 1';
    Q.ParamByName('plate').AsString := NormalizePlate(APlate);
    Q.Open;

    if not Q.Eof then
    begin
      ASessionId := Q.FieldByName('id').AsInteger;
      AVehicleType := Q.FieldByName('vehicle_type').AsString;
      AParkingSlot := Q.FieldByName('parking_slot').AsString;
      AEntryTime := Q.FieldByName('entry_time').AsDateTime;
      AEstimatedFee := InternalCalculateFee(APlate, AVehicleType, AEntryTime, Now, AElapsedMinutes);
      Result := True;
    end;
  finally
    Q.Free;
  end;
end;

function TParkingService.CalculateFeePreview(const APlate: string; out ATotalMinutes: Integer): Currency;
var
  LSessionId: Integer;
  LVehicleType: string;
  LSlot: string;
  LEntry: TDateTime;
begin
  if not GetOpenSession(APlate, LSessionId, LVehicleType, LSlot, LEntry, ATotalMinutes, Result) then
    raise Exception.Create('İçeride bu plakaya ait açık kayıt bulunamadı.');
end;

procedure TParkingService.CloseSession(const APlate, APaymentType: string; out ATotalMinutes: Integer; out ATotalFee: Currency);
var
  LSessionId: Integer;
  LVehicleType: string;
  LSlot: string;
  LEntry: TDateTime;
  Q: TFDQuery;
begin
  if Trim(APaymentType) = '' then
    raise Exception.Create('Ödeme tipi seçilmelidir.');

  if not GetOpenSession(APlate, LSessionId, LVehicleType, LSlot, LEntry, ATotalMinutes, ATotalFee) then
    raise Exception.Create('İçeride bu plakaya ait açık kayıt bulunamadı.');

  Q := TFDQuery.Create(nil);
  try
    Q.Connection := TDatabase.Connection;
    Q.SQL.Text :=
      'UPDATE parking_sessions SET ' +
      'exit_time = :exit_time, total_minutes = :total_minutes, total_fee = :total_fee, ' +
      'payment_type = :payment_type, status = ''CLOSED'' ' +
      'WHERE id = :id';
    Q.ParamByName('exit_time').AsDateTime := Now;
    Q.ParamByName('total_minutes').AsInteger := ATotalMinutes;
    Q.ParamByName('total_fee').AsCurrency := ATotalFee;
    Q.ParamByName('payment_type').AsString := Trim(APaymentType);
    Q.ParamByName('id').AsInteger := LSessionId;
    Q.ExecSQL;
  finally
    Q.Free;
  end;
end;

function TParkingService.GetInsideVehicles: TArray<TInsideVehicleView>;
var
  Q: TFDQuery;
  L: TList<TInsideVehicleView>;
  V: TInsideVehicleView;
begin
  L := TList<TInsideVehicleView>.Create;
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := TDatabase.Connection;
    Q.SQL.Text :=
      'SELECT id, plate, vehicle_type, parking_slot, entry_time ' +
      'FROM parking_sessions WHERE status = ''INSIDE'' ORDER BY entry_time DESC';
    Q.Open;

    while not Q.Eof do
    begin
      V.Id := Q.FieldByName('id').AsInteger;
      V.Plate := Q.FieldByName('plate').AsString;
      V.VehicleType := Q.FieldByName('vehicle_type').AsString;
      V.ParkingSlot := Q.FieldByName('parking_slot').AsString;
      V.EntryTime := Q.FieldByName('entry_time').AsDateTime;
      V.EstimatedFee := InternalCalculateFee(V.Plate, V.VehicleType, V.EntryTime, Now, V.ElapsedMinutes);
      L.Add(V);
      Q.Next;
    end;

    Result := L.ToArray;
  finally
    Q.Free;
    L.Free;
  end;
end;

end.
