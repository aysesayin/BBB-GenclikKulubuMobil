import 'package:bbb_genclik_kulubu_app/core/di/locator.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/session/session_controller.dart';
import 'package:bbb_genclik_kulubu_app/core/storage/cache_store.dart';
import 'package:bbb_genclik_kulubu_app/core/storage/secure_storage.dart';
import 'package:bbb_genclik_kulubu_app/core/theme/app_theme.dart';
import 'package:bbb_genclik_kulubu_app/core/theme/theme_controller.dart';
import 'package:bbb_genclik_kulubu_app/data/models/app/app_config.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/account_settings.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/child_profile.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/coupon.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/discount.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/profile_stats.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/support.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/app_repository.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/coupon_repository.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/profile_repository.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/support_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/profile/children/view/children_view.dart';
import 'package:bbb_genclik_kulubu_app/features/profile/coupons/view/coupons_view.dart';
import 'package:bbb_genclik_kulubu_app/features/profile/discounts/view/discounts_view.dart';
import 'package:bbb_genclik_kulubu_app/features/profile/settings/view/settings_view.dart';
import 'package:bbb_genclik_kulubu_app/features/profile/support/view/support_view.dart';
import 'package:bbb_genclik_kulubu_app/features/profile/view/profile_view.dart';
import 'package:bbb_genclik_kulubu_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

class _MockAppRepository extends Mock implements AppRepository {}

class _FakeSession extends SessionController {
  _FakeSession(CacheStore cache, {required this.guest}) : super(secure: SecureStorage(), cache: cache);
  final bool guest;
  @override
  bool get isGuest => guest;
  @override
  bool get isAuthenticated => !guest;
}

void main() {
  late CacheStore cache;

  setUpAll(() async {
    await initializeDateFormatting('tr');
    SharedPreferences.setMockInitialValues({});
    cache = await CacheStore.create();
    final profile = MockProfileRepository();
    final coupons = MockCouponRepository();
    final support = MockSupportRepository();
    final app = _MockAppRepository();
    when(() => app.current).thenReturn(const AppConfig());
    when(() => app.legalText(any())).thenAnswer((_) async => const Success('Metin'));
    when(profile.me).thenAnswer((_) async => const Success(demoUser));
    when(profile.stats).thenAnswer(
      (_) async => const Success(
        ProfileStats(
          totalBuanEarned: 24350,
          eventsAttended: 9,
          opportunitiesUsed: 7,
          badgeCount: 7,
          pendingPayments: 1,
          openSurveys: 2,
          featuredBadges: [
            FeaturedBadge(id: 'a', name: '7 Gün Seri', icon: 'flame', tone: 6),
            FeaturedBadge(id: 'b', name: 'Kültür Avcısı', icon: 'museum', tone: 4),
            FeaturedBadge(id: 'c', name: 'Kamp Ateşi', icon: 'camp', tone: 2),
          ],
        ),
      ),
    );
    when(profile.preferences).thenAnswer((_) async => const Success(NotificationPrefs()));
    when(profile.children).thenAnswer(
      (_) async => const Success([ChildProfile(id: 'c1', displayName: 'Deniz S. E.', initial: 'D', age: 9, note: '2 aktif başvuru')]),
    );
    when(profile.discountTypes).thenAnswer(
      (_) async => const Success([
        DiscountType(id: 'personel', name: 'Personel', requiredDocument: 'Personel kimlik kartı'),
        DiscountType(id: 'sehit-gazi', name: 'Şehit yakını', requiredDocument: 'Kimlik kartı'),
        DiscountType(id: 'yoksulluk', name: 'Yoksulluk belgesi', requiredDocument: 'SYDV belgesi'),
      ]),
    );
    when(profile.discounts).thenAnswer(
      (_) async => Success([
        UserDiscount(id: 'd1', typeId: 'ogrenci', typeName: 'Öğrenci', status: DiscountStatus.approved, validUntil: DateTime(2027, 6, 30)),
        const UserDiscount(id: 'd2', typeId: 'yoksulluk', typeName: 'Yoksulluk belgesi', status: DiscountStatus.rejected),
      ]),
    );
    when(coupons.wallet).thenAnswer(
      (_) async => Success(
        CouponWallet(
          balance: 30,
          items: [
            Coupon(id: 'k1', title: 'Raporla telafi kuponu', value: 30, source: 'Gürsu Havuzu iptali', expiresAt: DateTime(2026, 12, 31)),
            Coupon(
              id: 'k2',
              title: 'Gençlik Kampı erken kayıt',
              kind: CouponKind.percent,
              value: 15,
              used: true,
              usedAt: DateTime(2026, 9, 20),
            ),
          ],
        ),
      ),
    );
    when(coupons.movements).thenAnswer(
      (_) async => Success([CouponMovement(id: 'm', title: 'Telafi kuponu tanımlandı', date: DateTime(2026, 8, 29), value: 30)]),
    );
    when(support.tickets).thenAnswer(
      (_) async => Success([
        SupportTicket(
          id: 't',
          number: '24817',
          subject: 'Havuz soyunma dolabı',
          type: SupportType.sikayet,
          createdAt: DateTime(2026, 10, 12),
        ),
      ]),
    );
    when(support.faq).thenAnswer((_) async => const Success([FaqItem(id: 'f', question: 'Soru?', answer: 'Cevap.')]));
    sl
      ..registerSingleton<CacheStore>(cache)
      ..registerSingleton<ProfileRepository>(profile)
      ..registerSingleton<CouponRepository>(coupons)
      ..registerSingleton<SupportRepository>(support)
      ..registerSingleton<AppRepository>(app);
  });

  Future<void> pump(WidgetTester tester, Widget view, {bool guest = false, bool dark = false, Size size = const Size(393, 852)}) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SessionController>.value(value: _FakeSession(cache, guest: guest)),
          ChangeNotifierProvider<ThemeController>(create: (_) => ThemeController(cache)),
        ],
        child: MaterialApp(
          theme: dark ? AppTheme.dark : AppTheme.light,
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: view,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(seconds: 4));
  }

  final views = <String, (Widget, String)>{
    'profil': (const ProfileView(), 'Ayşe Su'),
    'ayarlar': (const SettingsView(), 'Hesap ayarları'),
    'indirim': (const DiscountsView(), 'Onaya gönder'),
    'cocuk': (const ChildrenView(), 'Deniz S. E.'),
    'kuponlar': (const CouponsView(), 'Raporla telafi kuponu'),
    'destek': (const SupportView(), '#24817 · Havuz soyunma dolabı'),
  };

  for (final MapEntry(key: name, value: (view, text)) in views.entries) {
    for (final (size, dark) in [(const Size(393, 852), false), (const Size(360, 800), true)]) {
      testWidgets('$name ${size.width.toInt()} ${dark ? 'koyu' : 'açık'} hatasız çizilir', (tester) async {
        await pump(tester, view, dark: dark, size: size);
        expect(tester.takeException(), isNull);
        expect(find.text(text), findsWidgets);
      });
    }
  }

  testWidgets('misafir profil varyantı', (tester) async {
    await pump(tester, const ProfileView(), guest: true);
    expect(tester.takeException(), isNull);
    expect(find.text('Misafir olarak geziyorsun'), findsOneWidget);
    expect(find.text('Kayıt ol, 500 BUAN kap'), findsOneWidget);
  });

  Future<void> tapText(WidgetTester tester, String text) async {
    final f = find.text(text).first;
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('ayarlar: telefon sheet açılır, geçersiz numara uyarısı', (tester) async {
    await pump(tester, const SettingsView());
    await tapText(tester, 'Telefon');
    expect(find.text('Telefonunu değiştir'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '0212');
    await tapText(tester, 'Kod gönder');
    expect(find.textContaining('Geçerli bir cep telefonu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('destek: yasal metin sheet içinde açılır', (tester) async {
    await pump(tester, const SupportView());
    await tapText(tester, 'KVKK Aydınlatma Metni');
    expect(find.text('Metin'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('profil: çıkış onay sayfası', (tester) async {
    await pump(tester, const ProfileView());
    await tapText(tester, 'Çıkış yap');
    expect(find.text('Çıkış yapmak istiyor musun?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('çocuk: 18 yaş üstü uyarısı', (tester) async {
    await pump(tester, const ChildrenView());
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '10000000146');
    await tester.enterText(fields.at(1), '02052007');
    await tapText(tester, 'MERNİS ile doğrula ve ekle');
    expect(find.text('Bu kişi 18 yaşını doldurmuş; kendi hesabını açabilir.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
