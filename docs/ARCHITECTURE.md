# Mimari ve Kodlama Kuralları

Bursa Büyükşehir Gençlik Kulübü — Flutter (MVVM + Repository). Bu belge hem ekip hem de özellik
geliştiren ajanlar için **bağlayıcı sözleşmedir**.

Flutter SDK bu makinede PATH'te değil: `C:\flutter\bin\flutter` (Bash: `/c/flutter/bin/flutter`, Dart: `/c/flutter/bin/dart`).

## Katmanlar

```
View (Widget)  →  ViewModel (ChangeNotifier)  →  Repository (abstract + Impl)  →  Service (DioClient)  →  API / assets/mock
```

| Katman | Konum | Kural |
|---|---|---|
| View | `lib/features/<f>/view/` | Yalnız UI. İş mantığı yok. `context.watch/select` ile VM okur. |
| Widget | `lib/features/<f>/widgets/` | Küçük, yeniden kullanılabilir parçalar. |
| ViewModel | `lib/features/<f>/view_model/` | `BaseViewModel` veya `LoadableViewModel<T>`'den türer. UI durumu `ViewState<T>`. |
| Repository | `lib/data/repositories/<f>_repository.dart` | `abstract interface class XRepository` + `XRepositoryImpl`. `Future<ApiResult<T>>` döner. |
| Service | `lib/data/services/<f>_service.dart` | `DioClient` ile uç nokta çağrısı + JSON → model. |
| Model | `lib/data/models/<f>/` | `freezed` + `json_serializable` (örnek: `lib/data/models/app/app_config.dart`). |
| DI | `lib/core/di/modules/<f>_module.dart` | Yalnız service + repository kaydı (`registerLazySingleton`). VM kaydedilmez. |
| Rotalar | `lib/features/<f>/<f>_routes.dart` | Özellik kendi `List<RouteBase>` listelerini yayınlar; `app_router.dart` bunları bağlar. |

View ↔ VM bağlama kalıbı:

```dart
class OpportunityListView extends StatelessWidget {
  const OpportunityListView({super.key});
  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => OpportunityListViewModel(sl<OpportunityRepository>())..load(),
        child: const _Body(),
      );
}
```

Durumlar: `ViewStateBuilder<T>` (lib/core/base/base_view.dart) → skeleton / boş / hata-çevrimdışı / içerik.
Çevrimdışı: `DioClient.get(..., cacheKey: 'x')` verirseniz ağ hatasında önbellek `Success(fromCache: true)` döner,
UI üstte `OfflineBanner` gösterir.

## Ağ

- **Tüm URL'ler yalnız** `lib/core/network/api_endpoints.dart` içinde; servislerde path dizesi yazılmaz.
  Önce mevcut sabitleri kullanın. Eksik varsa bu dosyaya **yalnız Edit aracıyla** (asla Write ile değil; başka
  ajanlar da aynı anda ekliyor olabilir) ilgili bölümün sonuna satır ekleyin ve teslim notunda listeleyin.
- Standart zarf: `{ "success", "data", "message", "errors": [{field,message}], "meta": {page,pageSize,total} }`.
- Hatalar `sealed AppException` (NetworkException, ConflictException …). Kullanıcı mesajı: `errorMessageOf(context, e)`.
- POST'larda idempotency gerekiyorsa `headers: {'Idempotency-Key': ...}`.

### Mock modu (`ApiConfig.useMock`, varsayılan açık)

`MockInterceptor` istekleri `assets/mock/` altındaki **düz** dosya adlarından yanıtlar:

| İstek | Dosya |
|---|---|
| `GET /buan/wallet` | `buan.wallet.json` |
| `GET /opportunities/opp-burulas` | `opportunities.opp-burulas.json` → yoksa `opportunities._.json` |
| `POST /opportunities/opp-1/claim` | `opportunities._.claim.post.json` (veya `.json`) |

`_` herhangi bir id'yi karşılar; sorgu parametreleri yok sayılır (filtreleri **VM tarafında da** uygulayın ki demo çalışsın).
Dosya içeriği tam zarftır. `"_status": 409` eklemek hata simülasyonu yapar. Alt klasör YOK (pubspec yalnız `assets/mock/` içerir).
Mock içerik metinleri (fırsat başlıkları vb.) API içeriğidir; l10n'e girmez.

Paylaşılan demo kimlikleri (özellikler arası tutarlılık için bu id'leri kullanın):

- Kullanıcı: `usr-demo`, Ayşe Su (baş harf "AS"), maskeli TCKN `1234*****90`, BUAN bakiye **12450**, seri **7**, lig **Gümüş · 14.**
- Fırsatlar: `opp-burulas`, `opp-extrempark`, `opp-kitapduragi`, `opp-teleferik`, `opp-dilokulu`, `opp-kafe`
- Etkinlikler: `evt-uludag-yuruyus`, `evt-kariyer-cv`, `evt-zumba`, `evt-genclik-kampi`
- Yerler: `plc-asik-veysel-gm`, `plc-sehir-tiyatrosu`, `plc-millet-gsm`
- Ödüller: `rwd-kapadokya`, `rwd-teleferik`, `rwd-oyun-kodu`, `rwd-market`, `rwd-kitap`, `rwd-giyim`, `rwd-yks`, `rwd-ingilizce`, `rwd-ogle-yemegi`
- Hikâyeler: `sto-yeni-firsat`, `sto-genclik-kampi`, `sto-konser`, `sto-duyuru`, `sto-uludag`
- Hizmet kalemleri: `itm-fethiye-gunluk`, `itm-fethiye-yetiskin`, `itm-mihrapli-kurs`

## Tasarım sistemi

- Renkler YALNIZ `context.palette.*` (lib/core/theme/app_palette.dart). Adlar tasarım dosyalarındaki `t.xxx` ile aynı:
  `bg, sf, sf2, ink, mut, line, teal, tealB, tealS, grn, grnT, grnS, pur, purT, purS, yel, yelS, pink, pinkT, pinkS,
  mint, sky, blob, cta, onCta, ctaShadow, buanFill, onBuan, buanShadow, coinMark, hotFill, tile1..tile6, onTile, chip,
  onChip, paper, success*, warning*, error*`. Gölge: `palette.cardShadow`. Gradyan: `palette.buanGradient`, `heroGradient`, `storyRing`.
  Tasarımdaki `t.secondaryText` → `grnT`, `t.primaryText` → `teal`, `t.hotText` → `pinkT`, `t.surfaceAlt` → `sf2`,
  `t.border` → `line`, `t.textSecondary` → `mut`, `t.accentSoft` → `yelS`, `t.buanSoft` → `purS`.
- Hex sabit renk YASAK (yalnız palette). SVG dizelerine renk: `p.teal.hex`.
- Tipografi: `AppTypography.display(size)` (Baloo 2), `.body(size, weight:)` (Nunito), `.number(size)` (tabular).
  Kısayollar: `screenTitle` (30), `pageTitle` (26), `sectionTitle` (21), `cardTitle`, `caption`, `label`, `buttonL`.
- Boşluk/köşe/süre: `AppSpacing`, `AppRadii`, `AppDurations`.
- İkonlar: `AppIcon(AppIcons.x)` — tasarımdaki SVG `d` yolu birebir. Özelliğe özgü ikon yollarını
  `lib/features/<f>/widgets/<f>_icons.dart` içinde tutun. `<circle>/<rect>` öğelerini path'e çevirin.
  Serbest çizimler (banner illüstrasyonu, harita süsü): `SvgArt('<svg viewBox=..>…</svg>')`, renkler palette'ten.
- Bileşenler (`import '../../../core/widgets/widgets.dart';`):
  `AppButton` (cta / buan / outline / outlineInk / text; 56-48-40), `AppIconButton` (44 px, semanticLabel zorunlu),
  `FilterPill`, `PillRow`, `StickerChip`, `SegmentedTabs`, `TagBadge`, `BuanCoin`, `BuanPointsBadge` (asla satır kırmaz),
  `BuanBalanceChip`, `StreakChip`, `CountUpText`, `AppCard`, `IconTile`, `SectionHeader`, `AppBackHeader`,
  `TabScreenHeader`, `StickyBottomBar`, `AppProgressBar`, `ProgressRing`, `DaysLeftLabel`, `CountdownText`,
  `Blob`/`BlobBackground`, `Mascot` (happy/celebrate/surprised/sleepy), `Shimmer` + `SkeletonBox`, `EmptyState`,
  `ErrorStateView`, `OfflineBanner`, `AppSheet.show`, `AuthGate.guard/show` (misafir duvarı),
  `showRewardToast`, `CelebrationOverlay` (konfeti / coin), `AppTextField`.
- Alt navigasyonlu sekme ekranları: kabuk `extendBody: true` olduğundan gövdedeki `MediaQuery.paddingOf(context).bottom`
  zaten tab bar yüksekliğini içerir → `padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 16)`.
- Tasarım 393×852 (iOS) ve 360×800 (Android) için çizildi → sabit genişlik yok; `Expanded`, `LayoutBuilder`, oranlar.
- Koyu tema zorunlu: yalnız palette kullanırsanız otomatik çalışır.

## Metinler (l10n)

- Widget içinde sabit Türkçe metin YOK. Her özellik kendi parçasını yazar:
  `lib/l10n/parts/<f>_tr.arb` ve `<f>_en.arb`. Anahtarlar özellik önekiyle: `homeGreeting`, `oppClaimCta`…
- Sonra çalıştırın: `/c/flutter/bin/dart run tool/codegen.dart` (birleştirir + `gen-l10n`). Kilitlidir; paralel çalışabilir.
- Kullanım: `context.l10n.homeGreeting` (`import '../../../l10n/l10n.dart';`).
- Ortak metinler `core_tr.arb`'da (commonBack, commonRetry, daysLeft, buanAmount …) — DÜZENLEMEYİN, kullanın.
- Büyük harf: `trUpper()` (i → İ). `toUpperCase()` kullanmayın.
- Sayılar: `Fmt.number(12450)` → "12.450", `Fmt.signed(2000)` → "+2.000", `Fmt.mmss`, `Fmt.maskTckn`.

## Kod üretimi

`/c/flutter/bin/dart run tool/codegen.dart --build` → l10n + freezed/json_serializable. Kilitli; başka biri çalıştırıyorsa bekler.
Başkasının yarım dosyası build_runner'da hata verebilir; yalnız kendi dosyalarınızın üretildiğini kontrol edin.

## Kalite

- Dosya başına ≤ 300 satır. Widget'ları küçük tutun.
- `flutter analyze` kendi klasörlerinizde sıfır uyarı: `/c/flutter/bin/flutter analyze lib/features/<f> lib/data test/features/<f>`.
- Her ViewModel için unit test: `test/features/<f>/…_view_model_test.dart`, `mocktail` ile sahte repository.
- Erişilebilirlik: dokunma hedefi ≥ 44 px, ikon butonlarında `semanticLabel`, durumlar yalnız renkle değil metin/ikonla,
  `Semantics(header: true)` başlıklar, `context.reduceMotion` iken döngüsel animasyon yok.
- Haptik: `Haptics.medium()` kazanımda, `Haptics.selection()` seçimde.
- Belirsiz iş kuralı → varsayım yapın, `// TODO(varsayım): …` ile işaretleyin, teslim notunda listeleyin.
- Kurumsal kişi adı / fotoğrafı, ödül, görev puanı, yasal metin kodda sabit OLMAZ — hepsi API (mock) verisi.

## Dokunulmayacak dosyalar (yalnız entegratör değiştirir)

`lib/core/**` (kendi `lib/core/di/modules/<f>_module.dart` dosyanız ve `api_endpoints.dart`'a Edit ile satır ekleme hariç), `lib/app.dart`, `lib/main.dart`,
`pubspec.yaml`, `analysis_options.yaml`, `tool/`, `android/`, `ios/`, `web/`,
`lib/l10n/parts/core_*.arb`, `lib/l10n/arb/*`, `lib/l10n/generated/*`, başka özelliklerin klasörleri.
Çekirdekte bir değişiklik gerekiyorsa yerel çözüm yapın ve teslim notunda önerin.
`flutter run` / `flutter build` çalıştırmayın (görsel kontrol entegrasyonda yapılır).

## Kolay Mod (ileri yaş / sade arayüz)

`context.easyMode` (lib/core/theme/ui_prefs_controller.dart) true iken: yazı ölçeği 1.2, `context.reduceMotion` true,
`context.touchTarget` 56. Her özellik kendi ekranında şunları uygular: hikâye/karusel/dekoratif blob gizlenir,
yatay kaydırmalı listeler dikey tek sütuna döner, en fazla 4 ana eylem büyük kartlarla gösterilir, ikincil menü
satırları "Daha fazla" altına alınır, sayılar ve CTA'lar büyür. Ayarlar → Görünüm'de anahtar var (profile özelliği).
