# Windows Build Notes

1. RAD Studio / Delphi açın.
2. `src/ParkFlowPro.dproj` dosyasını açın.
3. Target platform: `Windows 64-bit`.
4. Configuration: `Release`.
5. Project > Build ParkFlowPro.

SQLite için proje `FireDAC.Phys.SQLiteWrapper.Stat` unit'ini kullanır. Bu sayede çoğu senaryoda ayrı `sqlite3.dll` taşımanız gerekmez. Delphi sürümünüz farklı davranırsa Deployment ekranından SQLite driver gereksinimlerini kontrol edin.
