import 'package:bbb_genclik_kulubu_app/core/di/locator.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/router/routes.dart';
import 'package:bbb_genclik_kulubu_app/core/session/session_controller.dart';
import 'package:bbb_genclik_kulubu_app/core/storage/cache_store.dart';
import 'package:bbb_genclik_kulubu_app/core/storage/secure_storage.dart';
import 'package:bbb_genclik_kulubu_app/core/theme/app_theme.dart';
import 'package:bbb_genclik_kulubu_app/core/theme/theme_controller.dart';
import 'package:bbb_genclik_kulubu_app/core/theme/ui_prefs_controller.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/account_settings.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/delete_request.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/profile_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/profile/delete_requested/view/delete_requested_view.dart';
import 'package:bbb_genclik_kulubu_app/features/profile/settings/view/settings_view.dart';
import 'package:bbb_genclik_kulubu_app/features/profile/view/profile_view.dart';
import 'package:bbb_genclik_kulubu_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// Oturum: üye; [signOut] çağrı sayısını tutar (SecureStorage'a dokunmaz).
class _FakeSession extends SessionController {
  _FakeSession(CacheStore cache) : super(secure: SecureStorage(), cache: cache);
  int signOuts = 0;
  @override
  bool get isGuest => false;
  @override
  bool get isAuthenticated => true;
  @override
  Future<void> signOut() async => signOuts++;
}

/// Kolay Mod anahtarı (gerçek [UiPrefsController] + bellek içi [CacheStore]) ve KVKK silme akışı.
void main() {
  late CacheStore cache;
  late MockProfileRepository repo;
  late _FakeSession session;
  late UiPrefsController prefs;

  setUpAll(() async {
    await initializeDateFormatting('tr');
    repo = MockProfileRepository();
    sl.registerSingleton<ProfileRepository>(repo);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    cache = await CacheStore.create();
    if (sl.isRegistered<CacheStore>()) sl.unregister<CacheStore>();
    sl.registerSingleton<CacheStore>(cache);
    prefs = UiPrefsController(cache);
    session = _FakeSession(cache);
    when(repo.me).thenAnswer((_) async => const Success(demoUser));
    when(repo.stats).thenAnswer((_) async => const Success(demoStats));
    when(repo.preferences).thenAnswer((_) async => const Success(NotificationPrefs()));
    when(repo.requestDeletion).thenAnswer((_) async => Success(demoReceipt));
  });

  const delegates = [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  Widget wrap(Widget app) => MultiProvider(
    providers: [
      ChangeNotifierProvider<SessionController>.value(value: session),
      ChangeNotifierProvider<ThemeController>(create: (_) => ThemeController(cache)),
      ChangeNotifierProvider<UiPrefsController>.value(value: prefs),
    ],
    child: app,
  );

  Future<void> pump(WidgetTester tester, Widget view) async {
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      wrap(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: delegates,
          home: view,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(seconds: 4));
  }

  /// İskelet (NeverScrollable) listesi değil, içerik listesi.
  final contentList = find.byWidgetPredicate((w) => w is ListView && w.physics is! NeverScrollableScrollPhysics).first;

  Future<void> scrollTo(WidgetTester tester, String text) async {
    await tester.scrollUntilVisible(
      find.text(text),
      200,
      scrollable: find.descendant(of: contentList, matching: find.byType(Scrollable)).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await scrollTo(tester, text);
    await tester.tap(find.text(text).first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('ayarlar: Kolay Mod anahtarı tercihi kaydeder ve toast gösterir', (tester) async {
    await pump(tester, const SettingsView());
    await scrollTo(tester, 'Kolay Mod');
    expect(find.text('Kolay Mod'), findsOneWidget);
    expect(find.text('Yazılar büyür, ekranlar sadeleşir.'), findsOneWidget);
    expect(prefs.easyMode, isFalse);

    await tapText(tester, 'Kolay Mod');
    expect(prefs.easyMode, isTrue);
    expect(cache.readBool('pref.easyMode'), isTrue);
    expect(find.text('Kolay Mod açık'), findsOneWidget);
    expect(find.text('GÖRÜNÜM'), findsOneWidget);
    expect(find.text('GÖRÜNÜM VE DİL'), findsNothing);
    expect(tester.takeException(), isNull);

    await tapText(tester, 'Kolay Mod');
    expect(prefs.easyMode, isFalse);
    expect(find.text('GÖRÜNÜM VE DİL'), findsOneWidget);
  });

  testWidgets('profil: Kolay Mod 5 büyük satır, sayaç/rozet gizli, Daha fazla açılır', (tester) async {
    await prefs.setEasyMode(true);
    await pump(tester, const ProfileView());
    expect(find.text('Ayşe Su'), findsOneWidget);
    expect(find.text('Rozet vitrinim'), findsNothing);
    expect(find.text('Toplam kazanılan BUAN'), findsNothing);
    for (final label in ['Başvurularım', 'Kuponlarım', 'Hesap ayarları', 'Destek', 'Çıkış yap']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('İndirim Tanımla'), findsNothing);
    final row = find.ancestor(of: find.text('Kuponlarım'), matching: find.byType(InkWell)).first;
    expect(tester.getSize(row).height, greaterThanOrEqualTo(64));

    await tapText(tester, 'Daha fazla');
    expect(find.text('İndirim Tanımla'), findsOneWidget);
    expect(find.text('Yasal metinler ve hesap silme'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('silme talebi: onay → Talebin alındı ekranı → Çıkış yap → welcome', (tester) async {
    final router = GoRouter(
      initialLocation: Routes.settings,
      routes: [
        GoRoute(path: Routes.settings, builder: (_, _) => const SettingsView()),
        GoRoute(
          path: Routes.deleteRequested,
          builder: (_, s) => DeleteRequestedView(receipt: s.extra as DeleteRequestReceipt?),
        ),
        GoRoute(
          path: Routes.welcome,
          builder: (_, _) => const Scaffold(body: Text('welcome')),
        ),
      ],
    );
    tester.view.physicalSize = const Size(393, 852) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      wrap(
        MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light,
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: delegates,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(milliseconds: 50));

    await tapText(tester, 'Hesabımı silme talebi oluştur');
    expect(find.text('Hesabını silmek istediğine emin misin?'), findsOneWidget);
    await tester.tap(find.text('Silme talebi oluştur'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    verify(repo.requestDeletion).called(1);
    expect(find.text('Talebin alındı'), findsOneWidget);
    expect(find.textContaining('KVKK-2026-048213'), findsOneWidget);
    expect(find.textContaining('30 gün'), findsOneWidget);
    expect(find.text('Kayıtlı e-posta adresine bilgilendirme gönderdik.'), findsOneWidget);

    await tester.tap(find.text('Çıkış yap'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(session.signOuts, 1);
    expect(find.text('welcome'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
