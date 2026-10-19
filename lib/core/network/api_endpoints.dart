/// Tüm API (ve dış servis) adresleri YALNIZCA bu dosyada tutulur.
/// Başka hiçbir dosyada URL string'i bulunmaz.
library;

enum AppEnv { dev, staging, prod }

class ApiConfig {
  ApiConfig._();

  /// `--dart-define=ENV=prod` ile değiştirilir (bkz. bootstrap).
  static AppEnv env = AppEnv.dev;

  // TODO(varsayım): Alan adları henüz belli değil; ORNEK yer tutucusu backend ekibince değiştirilecek.
  static String get baseUrl => switch (env) {
        AppEnv.dev => 'https://dev-api.ORNEK.bursa.bel.tr/api/v1',
        AppEnv.staging => 'https://test-api.ORNEK.bursa.bel.tr/api/v1',
        AppEnv.prod => 'https://api.ORNEK.bursa.bel.tr/api/v1',
      };

  /// Davet / paylaşım deep link tabanı: `{deepLinkBase}/davet/{kod}`, `/firsat/{id}`, `/etkinlik/{id}`.
  static String get deepLinkBase => switch (env) {
        AppEnv.dev => 'https://dev-genclik.ORNEK.bursa.bel.tr',
        AppEnv.staging => 'https://test-genclik.ORNEK.bursa.bel.tr',
        AppEnv.prod => 'https://genclik.ORNEK.bursa.bel.tr',
      };

  /// Harita karo şablonu (flutter_map). TODO(varsayım): kurumsal vektör karo sunucusu gelince değişecek.
  static const mapTileUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const mapUserAgentPackage = 'com.bbb_genclik_kulubu_app';

  /// Destek / yasal metinler için dış sayfa yoksa uygulama içi gösterilir.
  static const supportPhone = 'tel:153';

  static const connectTimeout = Duration(seconds: 15);
  static const receiveTimeout = Duration(seconds: 20);

  /// true → istekler `assets/mock/*.json` dosyalarından yanıtlanır (bkz. MockInterceptor).
  static bool useMock = true;

  /// Mock modunda yapay gecikme (skeleton durumlarını görebilmek için).
  static Duration mockLatency = const Duration(milliseconds: 450);
}

class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const verifyOtp = '/auth/otp/verify';
  static const resendOtp = '/auth/otp/resend';
  static const verifyMernis = '/auth/mernis/verify';
  static const refreshToken = '/auth/refresh';
  static const forgotPassword = '/auth/password/forgot';
  static const changePassword = '/auth/password/change';
  static const logout = '/auth/logout';
  static const sendOtp = '/auth/otp/send'; // kayıtta ilk SMS kodu
  static const biometricLogin = '/auth/biometric'; // cihaz anahtarıyla giriş (Face ID / parmak izi)
  static const parentConsent = '/auth/parent-consent'; // 16–17 yaş veli onay bağlantısı

  // Profil
  static const me = '/users/me';
  static const meStats = '/users/me/stats';
  static const updateContact = '/users/me/contact';
  static const preferences = '/users/me/preferences';
  static const interests = '/users/me/interests';
  static const interestOptions = '/interests';
  static const discountTypes = '/discount-types';
  static const discounts = '/users/me/discounts';
  static String discountDocument(String id) => '/users/me/discounts/$id/document';
  static const children = '/users/me/children';
  static const deleteAccount = '/users/me/delete-request';
  static const digitalCard = '/users/me/card'; // dinamik QR token + 4 haneli kod
  static const digitalCardToken = '/users/me/card/token'; // 30 sn'lik dönen token
  static const meAvatar = '/users/me/avatar'; // çok parçalı profil fotoğrafı yükleme

  // İçerik
  static const home = '/home'; // banner, story, kısayollar, öneriler (tek çağrı)
  static const stories = '/stories';
  static String storyDetail(String id) => '/stories/$id';
  static String storySeen(String id) => '/stories/$id/seen';
  static const search = '/search';
  static const searchPopular = '/search/popular';
  static const notifications = '/notifications';
  static const notificationsReadAll = '/notifications/read-all';

  // Fırsatlar
  static const opportunities = '/opportunities';
  static const opportunityCategories = '/opportunities/categories';
  static String opportunityDetail(String id) => '/opportunities/$id';
  static String claimOpportunity(String id) => '/opportunities/$id/claim';
  static String favoriteOpportunity(String id) => '/opportunities/$id/favorite';
  static const myOpportunities = '/opportunities/mine';

  // Etkinlikler & Yerler
  static const events = '/events';
  static String eventDetail(String id) => '/events/$id';
  static String applyEvent(String id) => '/events/$id/apply';
  static const places = '/places';
  static const placesNearby = '/places/nearby';
  static String placeDetail(String id) => '/places/$id';
  static const mapPins = '/map/pins'; // ?layer=places|events|opportunities&bbox=
  static const facilities = '/facilities'; // gençlik merkezleri + spor tesisleri
  /// Yol tarifi (url_launcher, harici uygulama). `{lat}` / `{lng}` yer tutucuları doldurulur.
  /// TODO(varsayım): Google Maps evrensel bağlantısı; kurum tercihi (Apple/Yandex) netleşince değişebilir.
  static const directionsUrlTemplate = 'https://www.google.com/maps/dir/?api=1&destination={lat},{lng}';
  static String eventShareLink(String id) => '${ApiConfig.deepLinkBase}/etkinlik/$id'; // paylaşım deep link

  // Hizmetler (Havuz / Spor Okulu / Tenis)
  static const serviceGroups = '/services/groups';
  static const pools = '/services/pools';
  static const sportsBranches = '/services/sports-branches';
  static const tennisProducts = '/services/tennis-products';
  static String serviceItems(String facilityId) => '/services/facilities/$facilityId/items';
  static String sessions(String itemId) => '/services/items/$itemId/sessions'; // ?from=&to=
  static const cart = '/cart';
  static const cartHold = '/cart/hold'; // 5 dk kontenjan rezervasyonu
  static String cartItem(String id) => '/cart/items/$id';
  static const checkout = '/cart/checkout';
  static const applications = '/applications';
  static String cancelApplication(String id) => '/applications/$id/cancel';
  static const coupons = '/coupons';
  static const couponMovements = '/coupons/movements';

  // BUAN
  static const buanWallet = '/buan/wallet';
  static const buanLevel = '/buan/level';
  static const buanTasks = '/buan/tasks';
  static String completeTask(String id) => '/buan/tasks/$id/complete';
  static const buanTransactions = '/buan/transactions';
  static const buanRewards = '/buan/rewards';
  static String rewardDetail(String id) => '/buan/rewards/$id';
  static String redeemReward(String id) => '/buan/rewards/$id/redeem';
  static const leaderboard = '/buan/leaderboard'; // ?scope=global|district|friends
  static const leagueSummary = '/buan/leaderboard/me';
  static const badges = '/buan/badges';
  static const streak = '/buan/streak';
  static const dailySpin = '/buan/daily-spin';
  static const qrCheckIn = '/buan/qr-checkin';
  static const steps = '/buan/steps';
  static const watchVideo = '/buan/videos/current';
  static String videoProgress(String id) => '/buan/videos/$id/progress';
  static String videoComplete(String id) => '/buan/videos/$id/complete';
  static const referral = '/buan/referral';
  static const quizActive = '/buan/quizzes/active';
  static String quizAnswer(String id) => '/buan/quizzes/$id/answers';

  // Katılım
  static const surveys = '/surveys';
  static String submitSurvey(String id) => '/surveys/$id/answers';
  static const ideas = '/ideas';
  static const photoReports = '/photo-reports';
  static const support = '/support/tickets';
  static const faq = '/support/faq';
  static const games = '/games';
  static const gameTournament = '/games/tournament/current';
  static String submitGameScore(String id) => '/games/$id/score';
  static const photoReportTypes = '/photo-reports/types'; // tür + kategori + ödül (panel)
  static const myPhotoReports = '/photo-reports/mine'; // moderasyon durumlu gönderilerim
  static const whatsappShare = 'https://wa.me/?text='; // davet paylaşımı (dış uygulama)

  // Sistem
  static const appConfig = '/app/config'; // min sürüm, bakım modu, feature flag, metinler
  static const legalTexts = '/app/legal';
  static String legalText(String key) => '/app/legal/$key';
  static const deviceToken = '/devices/token';
}
