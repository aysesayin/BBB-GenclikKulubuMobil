import 'package:bbb_genclik_kulubu_app/core/theme/app_theme.dart';
import 'package:bbb_genclik_kulubu_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

/// G ekranları için duman testi kabı: tr yerel ayarı, tema, verilen ekran boyutu.
Future<void> pumpDiscoverScreen(WidgetTester tester, Widget screen, {Size size = const Size(393, 852), bool dark = false}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppTheme.dark : AppTheme.light,
      locale: const Locale('tr'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: screen,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
