program ParkFlowPro;

{$CODEPAGE UTF8}

uses
  System.StartUpCopy,
  FMX.Forms,
  FireDAC.FMXUI.Wait,
  FireDAC.Phys.SQLite,
  FireDAC.Phys.SQLiteWrapper.Stat,
  App.uAppTypes in 'App\uAppTypes.pas',
  App.uAppPaths in 'App\uAppPaths.pas',
  Infra.uDatabase in 'Infra\uDatabase.pas',
  Security.uPasswordHasher in 'Security\uPasswordHasher.pas',
  Services.uAuthService in 'Services\uAuthService.pas',
  Services.uTariffService in 'Services\uTariffService.pas',
  Services.uSubscriberService in 'Services\uSubscriberService.pas',
  Services.uParkingService in 'Services\uParkingService.pas',
  Services.uReportService in 'Services\uReportService.pas',
  Services.uSettingsService in 'Services\uSettingsService.pas',
  UI.uMainForm in 'UI\uMainForm.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
