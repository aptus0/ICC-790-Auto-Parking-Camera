unit Services.uReportService;

{$CODEPAGE UTF8}

interface

uses
  App.uAppTypes;

type
  TReportService = class
  public
    function GetDashboardStats: TDashboardStats;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  FireDAC.Comp.Client,
  Infra.uDatabase,
  Services.uSettingsService,
  Services.uSubscriberService;

function QueryInt(const ASQL: string; AStartDate, AEndDate: TDateTime): Integer;
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := TDatabase.Connection;
    Q.SQL.Text := ASQL;
    if Pos(':start_date', ASQL) > 0 then
      Q.ParamByName('start_date').AsDateTime := AStartDate;
    if Pos(':end_date', ASQL) > 0 then
      Q.ParamByName('end_date').AsDateTime := AEndDate;
    Q.Open;
    Result := Q.Fields[0].AsInteger;
  finally
    Q.Free;
  end;
end;

function QueryCurrency(const ASQL: string; AStartDate, AEndDate: TDateTime): Currency;
var
  Q: TFDQuery;
begin
  Q := TFDQuery.Create(nil);
  try
    Q.Connection := TDatabase.Connection;
    Q.SQL.Text := ASQL;
    Q.ParamByName('start_date').AsDateTime := AStartDate;
    Q.ParamByName('end_date').AsDateTime := AEndDate;
    Q.Open;
    Result := Q.Fields[0].AsCurrency;
  finally
    Q.Free;
  end;
end;

function TReportService.GetDashboardStats: TDashboardStats;
var
  Settings: TSettingsService;
  Subscribers: TSubscriberService;
  D1, D2: TDateTime;
begin
  Result := Default(TDashboardStats);
  D1 := StartOfTheDay(Now);
  D2 := IncDay(D1, 1);

  Settings := TSettingsService.Create;
  Subscribers := TSubscriberService.Create;
  try
    Result.TotalCapacity := Settings.GetCapacity;
    Result.InsideCount := QueryInt('SELECT COUNT(*) FROM parking_sessions WHERE status = ''INSIDE''', 0, 0);
    Result.FreeCapacity := Result.TotalCapacity - Result.InsideCount;
    if Result.FreeCapacity < 0 then
      Result.FreeCapacity := 0;

    Result.TodayEntries := QueryInt(
      'SELECT COUNT(*) FROM parking_sessions WHERE entry_time >= :start_date AND entry_time < :end_date',
      D1, D2);

    Result.TodayExits := QueryInt(
      'SELECT COUNT(*) FROM parking_sessions WHERE exit_time >= :start_date AND exit_time < :end_date AND status = ''CLOSED''',
      D1, D2);

    Result.TodayIncome := QueryCurrency(
      'SELECT COALESCE(SUM(total_fee), 0) FROM parking_sessions WHERE exit_time >= :start_date AND exit_time < :end_date AND status = ''CLOSED''',
      D1, D2);

    Result.ActiveSubscribers := Subscribers.CountActiveSubscribers;
  finally
    Subscribers.Free;
    Settings.Free;
  end;
end;

end.
