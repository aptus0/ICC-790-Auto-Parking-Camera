unit App.uAppTypes;

{$CODEPAGE UTF8}

interface

type
  TCurrentUser = record
    Id: Integer;
    UserName: string;
    Role: string;
    IsAuthenticated: Boolean;
  end;

  TTariff = record
    Id: Integer;
    VehicleType: string;
    FirstHourFee: Currency;
    NextHourFee: Currency;
    DailyMaxFee: Currency;
  end;

  TInsideVehicleView = record
    Id: Integer;
    Plate: string;
    VehicleType: string;
    ParkingSlot: string;
    EntryTime: TDateTime;
    ElapsedMinutes: Integer;
    EstimatedFee: Currency;
  end;

  TSubscriberView = record
    Id: Integer;
    FullName: string;
    Phone: string;
    Plate: string;
    StartDate: TDateTime;
    EndDate: TDateTime;
    MonthlyFee: Currency;
    Status: string;
  end;

  TDashboardStats = record
    InsideCount: Integer;
    TotalCapacity: Integer;
    FreeCapacity: Integer;
    TodayEntries: Integer;
    TodayExits: Integer;
    ActiveSubscribers: Integer;
    TodayIncome: Currency;
  end;

implementation

end.
