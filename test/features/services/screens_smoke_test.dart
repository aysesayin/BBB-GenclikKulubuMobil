import 'dart:convert';
import 'dart:io';

import 'package:bbb_genclik_kulubu_app/core/di/locator.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/dio_client.dart';
import 'package:bbb_genclik_kulubu_app/core/theme/app_theme.dart';
import 'package:bbb_genclik_kulubu_app/core/theme/ui_prefs_controller.dart';
import 'package:bbb_genclik_kulubu_app/core/widgets/widgets.dart';
import 'package:bbb_genclik_kulubu_app/data/models/services/application.dart';
import 'package:bbb_genclik_kulubu_app/data/models/services/facility.dart';
import 'package:bbb_genclik_kulubu_app/data/models/services/session.dart';
import 'package:bbb_genclik_kulubu_app/data/models/services/sports.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/application_repository.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/cart_repository.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/facility_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/services/applications/view/applications_view.dart';
import 'package:bbb_genclik_kulubu_app/features/services/pool/view/pools_view.dart';
import 'package:bbb_genclik_kulubu_app/features/services/session/view/session_view.dart';
import 'package:bbb_genclik_kulubu_app/features/services/sports_school/view/sports_school_view.dart';
import 'package:bbb_genclik_kulubu_app/features/services/widgets/service_row_card.dart';
import 'package:bbb_genclik_kulubu_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';

import '../events/discover_test_app.dart';
import 'svc_fixtures.dart';

Object? _data(String name) => (jsonDecode(File('assets/mock/$name').readAsStringSync()) as Map)['data'];

/// Ekranlar gerçek mock verisiyle 393 ve 360 px genişlikte taşmadan çizilir.
void main() {
  late MockFacilityRepository facility;
  late MockApplicationRepository apps;

  setUpAll(() async {
    await initializeDateFormatting('tr');
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    facility = MockFacilityRepository();
    apps = MockApplicationRepository();
    when(() => facility.pools()).thenAnswer((_) async => Success(PoolCatalog.fromJson(Json.map(_data('services.pools.json')))));
    when(
      () => facility.items(any()),
    ).thenAnswer((_) async => Success(Json.list(_data('services.facilities.fac-fethiye.items.json'), ServiceItem.fromJson)));
    when(
      () => facility.sessions(
        any(),
        from: any(named: 'from'),
        to: any(named: 'to'),
      ),
    ).thenAnswer((_) async => Success(SessionWeek.fromJson(Json.map(_data('services.items.itm-fethiye-gunluk.sessions.json')))));
    when(
      () => facility.sportsCatalog(),
    ).thenAnswer((_) async => Success(SportsCatalog.fromJson(Json.map(_data('services.sports-branches.json')))));
    when(
      () => facility.tennisProducts(),
    ).thenAnswer((_) async => Success(Json.list(_data('services.tennis-products.json'), TennisProduct.fromJson)));
    when(
      () => apps.list(status: any(named: 'status')),
    ).thenAnswer((_) async => Success(Json.list(_data('applications.json'), Application.fromJson)));
    sl
      ..registerSingleton<FacilityRepository>(facility)
      ..registerSingleton<CartRepository>(MockCartRepository())
      ..registerSingleton<ApplicationRepository>(apps);
  });

  tearDown(sl.reset);

  Future<void> pump(WidgetTester tester, Widget child, double width, {bool easy = false}) async {
    tester.view.physicalSize = Size(width * 3, 800 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final prefs = await testUiPrefs(easyMode: easy);
    await tester.pumpWidget(
      ChangeNotifierProvider<UiPrefsController>.value(
        value: prefs,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('tr'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: child,
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  for (final width in [393.0, 360.0]) {
    testWidgets('Havuzlar @$width', (tester) async {
      await pump(tester, const PoolsView(), width);
      expect(find.text('Fethiye · hizmetler'), findsOneWidget);
      expect(find.text('Günlük Giriş'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Seans @$width', (tester) async {
      await pump(tester, const SessionView(itemId: 'itm-fethiye-gunluk'), width);
      expect(find.text('Fethiye Havuzu'), findsOneWidget);
      expect(find.text('Bir seans seç'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Spor @$width', (tester) async {
      await pump(tester, const SportsSchoolView(), width);
      expect(find.text('Yüzme'), findsOneWidget);
      await tester.tap(find.text('Tenis'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Özel ders'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Seans Kolay Mod @$width: tek gün + büyük gün düğmeleri', (tester) async {
      await pump(tester, const SessionView(itemId: 'itm-fethiye-gunluk'), width, easy: true);
      expect(find.text('Fethiye Havuzu'), findsOneWidget);
      expect(find.bySemanticsLabel('Sonraki gün'), findsOneWidget);
      expect(find.bySemanticsLabel('Önceki gün'), findsOneWidget);
      expect(find.text('Haftalık seans takvimi'), findsNothing);
      expect(find.bySemanticsLabel('Sonraki hafta'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Sonraki gün'));
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('Havuzlar / Spor Kolay Mod @$width: 64 px satırlar', (tester) async {
      await pump(tester, const PoolsView(), width, easy: true);
      expect(find.text('Günlük Giriş'), findsOneWidget);
      final tile = tester.getSize(find.byType(IconTile).first);
      expect(tile.width, 64);
      await pump(tester, const SportsSchoolView(), width, easy: true);
      expect(find.text('Yüzme'), findsOneWidget);
      expect(find.byType(ServiceRowCard), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Başvurularım @$width', (tester) async {
      await pump(tester, const ApplicationsView(), width);
      expect(find.text('Aktif · 3'), findsOneWidget);
      expect(find.text('Turnikede okut'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
