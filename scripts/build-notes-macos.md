# macOS Build Notes

Delphi ile macOS hedeflemek için Mac tarafında PAServer gerekir.

1. Mac üzerinde PAServer'ı başlatın.
2. Windows üzerindeki RAD Studio'da connection profile oluşturun.
3. `Target Platforms > macOS 64-bit` seçin.
4. Build ve Deploy çalıştırın.

Veritabanı çalışma zamanı konumu:

```text
~/Documents/ParkFlowPro/parkflowpro.db
```

Gerçek dağıtım öncesi Apple code signing / notarization sürecini ayrıca uygulayın.
