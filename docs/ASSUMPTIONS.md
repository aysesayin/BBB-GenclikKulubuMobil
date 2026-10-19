# Varsayımlar (`TODO(varsayım)`)

Belirsiz iş kurallarında yapılan varsayımlar. Kodda `// TODO(varsayım):` ile işaretlidir; bu liste `grep` ile üretildi.

## auth

- [lib/features/auth/view_model/login_view_model.dart:26](lib/features/auth/view_model/login_view_model.dart#L26) — Hatalı şifre deneme hakkı sunucudan gelmezse yerel olarak 3 sayılır.
- [lib/features/auth/view_model/register_view_model.dart:57](lib/features/auth/view_model/register_view_model.dart#L57) — Yaş kuralları panelden gelecek; tasarım notu "16–17 veli onayı, 2009+ doğum → 18 altı".
- [lib/features/auth/view_model/register_view_model.dart:261](lib/features/auth/view_model/register_view_model.dart#L261) — İlgi alanı kaydı başarısızsa akış durmaz; profilde tekrar sorulur.
- [lib/features/auth/widgets/register_steps.dart:166](lib/features/auth/widgets/register_steps.dart#L166) — Android'de SMS Retriever paketi yok; iOS one-time-code autofill çalışır.

## buan

- [lib/features/buan/tasks/invite/view/invite_view.dart:97](lib/features/buan/tasks/invite/view/invite_view.dart#L97) — Instagram metin paylaşımını desteklemez; sistem paylaşım sayfası açılır.
- [lib/features/buan/tasks/photo_report/view_model/location_reader.dart:6](lib/features/buan/tasks/photo_report/view_model/location_reader.dart#L6) — Adres ("Tophane, Osmangazi") sunucuda ters geokodlanır; istemci yalnız koordinat yollar.
- [lib/features/buan/tasks/quiz/view_model/quiz_view_model.dart:11](lib/features/buan/tasks/quiz/view_model/quiz_view_model.dart#L11) — BUAN soru başına (doğru cevapta yanıtın `awarded` alanı) verilir; özet ekranı toplamı gösterir.
- [lib/features/buan/tasks/spin/widgets/shake_panel.dart:25](lib/features/buan/tasks/spin/widgets/shake_panel.dart#L25) — Eşik 14 m/s², 800 ms içinde 2 tepe — cihaz testinde ayarlanacak.
- [lib/features/buan/tasks/steps/view_model/step_source.dart:26](lib/features/buan/tasks/steps/view_model/step_source.dart#L26) — HealthKit / Health Connect ile gün boyu eşitleme (tasarımdaki "Apple Sağlık") entegrasyonda eklenecek.
- [lib/features/buan/tasks/steps/view_model/steps_view_model.dart:56](lib/features/buan/tasks/steps/view_model/steps_view_model.dart#L56) — Mesafe ve aktif süre cihazda tahmin edilir (adım 0,75 m; dakikada ~110 adım).
- [lib/features/buan/view_model/buan_view_model.dart:60](lib/features/buan/view_model/buan_view_model.dart#L60) — Takip Et / Gönül Dostu / BİKO / Fikrin ile Kazan / Fırsat Kullan için
- [lib/features/buan/widgets/task_card.dart:143](lib/features/buan/widgets/task_card.dart#L143) — BuanPointsBadge yalnız tek değer alıyor; aralık için aynı ölçülerde yerel rozet.
- [lib/features/buan/widgets/task_info_sheet.dart:36](lib/features/buan/widgets/task_info_sheet.dart#L36) — Bu görevlerin (Takip Et, Gönül Dostu, BİKO, Fikrin ile Kazan, Fırsat Kullan)

## card_qr

- [lib/features/card_qr/utils/geo.dart:6](lib/features/card_qr/utils/geo.dart#L6) — konum izni A akışındaki izin ekranında alınır; burada sorulmaz, yoksa geo=null gider.
- [lib/features/card_qr/view/card_view.dart:155](lib/features/card_qr/view/card_view.dart#L155) — Apple/Google Wallet pass'i backend'den (.pkpass / JWT) gelecek; şimdilik bilgi notu.

## core

- [lib/core/di/modules/buan_tasks_module.dart:9](lib/core/di/modules/buan_tasks_module.dart#L9) — Oyunlar için ayrı modül dosyası yok (locator çekirdekte); entegratör isterse games_module.dart'a ayırabilir.
- [lib/core/network/api_endpoints.dart:13](lib/core/network/api_endpoints.dart#L13) — Alan adları henüz belli değil; ORNEK yer tutucusu backend ekibince değiştirilecek.
- [lib/core/network/api_endpoints.dart:27](lib/core/network/api_endpoints.dart#L27) — kurumsal vektör karo sunucusu gelince değişecek.
- [lib/core/network/api_endpoints.dart:105](lib/core/network/api_endpoints.dart#L105) — Google Maps evrensel bağlantısı; kurum tercihi (Apple/Yandex) netleşince değişebilir.
- [lib/core/services/analytics_service.dart:23](lib/core/services/analytics_service.dart#L23) — firebase_analytics, Firebase proje dosyaları (google-services.json /

## data

- [lib/data/models/opportunities/opportunity.dart:63](lib/data/models/opportunities/opportunity.dart#L63) — "Bitmek üzere" = son 5 gün (tasarımdaki örneklerde 3 ve 5 gün kalanlar işaretli).
- [lib/data/models/profile/discount.dart:45](lib/data/models/profile/discount.dart#L45) — Hatırlatma eşiği tasarım metnindeki 15 gün; sunucu `expiring` gönderirse o geçerli.
- [lib/data/models/profile/profile_stats.dart:7](lib/data/models/profile/profile_stats.dart#L7) — Tasarım notu ayrı `GET /badges/me?featured` diyor; tek çağrı için vitrin rozetleri
- [lib/data/repositories/cart_repository.dart:77](lib/data/repositories/cart_repository.dart#L77) — Yeni kalem eklenince sunucu tüm sepetin rezervini yeniden 5 dk'ya kurar.
- [lib/data/repositories/search_repository.dart:26](lib/data/repositories/search_repository.dart#L26) — Son arama sayısı üst sınırı 8.
- [lib/data/services/buan_tasks_service.dart:66](lib/data/services/buan_tasks_service.dart#L66) — "Fikir" sekmesi de /photo-reports'a type=idea (fotoğrafsız) gider; ApiEndpoints.ideas başka akışa ait sayıldı.
- [lib/data/services/cart_payment_launcher.dart:12](lib/data/services/cart_payment_launcher.dart#L12) — webview_flutter kurulu değil; 3D Secure sayfası url_launcher ile uygulama içi
- [lib/data/services/opportunity_service.dart:31](lib/data/services/opportunity_service.dart#L31) — favori ekleme/çıkarma tek uçta `{isFavorite: bool}` gövdesiyle yapılır.

## events

- [lib/features/events/view/event_detail_view.dart:103](lib/features/events/view/event_detail_view.dart#L103) — Cihaz takvimine ekleme için paket henüz yok; şimdilik bilgi mesajı.
- [lib/features/events/view_model/event_list_view_model.dart:9](lib/features/events/view_model/event_list_view_model.dart#L9) — Liste [windowDays] günlük pencere için tek çağrıyla (`?from=&to=`) alınır;
- [lib/features/events/view_model/event_list_view_model.dart:18](lib/features/events/view_model/event_list_view_model.dart#L18) — Gün şeridi bugünden itibaren 14 gün gösterir.

## games

- [lib/features/games/view/games_view.dart:35](lib/features/games/view/games_view.dart#L35) — Bilgi yarışması şimdilik BUAN "Cevapla Kazan" ekranını açar; ayrı oyun motoru (Flame) gelince değişir.
- [lib/features/games/widgets/game_icons.dart:10](lib/features/games/widgets/game_icons.dart#L10) — Sembol çizimleri yer tutucu; illüstratör setiyle değişecek.

## home

- [lib/features/home/view_model/home_view_model.dart:47](lib/features/home/view_model/home_view_model.dart#L47) — Selam saat aralıkları tasarımda tanımlı değil; yukarıdaki dilimler kullanıldı.
- [lib/features/home/widgets/home_banner_carousel.dart:20](lib/features/home/widgets/home_banner_carousel.dart#L20) — Otomatik geçiş aralığı tasarımda yok; 5 sn seçildi.
- [lib/features/home/widgets/home_header.dart:25](lib/features/home/widgets/home_header.dart#L25) — Misafirde (user null) ad yerine "Gezgin" gösterilir, BUAN/seri çipleri gizlenir.

## notifications

- [lib/features/notifications/view_model/notifications_view_model.dart:81](lib/features/notifications/view_model/notifications_view_model.dart#L81) — Tek bildirim için "okundu" uç noktası yok; sunucu satır açılışını ayrıca izlemiyor varsayıldı.

## onboarding

- [lib/features/onboarding/permission_gateway.dart:20](lib/features/onboarding/permission_gateway.dart#L20) — firebase_messaging kurulu değil; bildirim izni FCM entegrasyonunda
- [lib/features/onboarding/permission_gateway.dart:23](lib/features/onboarding/permission_gateway.dart#L23) — permission_handler kurulu değil; Android ACTIVITY_RECOGNITION / iOS Motion
- [lib/features/onboarding/view/summit_view.dart:247](lib/features/onboarding/view/summit_view.dart#L247) — Apple/Google Wallet pass üretimi backend + paket gerektirir; şimdilik bilgi mesajı.
- [lib/features/onboarding/view_model/interests_view_model.dart:13](lib/features/onboarding/view_model/interests_view_model.dart#L13) — En az seçim sayısı panelden gelebilir; tasarımdaki 3 kullanıldı.
- [lib/features/onboarding/view_model/permissions_view_model.dart:60](lib/features/onboarding/view_model/permissions_view_model.dart#L60) — İzin tercihleri /users/me/preferences'a profil özelliği yazacak; burada yalnız OS izni istenir.

## opportunities

- [lib/features/opportunities/widgets/opp_style.dart:30](lib/features/opportunities/widgets/opp_style.dart#L30) — stok %50'nin altındaysa "Son N kod", üstündeyse "Bol" (tasarım örneklerinden).

## places

- [lib/features/places/view/place_detail_view.dart:49](lib/features/places/view/place_detail_view.dart#L49) — Görev detayı rotası yok; BUAN sekmesindeki görev listesine gidilir.
- [lib/features/places/view_model/place_detail_view_model.dart:19](lib/features/places/view_model/place_detail_view_model.dart#L19) — Yer favorisi için uç nokta yok; şimdilik yalnız ekran içinde tutulur.

## profile

- [lib/features/profile/settings/view_model/biometric_login.dart:17](lib/features/profile/settings/view_model/biometric_login.dart#L17) — Bayrak `pref.biometricLogin`; giriş ekranı (A grubu) bunu okuyup
- [lib/features/profile/settings/view_model/settings_view_model.dart:93](lib/features/profile/settings/view_model/settings_view_model.dart#L93) — Uygulama dili şimdilik `app.dart`'ta 'tr' sabit; tercih sunucuya kaydedilir,
- [lib/features/profile/support/view_model/support_view_model.dart:18](lib/features/profile/support/view_model/support_view_model.dart#L18) — Konu listesi tasarımdaki 4 seçenek; panelden yönetilecekse `/support/topics` ucu gerekir.
- [lib/features/profile/widgets/document_picker.dart:10](lib/features/profile/widgets/document_picker.dart#L10) — Tasarım PDF de diyor; image_picker yalnız görsel seçer. PDF için file_picker paketi
- [lib/features/profile/widgets/guest_profile.dart:20](lib/features/profile/widgets/guest_profile.dart#L20) — Tasarımda misafir profil varyantı yok; AuthGate sheet'inin dili ve renkleriyle kuruldu.
- [lib/features/profile/widgets/legal_links.dart:15](lib/features/profile/widgets/legal_links.dart#L15) — Anahtar adları backend ile netleşmeli (kvkk mock'u mevcut; diğerleri `app.legal._.json`).

## search

- [lib/features/search/view_model/search_view_model.dart:136](lib/features/search/view_model/search_view_model.dart#L136) — Gerçek API'de bulanık eşleşmeleri gizlememesi için istemci süzgeci yalnız mock modunda gerekebilir.

## services

- [lib/features/services/applications/widgets/application_card.dart:76](lib/features/services/applications/widgets/application_card.dart#L76) — Ödeme bekleyen başvuru için sunucu sepeti yeniden kurar; doğrudan sepete gidilir.
- [lib/features/services/session/view_model/session_rules.dart:46](lib/features/services/session/view_model/session_rules.dart#L46) — Veli izin belgesi girişte kontrol edilir; uygulamadan yükleme akışı yok.
- [lib/features/services/session/view_model/session_view_model.dart:23](lib/features/services/session/view_model/session_view_model.dart#L23) — Canlı kontenjan için WebSocket paketi yok; 30 sn'de bir sessiz yenileme yapılır.
- [lib/features/services/sports_school/view_model/sports_school_view_model.dart:20](lib/features/services/sports_school/view_model/sports_school_view_model.dart#L20) — "Son N" eşiği 3 yer; panelden gelirse API değeri kullanılmalı.

## splash

- [lib/features/splash/view_model/splash_view_model.dart:51](lib/features/splash/view_model/splash_view_model.dart#L51) — minVersion (zorunlu güncelleme) kontrolü package_info_plus ile

## stories

- [lib/features/stories/view/story_view.dart:64](lib/features/stories/view/story_view.dart#L64) — Hareketi azalt açıkken otomatik geçiş kapatıldı (tasarımdaki CSS yalnız animasyonu kapatıyor).
- [lib/features/stories/view_model/story_view_model.dart:35](lib/features/stories/view_model/story_view_model.dart#L35) — Son segmentten sonra sıradaki hikâyeye geçilmez, görüntüleyici kapanır.
