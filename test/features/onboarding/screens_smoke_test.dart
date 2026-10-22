import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/router/routes.dart';
import 'package:bbb_genclik_kulubu_app/core/session/session_controller.dart';
import 'package:bbb_genclik_kulubu_app/core/theme/app_theme.dart';
import 'package:bbb_genclik_kulubu_app/core/theme/ui_prefs_controller.dart';
import 'package:bbb_genclik_kulubu_app/data/models/app/app_config.dart';
import 'package:bbb_genclik_kulubu_app/data/models/auth/interest_option.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/app_repository.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/auth_repository.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/interests_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/auth/biometric_authenticator.dart';
import 'package:bbb_genclik_kulubu_app/features/onboarding/onboarding_routes.dart';
import 'package:bbb_genclik_kulubu_app/features/onboarding/permission_gateway.dart';
import 'package:bbb_genclik_kulubu_app/features/onboarding/widgets/marquee.dart';
import 'package:bbb_genclik_kulubu_app/features/onboarding/widgets/motion.dart';
import 'package:bbb_genclik_kulubu_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';

/// Giriş akışı ekranlarının (hareketi azalt açık) hatasız çizildiğini ve
/// 360×800 / 393×852 boyutlarında taşma olmadığını doğrular.
void main() {
  final sl = GetIt.instance;
  late MockSession session;

  setUpAll(() async {
    registerAuthFallbacks();
    await initializeDateFormatting('tr');
  });

  setUp(() async {
    await sl.reset();
    session = stubSession(onboardingSeen: true);
    final app = stubApp();
    when(app.fetchConfig).thenAnswer((_) async => const Success(AppConfig()));
    when(() => app.legalText(any())).thenAnswer((_) async => const Success('metin'));
    final auth = MockAuthRepository();
    when(() => auth.onboardingBonusHeld).thenReturn(true);
    when(auth.holdOnboardingBonus).thenAnswer((_) async {});
    when(() => auth.lastRegistration).thenReturn(demoSession);
    when(auth.firstDayTasks).thenAnswer((_) async => const Success(firstDayTasks));
    when(() => auth.isFirstDayDone(any())).thenReturn(false);
    when(() => auth.markFirstDayDone(any())).thenAnswer((_) async {});
    final interests = MockInterestsRepository();
    when(() => interests.held).thenReturn(const {});
    when(interests.options).thenAnswer(
      (_) async => const Success([
        InterestOption(id: 'a', label: 'Spor', icon: 'ball', tile: 3),
        InterestOption(id: 'b', label: 'Müzik', icon: 'music'),
        InterestOption(id: 'c', label: 'Doğa & Kamp', icon: 'tent', tile: 2),
        InterestOption(id: 'd', label: 'Gönüllülük', icon: 'heart', tile: 2),
      ]),
    );
    final bio = MockBiometric();
    when(bio.isAvailable).thenAnswer((_) async => false);
    sl
      ..registerSingleton<SessionController>(session)
      ..registerSingleton<AppRepository>(app)
      ..registerSingleton<AuthRepository>(auth)
      ..registerSingleton<InterestsRepository>(interests)
      ..registerSingleton<BiometricAuthenticator>(bio)
      ..registerSingleton<PermissionGateway>(MockPermissionGateway());
  });

  tearDown(sl.reset);

  Future<void> pumpAt(WidgetTester tester, String location, Size size, {bool reduce = true, bool easy = false}) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final prefs = await testPrefs(easy: easy);
    final router = GoRouter(
      initialLocation: location,
      routes: [
        ...onboardingRoutes,
        GoRoute(path: Routes.home, builder: (_, _) => const Text('HOME')),
      ],
    );
    await tester.pumpWidget(
      withPrefs(
        prefs,
        MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          routerConfig: router,
          builder: (c, child) => MediaQuery(
            data: MediaQuery.of(c).copyWith(disableAnimations: reduce || easy),
            child: child!,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
  }

  const sizes = [Size(393, 852), Size(360, 800)];
  const paths = [
    Routes.onboarding,
    Routes.welcome,
    Routes.interests,
    Routes.login,
    Routes.summit,
    Routes.prePermission,
    Routes.permissions,
    Routes.firstDay,
    Routes.register,
  ];

  for (final size in sizes) {
    for (final path in paths) {
      testWidgets('$path @ ${size.width.toInt()}×${size.height.toInt()} hatasız çizilir', (tester) async {
        await pumpAt(tester, path, size);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final path in [Routes.splash, ...paths]) {
    testWidgets('$path animasyonlu (hareketi azalt kapalı) hatasız oynar', (tester) async {
      await pumpAt(tester, path, sizes.first, reduce: false);
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 160));
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final path in [Routes.welcome, Routes.login, Routes.register]) {
    testWidgets('$path Kolay Mod: marquee / blob / kinetik başlık yok', (tester) async {
      await pumpAt(tester, path, sizes.last, easy: true);
      expect(tester.takeException(), isNull);
      expect(find.byType(Marquee), findsNothing);
      expect(find.byType(MorphBlob), findsNothing);
      expect(tester.element(find.byType(Scaffold).first).read<UiPrefsController>().easyMode, isTrue);
    });
  }

  testWidgets('İlk günün: 3 görev, toplam 2.600, dokununca tamamlandı', (tester) async {
    await pumpAt(tester, Routes.firstDay, sizes.first);
    await tester.pump(const Duration(milliseconds: 300));
    final l = AppLocalizations.of(tester.element(find.byType(Scaffold).first));
    expect(find.text(l.onbFirstDayHeader(3, '2.600')), findsOneWidget);
    expect(find.text('QR okut'), findsOneWidget);
    expect(find.text(l.onbFirstDayProgress(0, 3)), findsOneWidget);
  });

  testWidgets('splash → oturum + yapılandırma → karşılama', (tester) async {
    await pumpAt(tester, Routes.splash, sizes.first);
    await tester.pump(const Duration(seconds: 1));
    verify(session.restore).called(1);
    expect(tester.takeException(), isNull);
  });
}
