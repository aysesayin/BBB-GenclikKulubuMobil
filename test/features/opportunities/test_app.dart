import 'dart:convert';

import 'package:bbb_genclik_kulubu_app/core/session/session_controller.dart';
import 'package:bbb_genclik_kulubu_app/core/storage/cache_store.dart';
import 'package:bbb_genclik_kulubu_app/core/storage/secure_storage.dart';
import 'package:bbb_genclik_kulubu_app/core/theme/app_theme.dart';
import 'package:bbb_genclik_kulubu_app/data/models/app/app_config.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/app_repository.dart';
import 'package:bbb_genclik_kulubu_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSecure extends Mock implements SecureStorage {}

class _MockAppRepo extends Mock implements AppRepository {}

/// Üye / misafir oturumu (gerçek SessionController, sahte güvenli depo).
Future<SessionController> testSession({required bool member}) async {
  SharedPreferences.setMockInitialValues({
    if (member) 'user.session': jsonEncode(const SessionUser(id: 'usr-demo', firstName: 'Ayşe', lastName: 'Su').toJson()),
  });
  final secure = _MockSecure();
  when(() => secure.accessToken).thenAnswer((_) async => member ? 'tok' : null);
  final s = SessionController(secure: secure, cache: await CacheStore.create());
  await s.restore();
  return s;
}

/// 393×852 iOS artboard boyutunda, Türkçe, açık temalı test uygulaması.
Future<void> pumpTestApp(
  WidgetTester tester, {
  required SessionController session,
  required List<RouteBase> routes,
  required String initial,
  ThemeData? theme,
}) async {
  tester.view
    ..physicalSize = const Size(393 * 3, 852 * 3)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final router = GoRouter(initialLocation: initial, routes: routes);
  addTearDown(router.dispose);
  final appRepo = _MockAppRepo();
  when(() => appRepo.current).thenReturn(const AppConfig());
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SessionController>.value(value: session),
        Provider<AppRepository>.value(value: appRepo),
      ],
      child: MaterialApp.router(
        theme: theme ?? AppTheme.light,
        locale: const Locale('tr'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Zamanlayıcı/animasyon bırakmadan ağacı kapatır.
Future<void> disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 3));
}
