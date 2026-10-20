# Bursa Büyükşehir Gençlik Kulübü — Mobil Uygulama

Flutter (MVVM + Repository) ile yeniden tasarlanan Gençlik Kulübü uygulaması. Tasarım kaynağı:
Claude Design canvas'ı (B · Keşfet, C · Fırsatlar, D · Kartım, E · BUAN, F · Oyunlar, G · Etkinlik, H · Hizmetler, I · Profil, S · Durumlar, A · Giriş akışı).

- Android paket adı: `com.bbb_genclik_kulubu_app` (minSdk 24) · iOS 15+
- Arayüz Türkçe, i18n altyapısı İngilizceye hazır (`lib/l10n`)
- Açık / koyu tema (P1 · Bursa Klasik token'ları), dinamik yazı boyutu, "hareketi azalt" desteği
- Backend olmadan çalışır: **mock modu varsayılan açık** (`assets/mock/*.json`)

## Çalıştırma

Flutter 3.38 (Dart 3.10). Bu makinede SDK `C:\flutter` altında; PATH'e ekleyin ya da tam yol kullanın.

```bash
flutter pub get
```

```bash
dart run tool/codegen.dart --build
```

`lib/l10n/generated` yalnız bu betikle üretilir (`l10n.yaml` bilerek yok; ayarlar `tool/codegen.dart` içinde).
`.arb` parçalarını değiştirdikten sonra betiği yeniden çalıştırın. "Type 'AppLocalizations' not found" hatası görürseniz
aynı komut çözer.

```bash
flutter run --dart-define=ENV=dev --dart-define=MOCK=true
```

Flavor'lar: `ENV=dev|staging|prod`, `MOCK=true|false`. Tüm adresler yalnız `lib/core/network/api_endpoints.dart` içinde.

Demo (mock) girişi: T.C. Kimlik No `10000000146` + herhangi bir şifre (`yanlis123` hatalı şifre durumunu gösterir).
Kayıt akışında SMS kodu `481926`.

## Web test sürümü

- Herkese açık adres: https://aysesayin.github.io/BBB-GenclikKulubuMobil/ (`gh-pages` dalı, demo veri).
- Yeniden yayınlamak için:

```bash
flutter build web --release --dart-define=MOCK=true --no-web-resources-cdn --pwa-strategy=none --base-href /BBB-GenclikKulubuMobil/ -o build/web_pages
```

  Sonra `build/web_pages` içeriğini (`.nojekyll` dahil, `canvaskit/skwasm*` hariç) `gh-pages` dalına gönderin.
- Belediye ağı `*.netlify.app` adreslerini engelliyor; GitHub Pages ağ içinden de açılıyor.

## Kalite

```bash
flutter analyze
```

```bash
flutter test
```

- `flutter analyze`: 0 sorun · `flutter test`: 430 test (her ViewModel için unit test; kayıt, fırsat yakala,
  ödül takası ve sepet akışları için widget testleri; ekran duman testleri 393 / 360 px, açık / koyu)
- CI: `.github/workflows/ci.yml` (analyze + test + dev/staging/prod APK + imzasız iOS)

## Klasörler

```
lib/
  core/       ağ (Dio, interceptor'lar, mock), DI (get_it), router (go_router), tema, ortak bileşenler, yardımcılar
  data/       freezed modeller, servisler (uzak veri), repository'ler (soyut + uygulama)
  features/   splash · onboarding · auth · home · search · notifications · stories · opportunities · card_qr
              buan (cüzdan, pazar, lig, rozet, geçmiş) · buan/tasks (şans, izle, adım, quiz, davet, çek) · games
              events · map · places · services (havuz, spor okulu, tenis, sepet, başvurular) · profile
  l10n/       parts/*.arb (özellik başına) → arb/ (birleşik) → generated/
assets/mock/  API sözleşme örnekleri (düz dosya adları, bkz. docs/ARCHITECTURE.md)
tool/         codegen.dart (l10n + build_runner), gen_openapi.py
docs/         ARCHITECTURE.md (kurallar), openapi.yaml (backend taslağı), ASSUMPTIONS.md (varsayımlar)
```

## Backend ekibi için

- `docs/openapi.yaml` — `python tool/gen_openapi.py` ile mock sözleşmelerinden üretilen OpenAPI 3.1 taslağı
  (117 yol, örnek yanıtlarla). Standart zarf: `{ success, data, message, errors[], meta{page,pageSize,total} }`.
- Puan, kota, yaş ve stok kuralları sunucu tarafındadır; uygulama yalnız ilerleme bildirir ve sunucu sonucunu gösterir.

## Bilinen eksikler

- Firebase (bildirim, analitik, crashlytics) bağlı değil; `AnalyticsService` debug uygulaması kullanılıyor.
- `webview_flutter` yok: 3D Secure ödeme `url_launcher` ile tarayıcıda açılıyor. Canlı kontenjan WebSocket yerine 30 sn yenileme.
- Cüzdana ekle (Apple / Google Wallet), HealthKit / Health Connect, Android SMS Retriever, PDF belge yükleme (`file_picker`),
  dil değiştirme (LocaleController) ve oyun motoru (Flame) henüz yok — ayrıntı: `docs/ASSUMPTIONS.md`.
- `permission_handler` iOS'ta Podfile makroları gerektirir (ilk `pod install` sonrası `PERMISSION_SENSORS=1`).
- `permission_handler` bilerek `^12.0.1`'de sabit: 13.x'in Android tarafı (14.x) AGP 9 + Kotlin 2.3 + Gradle 9 ister;
  proje AGP 8.11 / Kotlin 2.2 / Gradle 8.14 kullanıyor. Android araç zinciri AGP 9'a geçince yükseltin.
- Harita karoları geçici olarak OpenStreetMap; üretimden önce kurumsal karo sunucusu gerekli.
- Logolar (Gençlik Kulübü, BU'AN, BBB kurumsal) gerçek .ai dosyalarından eklenmeli; şimdilik tipografik / SVG yer tutucu.
