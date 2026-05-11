unit UI.uMainForm;

{$CODEPAGE UTF8}

interface

uses
  System.SysUtils,
  System.Classes,
  System.Types,
  FMX.Types,
  FMX.Controls,
  FMX.Forms,
  FMX.StdCtrls,
  FMX.Layouts,
  FMX.Edit,
  FMX.ListBox,
  FMX.Memo,
  FMX.Objects,
  App.uAppTypes,
  Services.uAuthService,
  Services.uParkingService,
  Services.uTariffService,
  Services.uSubscriberService,
  Services.uReportService,
  Services.uSettingsService;

type
  TMainForm = class(TForm)
  private
    FRoot: TLayout;
    FContent: TLayout;
    FFooterLabel: TLabel;

    FAuthService: TAuthService;
    FParkingService: TParkingService;
    FTariffService: TTariffService;
    FSubscriberService: TSubscriberService;
    FReportService: TReportService;
    FSettingsService: TSettingsService;
    FCurrentUser: TCurrentUser;

    FLoginUserEdit: TEdit;
    FLoginPasswordEdit: TEdit;

    FEntryPlateEdit: TEdit;
    FEntryTypeCombo: TComboBox;
    FEntrySlotEdit: TEdit;
    FEntryNoteEdit: TEdit;

    FExitPlateEdit: TEdit;
    FExitPaymentCombo: TComboBox;
    FExitResultLabel: TLabel;

    FSubscriberNameEdit: TEdit;
    FSubscriberPhoneEdit: TEdit;
    FSubscriberPlateEdit: TEdit;
    FSubscriberStartEdit: TEdit;
    FSubscriberEndEdit: TEdit;
    FSubscriberFeeEdit: TEdit;

    FTariffTypeEdit: TEdit;
    FTariffFirstEdit: TEdit;
    FTariffNextEdit: TEdit;
    FTariffDailyMaxEdit: TEdit;

    FCapacityEdit: TEdit;

    procedure ClearForm;
    procedure ClearContent;
    procedure BuildLoginScreen;
    procedure BuildShell;
    procedure RefreshFooter;

    function AddLabel(AParent: TFmxObject; const AText: string; AHeight: Single = 28): TLabel;
    function AddTitle(AParent: TFmxObject; const AText: string): TLabel;
    function AddEdit(AParent: TFmxObject; const APrompt: string): TEdit;
    function AddButton(AParent: TFmxObject; const AText: string; AOnClick: TNotifyEvent): TButton;
    function AddCombo(AParent: TFmxObject; const AItems: array of string): TComboBox;
    function AddCard(AParent: TFmxObject; const ATitle, AValue: string): TRectangle;
    function TryReadCurrency(AEdit: TEdit; const AFieldName: string; out AValue: Currency): Boolean;

    procedure DoLogin(Sender: TObject);
    procedure DoLogout(Sender: TObject);

    procedure ShowDashboard(Sender: TObject = nil);
    procedure ShowVehicleEntry(Sender: TObject = nil);
    procedure ShowVehicleExit(Sender: TObject = nil);
    procedure ShowInsideVehicles(Sender: TObject = nil);
    procedure ShowSubscribers(Sender: TObject = nil);
    procedure ShowTariffs(Sender: TObject = nil);
    procedure ShowReports(Sender: TObject = nil);
    procedure ShowSettings(Sender: TObject = nil);

    procedure DoSaveEntry(Sender: TObject);
    procedure DoCalculateExit(Sender: TObject);
    procedure DoCloseSession(Sender: TObject);
    procedure DoSaveSubscriber(Sender: TObject);
    procedure DoSaveTariff(Sender: TObject);
    procedure DoSaveSettings(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.fmx}

uses
  System.DateUtils,
  System.UITypes,
  System.IOUtils,
  FMX.Dialogs,
  Infra.uDatabase;

const
  CPrimary = $FF1F2937;
  CAccent = $FF2563EB;
  CSurface = $FFF3F4F6;
  CCard = $FFFFFFFF;

constructor TMainForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  Caption := 'ParkFlow Pro - Otopark Takip Sistemi';
  Width := 1180;
  Height := 760;

  TDatabase.Initialize;

  FAuthService := TAuthService.Create;
  FParkingService := TParkingService.Create;
  FTariffService := TTariffService.Create;
  FSubscriberService := TSubscriberService.Create;
  FReportService := TReportService.Create;
  FSettingsService := TSettingsService.Create;

  BuildLoginScreen;
end;

destructor TMainForm.Destroy;
begin
  FSettingsService.Free;
  FReportService.Free;
  FSubscriberService.Free;
  FTariffService.Free;
  FParkingService.Free;
  FAuthService.Free;
  TDatabase.Finalize;
  inherited Destroy;
end;

procedure TMainForm.ClearForm;
begin
  while ChildrenCount > 0 do
    Children[0].Free;
end;

procedure TMainForm.ClearContent;
begin
  if FContent = nil then
    Exit;

  while FContent.ChildrenCount > 0 do
    FContent.Children[0].Free;
end;

function TMainForm.AddLabel(AParent: TFmxObject; const AText: string; AHeight: Single): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := AParent;
  Result.Align := TAlignLayout.Top;
  Result.Height := AHeight;
  Result.Margins.Rect := TRectF.Create(14, 6, 14, 2);
  Result.Text := AText;
  Result.WordWrap := True;
end;

function TMainForm.AddTitle(AParent: TFmxObject; const AText: string): TLabel;
begin
  Result := AddLabel(AParent, AText, 42);
  Result.TextSettings.Font.Size := 22;
  Result.TextSettings.Font.Style := [TFontStyle.fsBold];
  Result.StyledSettings := Result.StyledSettings - [TStyledSetting.Size, TStyledSetting.Style];
end;

function TMainForm.AddEdit(AParent: TFmxObject; const APrompt: string): TEdit;
begin
  Result := TEdit.Create(Self);
  Result.Parent := AParent;
  Result.Align := TAlignLayout.Top;
  Result.Height := 42;
  Result.Margins.Rect := TRectF.Create(14, 4, 14, 8);
  Result.TextPrompt := APrompt;
end;

function TMainForm.AddButton(AParent: TFmxObject; const AText: string; AOnClick: TNotifyEvent): TButton;
begin
  Result := TButton.Create(Self);
  Result.Parent := AParent;
  Result.Align := TAlignLayout.Top;
  Result.Height := 42;
  Result.Margins.Rect := TRectF.Create(14, 6, 14, 6);
  Result.Text := AText;
  Result.OnClick := AOnClick;
end;

function TMainForm.AddCombo(AParent: TFmxObject; const AItems: array of string): TComboBox;
var
  I: Integer;
begin
  Result := TComboBox.Create(Self);
  Result.Parent := AParent;
  Result.Align := TAlignLayout.Top;
  Result.Height := 42;
  Result.Margins.Rect := TRectF.Create(14, 4, 14, 8);
  for I := Low(AItems) to High(AItems) do
    Result.Items.Add(AItems[I]);
  if Result.Items.Count > 0 then
    Result.ItemIndex := 0;
end;

function TMainForm.AddCard(AParent: TFmxObject; const ATitle, AValue: string): TRectangle;
var
  LTitle: TLabel;
  LValue: TLabel;
begin
  Result := TRectangle.Create(Self);
  Result.Parent := AParent;
  Result.Align := TAlignLayout.Top;
  Result.Height := 86;
  Result.Margins.Rect := TRectF.Create(14, 8, 14, 6);
  Result.Fill.Color := CCard;
  Result.Stroke.Kind := TBrushKind.None;
  Result.XRadius := 14;
  Result.YRadius := 14;

  LTitle := TLabel.Create(Self);
  LTitle.Parent := Result;
  LTitle.Align := TAlignLayout.Top;
  LTitle.Height := 30;
  LTitle.Margins.Rect := TRectF.Create(14, 10, 14, 0);
  LTitle.Text := ATitle;

  LValue := TLabel.Create(Self);
  LValue.Parent := Result;
  LValue.Align := TAlignLayout.Client;
  LValue.Margins.Rect := TRectF.Create(14, 0, 14, 8);
  LValue.Text := AValue;
  LValue.TextSettings.Font.Size := 24;
  LValue.TextSettings.Font.Style := [TFontStyle.fsBold];
  LValue.StyledSettings := LValue.StyledSettings - [TStyledSetting.Size, TStyledSetting.Style];
end;

function TMainForm.TryReadCurrency(AEdit: TEdit; const AFieldName: string; out AValue: Currency): Boolean;
var
  S: string;
begin
  S := Trim(AEdit.Text);
  S := StringReplace(S, '.', FormatSettings.DecimalSeparator, [rfReplaceAll]);
  S := StringReplace(S, ',', FormatSettings.DecimalSeparator, [rfReplaceAll]);
  Result := TryStrToCurr(S, AValue);
  if not Result then
    ShowMessage(AFieldName + ' alanı geçerli bir tutar olmalıdır.');
end;

procedure TMainForm.BuildLoginScreen;
var
  CenterBox: TRectangle;
  TitleLabel: TLabel;
begin
  ClearForm;

  FRoot := TLayout.Create(Self);
  FRoot.Parent := Self;
  FRoot.Align := TAlignLayout.Client;

  CenterBox := TRectangle.Create(Self);
  CenterBox.Parent := FRoot;
  CenterBox.Width := 420;
  CenterBox.Height := 360;
  CenterBox.Position.X := (Width - CenterBox.Width) / 2;
  CenterBox.Position.Y := 120;
  CenterBox.Fill.Color := CCard;
  CenterBox.Stroke.Color := $FFE5E7EB;
  CenterBox.XRadius := 18;
  CenterBox.YRadius := 18;

  TitleLabel := AddTitle(CenterBox, 'ParkFlow Pro');
  TitleLabel.TextSettings.HorzAlign := TTextAlign.Center;
  TitleLabel.Align := TAlignLayout.Top;
  AddLabel(CenterBox, 'Windows + macOS uyumlu Delphi FMX otopark takip sistemi', 42);

  AddLabel(CenterBox, 'Kullanıcı Adı');
  FLoginUserEdit := AddEdit(CenterBox, 'admin');
  FLoginUserEdit.Text := 'admin';

  AddLabel(CenterBox, 'Şifre');
  FLoginPasswordEdit := AddEdit(CenterBox, 'admin123');
  FLoginPasswordEdit.Password := True;
  FLoginPasswordEdit.Text := 'admin123';

  AddButton(CenterBox, 'Giriş Yap', DoLogin);
end;

procedure TMainForm.BuildShell;
var
  TopBar: TRectangle;
  TopTitle: TLabel;
  MainArea: TLayout;
  Menu: TLayout;
  Footer: TRectangle;
begin
  ClearForm;

  FRoot := TLayout.Create(Self);
  FRoot.Parent := Self;
  FRoot.Align := TAlignLayout.Client;

  TopBar := TRectangle.Create(Self);
  TopBar.Parent := FRoot;
  TopBar.Align := TAlignLayout.Top;
  TopBar.Height := 58;
  TopBar.Fill.Color := CPrimary;
  TopBar.Stroke.Kind := TBrushKind.None;

  TopTitle := TLabel.Create(Self);
  TopTitle.Parent := TopBar;
  TopTitle.Align := TAlignLayout.Client;
  TopTitle.Margins.Rect := TRectF.Create(18, 0, 18, 0);
  TopTitle.Text := 'ParkFlow Pro  |  Otopark Takip Sistemi';
  TopTitle.TextSettings.Font.Size := 20;
  TopTitle.TextSettings.Font.Style := [TFontStyle.fsBold];
  TopTitle.TextSettings.FontColor := TAlphaColorRec.White;
  TopTitle.StyledSettings := TopTitle.StyledSettings - [TStyledSetting.Size, TStyledSetting.Style, TStyledSetting.FontColor];

  Footer := TRectangle.Create(Self);
  Footer.Parent := FRoot;
  Footer.Align := TAlignLayout.Bottom;
  Footer.Height := 32;
  Footer.Fill.Color := $FFE5E7EB;
  Footer.Stroke.Kind := TBrushKind.None;

  FFooterLabel := TLabel.Create(Self);
  FFooterLabel.Parent := Footer;
  FFooterLabel.Align := TAlignLayout.Client;
  FFooterLabel.Margins.Rect := TRectF.Create(12, 0, 12, 0);

  MainArea := TLayout.Create(Self);
  MainArea.Parent := FRoot;
  MainArea.Align := TAlignLayout.Client;

  Menu := TLayout.Create(Self);
  Menu.Parent := MainArea;
  Menu.Align := TAlignLayout.Left;
  Menu.Width := 220;
  Menu.Margins.Rect := TRectF.Create(0, 0, 0, 0);

  AddButton(Menu, 'Dashboard', ShowDashboard);
  AddButton(Menu, 'Araç Giriş', ShowVehicleEntry);
  AddButton(Menu, 'Araç Çıkış', ShowVehicleExit);
  AddButton(Menu, 'İçerideki Araçlar', ShowInsideVehicles);
  AddButton(Menu, 'Aboneler', ShowSubscribers);
  AddButton(Menu, 'Tarifeler', ShowTariffs);
  AddButton(Menu, 'Kasa / Rapor', ShowReports);
  AddButton(Menu, 'Ayarlar', ShowSettings);
  AddButton(Menu, 'Çıkış Yap', DoLogout);

  FContent := TLayout.Create(Self);
  FContent.Parent := MainArea;
  FContent.Align := TAlignLayout.Client;
  FContent.Margins.Rect := TRectF.Create(10, 10, 10, 10);

  RefreshFooter;
  ShowDashboard;
end;

procedure TMainForm.RefreshFooter;
begin
  if Assigned(FFooterLabel) then
    FFooterLabel.Text := Format('ParkFlow Pro | DB: Bağlı | Kullanıcı: %s | Veritabanı: %s',
      [FCurrentUser.UserName, TDatabase.DatabaseFile]);
end;

procedure TMainForm.DoLogin(Sender: TObject);
begin
  if FAuthService.Login(FLoginUserEdit.Text, FLoginPasswordEdit.Text, FCurrentUser) then
    BuildShell
  else
    ShowMessage('Kullanıcı adı veya şifre hatalı.');
end;

procedure TMainForm.DoLogout(Sender: TObject);
begin
  FCurrentUser := Default(TCurrentUser);
  BuildLoginScreen;
end;

procedure TMainForm.ShowDashboard(Sender: TObject);
var
  Stats: TDashboardStats;
begin
  ClearContent;
  AddTitle(FContent, 'Dashboard');

  Stats := FReportService.GetDashboardStats;

  AddCard(FContent, 'İçerideki Araçlar', Stats.InsideCount.ToString);
  AddCard(FContent, 'Boş Kapasite', Format('%d / %d', [Stats.FreeCapacity, Stats.TotalCapacity]));
  AddCard(FContent, 'Bugünkü Ciro', FormatCurr('#,##0.00 TL', Stats.TodayIncome));
  AddCard(FContent, 'Bugünkü Giriş / Çıkış', Format('%d / %d', [Stats.TodayEntries, Stats.TodayExits]));
  AddCard(FContent, 'Aktif Abone', Stats.ActiveSubscribers.ToString);
end;

procedure TMainForm.ShowVehicleEntry(Sender: TObject);
begin
  ClearContent;
  AddTitle(FContent, 'Araç Giriş');

  AddLabel(FContent, 'Plaka');
  FEntryPlateEdit := AddEdit(FContent, '16 ABC 123');

  AddLabel(FContent, 'Araç Tipi');
  FEntryTypeCombo := AddCombo(FContent, ['Otomobil', 'Motosiklet', 'Minibus', 'Kamyonet']);

  AddLabel(FContent, 'Park Yeri');
  FEntrySlotEdit := AddEdit(FContent, 'A-12');

  AddLabel(FContent, 'Açıklama');
  FEntryNoteEdit := AddEdit(FContent, 'Opsiyonel not');

  AddButton(FContent, 'Giriş Kaydet', DoSaveEntry);
end;

procedure TMainForm.DoSaveEntry(Sender: TObject);
begin
  try
    FParkingService.RegisterEntry(
      FEntryPlateEdit.Text,
      FEntryTypeCombo.Items[FEntryTypeCombo.ItemIndex],
      FEntrySlotEdit.Text,
      FEntryNoteEdit.Text,
      FCurrentUser.Id);

    ShowMessage('Araç girişi kaydedildi.');
    ShowDashboard;
  except
    on E: Exception do
      ShowMessage(E.Message);
  end;
end;

procedure TMainForm.ShowVehicleExit(Sender: TObject);
begin
  ClearContent;
  AddTitle(FContent, 'Araç Çıkış');

  AddLabel(FContent, 'Plaka');
  FExitPlateEdit := AddEdit(FContent, '16 ABC 123');

  AddLabel(FContent, 'Ödeme Tipi');
  FExitPaymentCombo := AddCombo(FContent, ['Nakit', 'Kredi Kartı', 'Havale/EFT', 'Abone']);

  FExitResultLabel := AddLabel(FContent, 'Plaka girip ücret hesaplayın.', 90);

  AddButton(FContent, 'Ücreti Hesapla', DoCalculateExit);
  AddButton(FContent, 'Çıkışı Tamamla', DoCloseSession);
end;

procedure TMainForm.DoCalculateExit(Sender: TObject);
var
  SessionId: Integer;
  VehicleType: string;
  Slot: string;
  EntryTime: TDateTime;
  Minutes: Integer;
  Fee: Currency;
begin
  try
    if FParkingService.GetOpenSession(FExitPlateEdit.Text, SessionId, VehicleType, Slot, EntryTime, Minutes, Fee) then
    begin
      FExitResultLabel.Text := Format(
        'Araç Tipi: %s'#13#10'Park Yeri: %s'#13#10'Giriş: %s'#13#10'Süre: %d dakika'#13#10'Tutar: %s',
        [VehicleType, Slot, FormatDateTime('dd.mm.yyyy hh:nn', EntryTime), Minutes, FormatCurr('#,##0.00 TL', Fee)]);
    end
    else
      FExitResultLabel.Text := 'Bu plakaya ait içeride açık kayıt bulunamadı.';
  except
    on E: Exception do
      ShowMessage(E.Message);
  end;
end;

procedure TMainForm.DoCloseSession(Sender: TObject);
var
  Minutes: Integer;
  Fee: Currency;
begin
  try
    FParkingService.CloseSession(
      FExitPlateEdit.Text,
      FExitPaymentCombo.Items[FExitPaymentCombo.ItemIndex],
      Minutes,
      Fee);

    ShowMessage(Format('Çıkış tamamlandı. Süre: %d dakika, Tutar: %s',
      [Minutes, FormatCurr('#,##0.00 TL', Fee)]));
    ShowDashboard;
  except
    on E: Exception do
      ShowMessage(E.Message);
  end;
end;

procedure TMainForm.ShowInsideVehicles(Sender: TObject);
var
  Vehicles: TArray<TInsideVehicleView>;
  V: TInsideVehicleView;
  List: TListBox;
  Item: TListBoxItem;
begin
  ClearContent;
  AddTitle(FContent, 'İçerideki Araçlar');

  List := TListBox.Create(Self);
  List.Parent := FContent;
  List.Align := TAlignLayout.Client;
  List.Margins.Rect := TRectF.Create(14, 8, 14, 14);

  Vehicles := FParkingService.GetInsideVehicles;

  if Length(Vehicles) = 0 then
  begin
    Item := TListBoxItem.Create(Self);
    Item.Text := 'İçeride araç bulunmuyor.';
    List.AddObject(Item);
    Exit;
  end;

  for V in Vehicles do
  begin
    Item := TListBoxItem.Create(Self);
    Item.Height := 58;
    Item.Text := Format('%s | %s | Giriş: %s | Süre: %d dk | Tahmini: %s | Yer: %s',
      [V.Plate, V.VehicleType, FormatDateTime('dd.mm.yyyy hh:nn', V.EntryTime),
       V.ElapsedMinutes, FormatCurr('#,##0.00 TL', V.EstimatedFee), V.ParkingSlot]);
    List.AddObject(Item);
  end;
end;

procedure TMainForm.ShowSubscribers(Sender: TObject);
var
  List: TListBox;
  Item: TListBoxItem;
  Subscribers: TArray<TSubscriberView>;
  S: TSubscriberView;
begin
  ClearContent;
  AddTitle(FContent, 'Aboneler');

  AddLabel(FContent, 'Ad Soyad');
  FSubscriberNameEdit := AddEdit(FContent, 'Müşteri adı');

  AddLabel(FContent, 'Telefon');
  FSubscriberPhoneEdit := AddEdit(FContent, '05xx xxx xx xx');

  AddLabel(FContent, 'Plaka');
  FSubscriberPlateEdit := AddEdit(FContent, '16 ABC 123');

  AddLabel(FContent, 'Başlangıç Tarihi');
  FSubscriberStartEdit := AddEdit(FContent, 'dd.mm.yyyy');
  FSubscriberStartEdit.Text := FormatDateTime('dd.mm.yyyy', Date);

  AddLabel(FContent, 'Bitiş Tarihi');
  FSubscriberEndEdit := AddEdit(FContent, 'dd.mm.yyyy');
  FSubscriberEndEdit.Text := FormatDateTime('dd.mm.yyyy', IncDay(Date, 30));

  AddLabel(FContent, 'Aylık Ücret');
  FSubscriberFeeEdit := AddEdit(FContent, '2500');

  AddButton(FContent, 'Abone Kaydet', DoSaveSubscriber);

  AddLabel(FContent, 'Kayıtlı Aboneler', 34);
  List := TListBox.Create(Self);
  List.Parent := FContent;
  List.Align := TAlignLayout.Client;
  List.Margins.Rect := TRectF.Create(14, 8, 14, 14);

  Subscribers := FSubscriberService.GetAll;
  for S in Subscribers do
  begin
    Item := TListBoxItem.Create(Self);
    Item.Height := 54;
    Item.Text := Format('%s | %s | %s - %s | %s | %s',
      [S.Plate, S.FullName, FormatDateTime('dd.mm.yyyy', S.StartDate), FormatDateTime('dd.mm.yyyy', S.EndDate),
       FormatCurr('#,##0.00 TL', S.MonthlyFee), S.Status]);
    List.AddObject(Item);
  end;
end;

procedure TMainForm.DoSaveSubscriber(Sender: TObject);
var
  StartDate: TDateTime;
  EndDate: TDateTime;
  Fee: Currency;
begin
  try
    if not TryStrToDate(FSubscriberStartEdit.Text, StartDate) then
    begin
      ShowMessage('Başlangıç tarihi geçerli değil. Örnek: 11.05.2026');
      Exit;
    end;

    if not TryStrToDate(FSubscriberEndEdit.Text, EndDate) then
    begin
      ShowMessage('Bitiş tarihi geçerli değil. Örnek: 11.06.2026');
      Exit;
    end;

    if not TryReadCurrency(FSubscriberFeeEdit, 'Aylık ücret', Fee) then
      Exit;

    FSubscriberService.AddSubscriber(
      FSubscriberNameEdit.Text,
      FSubscriberPhoneEdit.Text,
      FSubscriberPlateEdit.Text,
      StartDate,
      EndDate,
      Fee);

    ShowMessage('Abone kaydedildi.');
    ShowSubscribers;
  except
    on E: Exception do
      ShowMessage(E.Message);
  end;
end;

procedure TMainForm.ShowTariffs(Sender: TObject);
var
  List: TListBox;
  Item: TListBoxItem;
  Tariffs: TArray<TTariff>;
  T: TTariff;
begin
  ClearContent;
  AddTitle(FContent, 'Ücret Tarifeleri');

  AddLabel(FContent, 'Araç Tipi');
  FTariffTypeEdit := AddEdit(FContent, 'Otomobil');

  AddLabel(FContent, 'İlk Saat Ücreti');
  FTariffFirstEdit := AddEdit(FContent, '50');

  AddLabel(FContent, 'Sonraki Saat Ücreti');
  FTariffNextEdit := AddEdit(FContent, '30');

  AddLabel(FContent, 'Günlük Maksimum Ücret');
  FTariffDailyMaxEdit := AddEdit(FContent, '0');

  AddButton(FContent, 'Tarifeyi Kaydet / Güncelle', DoSaveTariff);

  AddLabel(FContent, 'Mevcut Tarifeler', 34);
  List := TListBox.Create(Self);
  List.Parent := FContent;
  List.Align := TAlignLayout.Client;
  List.Margins.Rect := TRectF.Create(14, 8, 14, 14);

  Tariffs := FTariffService.GetAll;
  for T in Tariffs do
  begin
    Item := TListBoxItem.Create(Self);
    Item.Height := 46;
    Item.Text := Format('%s | İlk saat: %s | Sonraki: %s | Günlük max: %s',
      [T.VehicleType, FormatCurr('#,##0.00 TL', T.FirstHourFee),
       FormatCurr('#,##0.00 TL', T.NextHourFee), FormatCurr('#,##0.00 TL', T.DailyMaxFee)]);
    List.AddObject(Item);
  end;
end;

procedure TMainForm.DoSaveTariff(Sender: TObject);
var
  FirstFee: Currency;
  NextFee: Currency;
  DailyMax: Currency;
begin
  try
    if not TryReadCurrency(FTariffFirstEdit, 'İlk saat ücreti', FirstFee) then
      Exit;

    if not TryReadCurrency(FTariffNextEdit, 'Sonraki saat ücreti', NextFee) then
      Exit;

    if not TryReadCurrency(FTariffDailyMaxEdit, 'Günlük maksimum ücret', DailyMax) then
      Exit;

    FTariffService.SaveTariff(FTariffTypeEdit.Text, FirstFee, NextFee, DailyMax);
    ShowMessage('Tarife kaydedildi.');
    ShowTariffs;
  except
    on E: Exception do
      ShowMessage(E.Message);
  end;
end;

procedure TMainForm.ShowReports(Sender: TObject);
var
  Stats: TDashboardStats;
begin
  ClearContent;
  AddTitle(FContent, 'Kasa / Günlük Rapor');

  Stats := FReportService.GetDashboardStats;
  AddCard(FContent, 'Bugünkü Toplam Ciro', FormatCurr('#,##0.00 TL', Stats.TodayIncome));
  AddCard(FContent, 'Bugünkü Araç Giriş Sayısı', Stats.TodayEntries.ToString);
  AddCard(FContent, 'Bugünkü Araç Çıkış Sayısı', Stats.TodayExits.ToString);
  AddCard(FContent, 'Anlık İçerideki Araç', Stats.InsideCount.ToString);
end;

procedure TMainForm.ShowSettings(Sender: TObject);
begin
  ClearContent;
  AddTitle(FContent, 'Ayarlar');

  AddLabel(FContent, 'Toplam Otopark Kapasitesi');
  FCapacityEdit := AddEdit(FContent, '100');
  FCapacityEdit.Text := FSettingsService.GetCapacity.ToString;

  AddButton(FContent, 'Ayarları Kaydet', DoSaveSettings);

  AddLabel(FContent, 'Veritabanı Dosyası', 30);
  AddLabel(FContent, TDatabase.DatabaseFile, 54);

  AddLabel(FContent, 'Not: Windows + macOS uyumluluğu için veri dosyası kullanıcı Documents klasörü altında tutulur.', 54);
end;

procedure TMainForm.DoSaveSettings(Sender: TObject);
var
  Capacity: Integer;
begin
  try
    Capacity := StrToIntDef(Trim(FCapacityEdit.Text), 0);
    FSettingsService.SetCapacity(Capacity);
    ShowMessage('Ayarlar kaydedildi.');
    ShowDashboard;
  except
    on E: Exception do
      ShowMessage(E.Message);
  end;
end;

end.
