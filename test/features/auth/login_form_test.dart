import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/core/theme/app_theme.dart';
import 'package:bbb_genclik_kulubu_app/features/auth/view_model/login_view_model.dart';
import 'package:bbb_genclik_kulubu_app/features/auth/widgets/login_form.dart';
import 'package:bbb_genclik_kulubu_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../onboarding/fakes.dart';

void main() {
  setUpAll(registerAuthFallbacks);

  testWidgets('hatalı şifre → kalan hak mesajı; doğru şifre → onSuccess', (tester) async {
    final auth = MockAuthRepository();
    final bio = MockBiometric();
    when(bio.isAvailable).thenAnswer((_) async => false);
    var calls = 0;
    when(
      () => auth.login(any()),
    ).thenAnswer((_) async => calls++ == 0 ? const Failure(UnauthorizedException()) : const Success(demoSession));
    final vm = LoginViewModel(auth, stubSession(), bio);
    var success = false;
    final prefs = await testPrefs();
    await tester.pumpWidget(
      withPrefs(prefs, MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true, size: Size(393, 852)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: ChangeNotifierProvider.value(
                value: vm,
                child: LoginForm(onSuccess: () => success = true),
              ),
            ),
          ),
        ),
      )),
    );
    final l = AppLocalizations.of(tester.element(find.byType(LoginForm)));
    await tester.enterText(find.byType(TextField).at(0), '10000000146');
    await tester.enterText(find.byType(TextField).at(1), 'yanlis123');
    await tester.tap(find.text(l.authLogin));
    await tester.pumpAndSettle();
    expect(find.text(l.authWrongPassword(2)), findsOneWidget);
    expect(success, isFalse);

    await tester.enterText(find.byType(TextField).at(1), 'Dogru1234');
    await tester.tap(find.text(l.authLogin));
    await tester.pumpAndSettle();
    expect(success, isTrue);
  });
}
