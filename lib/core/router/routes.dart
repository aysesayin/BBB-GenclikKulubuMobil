/// Uygulamadaki tüm yol (path) sabitleri. Özellikler arası gezinme
/// yalnız bu sabitlerle yapılır: `context.push(Routes.opportunity(id))`.
abstract final class Routes {
  // A · Giriş akışı
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const welcome = '/welcome';
  static const interests = '/interests';
  static const register = '/register'; // ?ref=DAVETKODU
  static const login = '/login';
  static const summit = '/summit';
  static const permissions = '/permissions';
  static const prePermission = '/izin-oncesi'; // bildirim ön-izin açıklaması
  static const firstDay = '/ilk-gun'; // kayıt sonrası ilk gün kontrol listesi
  static String registerWithReferral(String code) => '$register?ref=${Uri.encodeQueryComponent(code)}';

  // Sekmeler (alt navigasyon)
  static const home = '/kesfet';
  static const opportunities = '/firsatlar';
  static const card = '/kartim';
  static const buan = '/buan';
  static const profile = '/profil';

  // B · Keşfet (tam ekran)
  static const search = '/arama';
  static const notifications = '/bildirimler';
  static String story(String id) => '/hikaye/$id';

  // C · Fırsatlar
  static const myOpportunities = '/firsatlar/cuzdan'; // sekme içinde
  static String opportunity(String id) => '/firsat/$id';
  static String opportunityClaimed(String id) => '/firsat/$id/yakalandi';

  // D · Kartım
  static const qrScan = '/qr-okut';
  static const turnstile = '/kartim/turnike'; // tam ekran QR + 4 hane (gişe modu)

  // E · BUAN (sekme içinde: pazar, lig, rozetler, geçmiş; diğerleri tam ekran)
  static const market = '/buan/pazar';
  static String reward(String id) => '/buan/pazar/$id';
  static const league = '/buan/lig';
  static const badges = '/buan/rozetler';
  static const history = '/buan/gecmis';
  static const dailySpin = '/buan/sans';
  static const watchEarn = '/buan/izle';
  static const steps = '/buan/adim';
  static const quiz = '/buan/quiz';
  static const invite = '/buan/davet';
  static const photoReport = '/buan/cek';
  static String task(String id) => '/buan/gorev/$id'; // genel görev detayı (takip et, gönül dostu, BİKO…)

  // F · Oyunlar (Keşfet sekmesi içinde)
  static const games = '/kesfet/oyunlar';

  // G · Etkinlik & Keşif
  static const events = '/kesfet/etkinlikler'; // sekme içinde
  static const map = '/kesfet/harita'; // sekme içinde
  static String event(String id) => '/etkinlik/$id';
  static String place(String id) => '/yer/$id';

  // H · Hizmetler
  static const pools = '/kesfet/havuzlar'; // sekme içinde
  static const sportsSchools = '/kesfet/spor-okullari'; // sekme içinde
  static String sessions(String itemId) => '/seans/$itemId';
  static const cart = '/sepet';
  static const applications = '/profil/basvurularim'; // sekme içinde

  // I · Profil
  static const settings = '/profil/ayarlar';
  static const discounts = '/profil/indirim';
  static const children = '/profil/cocuk';
  static const coupons = '/profil/kuponlar'; // sekme içinde
  static const support = '/profil/destek';
  static const deleteRequested = '/profil/hesap-silme-talebi'; // KVKK talep sonucu

  // Deep link
  static const inviteDeepLink = '/davet/:code';

  /// Oturum gerektiren yollar (misafir → karşılama ekranı).
  static const protectedPrefixes = <String>[
    myOpportunities,
    qrScan,
    turnstile,
    firstDay,
    deleteRequested,
    cart,
    applications,
    settings,
    discounts,
    children,
    coupons,
    support,
    dailySpin,
    watchEarn,
    steps,
    quiz,
    invite,
    photoReport,
  ];

  static bool isProtected(String location) {
    if (RegExp(r'^/firsat/[^/]+/yakalandi').hasMatch(location)) return true;
    return protectedPrefixes.any(location.startsWith);
  }

  /// Giriş akışındaki yollar (oturum gerektirmez, alt navigasyon yok).
  static const onboardingPaths = <String>[splash, onboarding, welcome, interests, register, login, summit, permissions, prePermission, firstDay];
}
