# ParkFlow Pro Architecture

## Amaç

ParkFlow Pro, küçük ve orta ölçekli otoparklar için masaüstü çalışan, lokal veritabanı kullanan, Windows ve macOS uyumlu bir takip sistemidir.

## Katmanlar

### UI

`UI/uMainForm.pas` içinde FireMonkey tabanlı ekranlar bulunur.

### Services

İş kuralları burada yer alır:

- `uAuthService`: Login ve kullanıcı doğrulama
- `uParkingService`: Araç giriş/çıkış, ücret hesaplama
- `uTariffService`: Ücret tarifesi yönetimi
- `uSubscriberService`: Abone yönetimi
- `uReportService`: Dashboard ve kasa raporları
- `uSettingsService`: Kapasite gibi uygulama ayarları

### Infra

`uDatabase`, SQLite bağlantısını, şema oluşturmayı ve seed verilerini yönetir.

### Security

`uPasswordHasher`, demo seviyesinde SHA-256 hash üretir. Üretim ortamında kullanıcı başı salt ve daha güçlü bir parola hash stratejisi önerilir.

## Cross-platform Best Practices

- Dosya yolu için `System.IOUtils.TPath` kullanılır.
- Veritabanı uygulama klasörüne değil kullanıcı dokümanlarına yazılır.
- UI FireMonkey ile oluşturulur.
- FireDAC SQLite kullanılır.
- Platforma özel kod minimumda tutulur.

## Gelecek Geliştirmeler

- Repository sınıflarını servislerden tamamen ayırma
- Unit test projesi
- Yazıcı adaptörleri
- Kamera/plaka tanıma adaptörleri
- Çoklu otopark/şube desteği
- MySQL veya REST API senkronizasyon modu
