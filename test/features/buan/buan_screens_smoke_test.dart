// BUAN ana, Pazar ve genel görev detayı ekranlarının iOS (393×852) ve Android (360×800)
// boyutlarında, açık/koyu temada ve Kolay Mod'da gerçek yazı tipleriyle taşmasız çizildiğini doğrular.
import 'dart:convert';
import 'dart:io';

import 'package:bbb_genclik_kulubu_app/core/di/locator.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/dio_client.dart';
import 'package:bbb_genclik_kulubu_app/core/storage/cache_store.dart';
import 'package:bbb_genclik_kulubu_app/core/theme/app_theme.dart';
import 'package:bbb_genclik_kulubu_app/core/theme/ui_prefs_controller.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan/buan_reward.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan/buan_task.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan/buan_wallet.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/buan_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/market/view/market_view.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/tasks/detail/view/task_detail_view.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/view/buan_view.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/widgets/buan_hero.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/widgets/task_card.dart';
import 'package:bbb_genclik_kulubu_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'buan_fixtures.dart';

Map<String, dynamic> _data(String file) =>
    (jsonDecode(File('assets/mock/$file').readAsStringSync()) as Map<String, dynamic>)['data'] as Map<String, dynamic>;

const _sizes = [Size(393, 852), Size(360, 800)];

void main() {
  late MockBuanRepository repo;
  late UiPrefsController prefs;

  Widget app(Widget child, {bool dark = false}) => ChangeNotifierProvider<UiPrefsController>.value(
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
      home: child,
    ),
  );

  Future<void> forEachVariant(WidgetTester tester, Future<void> Function(bool dark) body) async {
    for (final size in _sizes) {
      for (final dark in [false, true]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await body(dark);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
    tester.view.reset();
  }

  Future<void> pump(WidgetTester tester, Widget view, {bool dark = false}) async {
    await tester.pumpWidget(app(view, dark: dark));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(seconds: 1));
  }

  setUpAll(() async {
    await initializeDateFormatting('tr');
    // Gerçek yazı tipleri: taşma ölçümleri tasarımdakiyle aynı olsun (Ahem daha geniştir).
    for (final (family, weights) in [
      ('Nunito', [600, 700, 800, 900]),
      ('Baloo2', [800]),
    ]) {
      final loader = FontLoader(family);
      for (final w in weights) {
        loader.addFont(Future.value(ByteData.sublistView(File('assets/fonts/$family-$w.ttf').readAsBytesSync())));
      }
      await loader.load();
    }
    SharedPreferences.setMockInitialValues({});
    final cache = await CacheStore.create();
    prefs = UiPrefsController(cache);
    repo = MockBuanRepository(balance: 12450);
    when(() => repo.wallet()).thenAnswer((_) async => Success(BuanWallet.fromJson(_data('buan.wallet.json'))));
    when(() => repo.level()).thenAnswer((_) async => Success(BuanLevel.fromJson(_data('buan.level.json'))));
    when(() => repo.streak()).thenAnswer((_) async => Success(BuanStreak.fromJson(_data('buan.streak.json'))));
    when(() => repo.tasks()).thenAnswer((_) async => Success(Json.list(_data('buan.tasks.json')['groups'], BuanTaskGroup.fromJson)));
    when(() => repo.market()).thenAnswer((_) async => Success(BuanMarket.fromJson(_data('buan.rewards.json'))));
    when(
      () => repo.completeTask(any(), declared: any(named: 'declared')),
    ).thenAnswer((_) async => const Success(TaskCompleteResult(status: BuanTaskStatus.pending)));
    sl.registerSingleton<BuanRepository>(repo);
  });

  tearDownAll(sl.reset);

  setUp(() async => prefs.setEasyMode(false));

  testWidgets('E1 BUAN ana: kart düzeni 360/393, açık/koyu', (tester) async {
    await forEachVariant(tester, (dark) async {
      await pump(tester, const BuanView(), dark: dark);
      expect(find.byType(TaskCard), findsWidgets);
      expect(find.text('Bir Adım At'), findsOneWidget);
      expect(find.text('Sv 3 · Kâşif'), findsOneWidget);
      expect(find.text('Seri 7 gün'), findsOneWidget);
      expect(find.text('Kazan'), findsOneWidget);
    });
  });

  testWidgets('E1 hero kaydırınca 72 px bakiye çubuğuna iner, sekmeler sabit', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(tester, const BuanView());
    final heroAtRest = tester.getSize(find.byType(BuanHeroSurface));
    expect(heroAtRest.height, closeTo(852 * .25, 1));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pump(const Duration(seconds: 1));
    expect(tester.getSize(find.byType(BuanHeroSurface)).height, BuanHeroDelegate.barHeight);
    expect(find.text('12.450'), findsOneWidget);
    expect(find.text('Kazan'), findsOneWidget);
    expect(find.text('Sv 3 · Kâşif'), findsNothing);
  });

  testWidgets('E1 Kolay Mod: sekme yok, tek liste, üç büyük buton, 72 px kart', (tester) async {
    await prefs.setEasyMode(true);
    await forEachVariant(tester, (dark) async {
      tester.view.physicalSize = Size(tester.view.physicalSize.width, 3000);
      await pump(tester, const BuanView(), dark: dark);
      expect(find.text('Pazar'), findsNothing);
      expect(find.text('BUAN Pazar'), findsOneWidget);
      expect(find.text('Haftalık Lig'), findsOneWidget);
      expect(find.text('Rozetler'), findsOneWidget);
      expect(find.byType(BuanHeroSurface), findsNothing);
      for (final e in find.byType(TaskCard).evaluate()) {
        expect(tester.getSize(find.byWidget(e.widget)).height, greaterThanOrEqualTo(72));
      }
    });
  });

  testWidgets('E2 Pazar: yetmeyen ödülde "X BUAN daha"; Kolay Mod tek sütun', (tester) async {
    await forEachVariant(tester, (dark) async {
      await pump(tester, const MarketView(), dark: dark);
      expect(find.textContaining('BUAN daha'), findsWidgets);
    });
    await prefs.setEasyMode(true);
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(tester, const MarketView());
    expect(find.byType(IntrinsicHeight), findsNothing);
  });

  testWidgets('E13 görev detayı: takip beyanı → panel onayı bekleniyor', (tester) async {
    await forEachVariant(tester, (dark) async {
      await pump(tester, const TaskDetailView(taskId: 'tsk-volunteer'), dark: dark);
      expect(find.text('Gönül Dostu Ol'), findsWidgets);
      expect(find.text('Nasıl yapılır?'), findsOneWidget);
      expect(find.text('Kurallar'), findsOneWidget);
      expect(find.text('Sıklık: 1 kez'), findsOneWidget);
      expect(find.text('Başvur'), findsOneWidget);
    });
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pump(tester, const TaskDetailView(taskId: 'tsk-follow'));
    // Kilitli: 12 haftada 1 → eylem yok, kilit metni var.
    expect(find.textContaining('Şu an yapılamaz'), findsOneWidget);
    expect(find.text('Takip ettim, beyan et'), findsNothing);
    await pump(tester, const TaskDetailView(taskId: 'tsk-volunteer'));
    await tester.tap(find.text('Başvur'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Panel onayı bekleniyor'), findsOneWidget);
    expect(find.text('Başvurun alındı'), findsOneWidget);
    expect(find.text('Başvur'), findsNothing);
    await pump(tester, const TaskDetailView(taskId: 'tsk-yok'));
    expect(find.text('Görev bulunamadı'), findsOneWidget);
  });
}
