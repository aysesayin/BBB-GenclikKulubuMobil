import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/core/router/routes.dart';
import 'package:bbb_genclik_kulubu_app/core/theme/app_theme.dart';
import 'package:bbb_genclik_kulubu_app/core/theme/ui_prefs_controller.dart';
import 'package:bbb_genclik_kulubu_app/data/models/auth/auth_requests.dart';
import 'package:bbb_genclik_kulubu_app/data/models/auth/otp_challenge.dart';
import 'package:bbb_genclik_kulubu_app/features/auth/view/register_view.dart';
import 'package:bbb_genclik_kulubu_app/features/auth/view_model/register_view_model.dart';
import 'package:bbb_genclik_kulubu_app/features/onboarding/widgets/motion.dart';
import 'package:bbb_genclik_kulubu_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../onboarding/fakes.dart';

void main() {
  setUpAll(() async {
    registerAuthFallbacks();
    await initializeDateFormatting('tr');
  });

  late MockAuthRepository auth;
  late MockInterestsRepository interests;
  late MockSession session;
  late RegisterViewModel vm;

  setUp(() {
    auth = MockAuthRepository();
    interests = MockInterestsRepository();
    session = stubSession();
    when(() => auth.onboardingBonusHeld).thenReturn(false);
    when(
      () => auth.sendOtp(any(), resend: any(named: 'resend')),
    ).thenAnswer((_) async => const Success(OtpChallenge(maskedPhone: '0532 *** ** 90', resendIn: 45)));
    when(() => auth.verifyOtp(any(), any())).thenAnswer(
      (i) async => i.positionalArguments[1] == '481926'
          ? const Success(OtpVerification(verificationToken: 'otp-tok'))
          : const Failure(ValidationException()),
    );
    when(
      () => auth.verifyMernis(
        tckn: any(named: 'tckn'),
        birthDate: any(named: 'birthDate'),
      ),
    ).thenAnswer((_) async => const Success(MernisResult(verified: true)));
    when(() => auth.register(any())).thenAnswer((_) async => const Success(demoSession));
    when(interests.saveHeld).thenAnswer((_) async => const Success(null));
  });

  Future<AppLocalizations> pumpFlow(WidgetTester tester, {bool easy = false}) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final prefs = await testPrefs(easy: easy);
    final router = GoRouter(
      initialLocation: Routes.register,
      routes: [
        GoRoute(
          path: Routes.register,
          builder: (_, _) => ChangeNotifierProvider(
            create: (_) => vm = RegisterViewModel(
              auth,
              interests,
              stubApp(),
              session,
              clock: () => DateTime(2026, 10, 16),
              minScene: Duration.zero,
              otpAdvance: Duration.zero,
            ),
            child: const RegisterBody(),
          ),
        ),
        GoRoute(
          path: Routes.summit,
          builder: (_, _) => const Scaffold(body: Text('SUMMIT')),
        ),
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
          // Döngüsel animasyonlar kapalı (hareketi azalt) → pumpAndSettle güvenli.
          builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(disableAnimations: true), child: child!),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.byType(RegisterBody)));
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  testWidgets('kayıt akışı (5 ekran): TCKN → telefon → OTP → sözleşmeler → MERNİS → Zirve', (tester) async {
    final l = await pumpFlow(tester);
    expect(find.text(l.authRegIdentityTitle), findsOneWidget);

    // Geçersiz TCKN anında işaretlenir, Devam sallar ve adımda kalır.
    await tester.enterText(find.byType(TextField).first, '12345678901');
    await tester.pumpAndSettle();
    expect(find.text(l.authTcknInvalid), findsOneWidget);
    await tapText(tester, l.commonContinue);
    expect(find.text(l.authRegIdentityTitle), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '10000000146');
    await tester.pumpAndSettle();
    expect(find.text(l.authTcknValid), findsOneWidget);
    await tapText(tester, l.commonContinue);

    // Telefon (yalnız cep; e-posta profilden)
    expect(find.text(l.authRegContactTitle), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '5324182790');
    await tapText(tester, l.commonContinue);
    verify(() => auth.sendOtp('05324182790', resend: false)).called(1);

    // OTP: yanlış → hata, doğru → sözleşmeler
    expect(find.text(l.authOtpSent('0532 *** ** 90')), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '000000');
    await tester.pumpAndSettle();
    expect(find.text(l.authOtpWrong), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '481926');
    await tester.pumpAndSettle();

    // Sözleşmeler: 4 zorunlu onay olmadan buton pasif
    expect(find.text(l.authRegLegalTitle), findsOneWidget);
    await tapText(tester, l.authLegalConfirm);
    expect(find.text(l.authRegLegalTitle), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byType(Checkbox).at(i));
      await tester.pump();
    }
    expect(vm.allRequiredAccepted, isTrue);
    expect(vm.explicitConsent, isFalse);
    await tapText(tester, l.authLegalConfirm);

    // MERNİS + kayıt → Doğrulandı → Zirve
    expect(find.text(l.authVerified), findsOneWidget);
    final req = verify(() => auth.register(captureAny())).captured.single as RegisterRequest;
    expect(req.tckn, '10000000146');
    expect(req.acceptedConsents, hasLength(4));
    expect(req.email, isNull);
    expect(req.emergencyContact, isNull);
    verify(
      () => session.signIn(
        accessToken: 'a',
        refreshToken: 'r',
        user: any(named: 'user'),
      ),
    ).called(1);

    await tapText(tester, l.authSummitCta);
    expect(find.text('SUMMIT'), findsOneWidget);
  });

  testWidgets('18 yaş altı: veli onayı ekranı', (tester) async {
    final l = await pumpFlow(tester);
    await tester.enterText(find.byType(TextField).first, '10000000146');
    vm.setBirthDate(DateTime(2009, 5, 1));
    await tester.pumpAndSettle();
    await tapText(tester, l.commonContinue);
    expect(find.text(l.authUnderAgeTitle), findsOneWidget);
    expect(find.text(l.authParentSend), findsOneWidget);

    // Geri → kimlik adımı
    await tester.tap(find.bySemanticsLabel(l.commonBack));
    await tester.pumpAndSettle();
    expect(find.text(l.authRegIdentityTitle), findsOneWidget);
  });

  testWidgets('Kolay Mod: dekoratif blob yok, 56 px dokunma hedefi', (tester) async {
    final l = await pumpFlow(tester, easy: true);
    expect(find.byType(MorphBlob), findsNothing);
    final later = tester.widget<TextButton>(find.widgetWithText(TextButton, l.authRegLater));
    expect(later.style?.minimumSize?.resolve({}), const Size(56, 56));
    expect(tester.element(find.byType(RegisterBody)).read<UiPrefsController>().easyMode, isTrue);
  });
}
