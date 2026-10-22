import 'package:bbb_genclik_kulubu_app/core/storage/cache_store.dart';
import 'package:bbb_genclik_kulubu_app/core/theme/app_theme.dart';
import 'package:bbb_genclik_kulubu_app/core/theme/ui_prefs_controller.dart';
import 'package:bbb_genclik_kulubu_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Testler için Kolay Mod denetleyicisi (bellek içi tercihler).
Future<UiPrefsController> testUiPrefs({bool easyMode = false}) async {
  SharedPreferences.setMockInitialValues({'pref.easyMode': easyMode});
  return UiPrefsController(CacheStore(await SharedPreferences.getInstance()));
}

/// G ekranları için duman testi kabı: tr yerel ayarı, tema, verilen ekran boyutu, Kolay Mod.
Future<void> pumpDiscoverScreen(
  WidgetTester tester,
  Widget screen, {
  Size size = const Size(393, 852),
  bool dark = false,
  bool easyMode = false,
}) async {
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final prefs = await testUiPrefs(easyMode: easyMode);
  await tester.pumpWidget(
    ChangeNotifierProvider<UiPrefsController>.value(
      value: prefs,
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
        home: screen,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
