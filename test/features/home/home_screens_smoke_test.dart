// Ekranların iOS (393×852) ve Android (360×800) boyutlarında, açık/koyu temada
// hatasız (taşma / SVG / düzen istisnası olmadan) çizildiğini doğrular.
import 'dart:convert';
import 'dart:io';

import 'package:bbb_genclik_kulubu_app/core/di/locator.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/core/theme/app_theme.dart';
import 'package:bbb_genclik_kulubu_app/data/models/home/home_feed.dart';
import 'package:bbb_genclik_kulubu_app/data/models/notifications/app_notification.dart';
import 'package:bbb_genclik_kulubu_app/data/models/search/search_result.dart';
import 'package:bbb_genclik_kulubu_app/data/models/stories/story.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/home_repository.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/notification_repository.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/search_repository.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/story_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/home/view/home_view.dart';
import 'package:bbb_genclik_kulubu_app/features/home/view_model/home_view_model.dart';
import 'package:bbb_genclik_kulubu_app/features/home/widgets/home_content.dart';
import 'package:bbb_genclik_kulubu_app/features/home/widgets/home_skeleton.dart';
import 'package:bbb_genclik_kulubu_app/features/notifications/view/notifications_view.dart';
import 'package:bbb_genclik_kulubu_app/features/search/view/search_view.dart';
import 'package:bbb_genclik_kulubu_app/features/stories/view/story_view.dart';
import 'package:bbb_genclik_kulubu_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

class _Home extends Mock implements HomeRepository {}

class _Notif extends Mock implements NotificationRepository {}

class _Search extends Mock implements SearchRepository {}

class _Story extends Mock implements StoryRepository {}

Map<String, dynamic> _data(String file) =>
    (jsonDecode(File('assets/mock/$file').readAsStringSync()) as Map<String, dynamic>)['data'] as Map<String, dynamic>;

List<T> _items<T>(String file, T Function(Map<String, dynamic>) f) =>
    (_data(file)['items'] as List).map((e) => f(e as Map<String, dynamic>)).toList();

Widget _app(Widget child, {required bool dark}) => MaterialApp(
  theme: dark ? AppTheme.dark : AppTheme.light,
  locale: const Locale('tr'),
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Scaffold(body: child),
);

const _sizes = [Size(393, 852), Size(360, 800)];

Future<void> _forEachVariant(WidgetTester tester, Future<void> Function(bool dark) body) async {
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

void main() {
  final feed = HomeFeed.fromJson(_data('home.json'));

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
    registerFallbackValue(NotificationCategory.earn);
    final home = _Home(), notif = _Notif(), search = _Search(), story = _Story();
    when(home.fetchHome).thenAnswer((_) async => const Failure(NetworkException()));
    when(
      () => notif.list(category: any(named: 'category')),
    ).thenAnswer((_) async => Success(_items('notifications.json', AppNotification.fromJson)));
    when(notif.readAll).thenAnswer((_) async => const Success<void>(null));
    when(() => search.search(any())).thenAnswer((_) async => Success(_items('search.json', SearchResult.fromJson)));
    when(search.popularTags).thenAnswer((_) async => const Success(['Teleferik', 'Konser', 'Kamp', 'YKS', 'Ücretsiz']));
    when(search.recentSearches).thenReturn(['Yüzme kursu', 'Kitap indirimi']);
    when(() => search.addRecent(any())).thenAnswer((_) async => ['Teleferik']);
    when(() => story.detail(any())).thenAnswer((_) async => Success(Story.fromJson(_data('stories._.json'))));
    when(() => story.markSeen(any())).thenAnswer((_) async => const Success<void>(null));
    sl
      ..registerSingleton<HomeRepository>(home)
      ..registerSingleton<NotificationRepository>(notif)
      ..registerSingleton<SearchRepository>(search)
      ..registerSingleton<StoryRepository>(story);
  });

  testWidgets('B1 Keşfet içerik (uzun ekran, tüm bloklar)', (tester) async {
    await _forEachVariant(tester, (dark) async {
      tester.view.physicalSize = Size(tester.view.physicalSize.width, 2600);
      await tester.pumpWidget(
        _app(
          HomeContent(feed: feed, greeting: HomeGreeting.morning, offline: dark, onRefresh: () async {}),
          dark: dark,
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Ayşe'), findsOneWidget);
      expect(find.text('Bugünün Görevleri'), findsOneWidget);
      expect(find.text('Haftalık Lig · Gümüş'), findsOneWidget);
      expect(find.text('Aşık Veysel GM · 650 m'), findsOneWidget);
      expect(find.text('14. sıradasın · sezon 2g 14s sonra biter'), findsOneWidget);
    });
  });

  testWidgets('B1 Keşfet içerik — 360 px, yazı ölçeği 1.35', (tester) async {
    tester.view.physicalSize = const Size(360, 2800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.35;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      _app(HomeContent(feed: feed, greeting: HomeGreeting.evening, offline: false, onRefresh: () async {}), dark: false),
    );
    await tester.pump(const Duration(milliseconds: 300));
    final ctx = tester.element(find.byType(HomeContent));
    expect(MediaQuery.textScalerOf(ctx).scale(10), closeTo(13.5, .01));
  });

  testWidgets('S1 skeleton', (tester) async {
    await _forEachVariant(tester, (dark) async {
      await tester.pumpWidget(_app(const HomeSkeleton(), dark: dark));
      await tester.pump(const Duration(milliseconds: 600));
    });
  });

  testWidgets('S3 çevrimdışı (önbellek yok)', (tester) async {
    await _forEachVariant(tester, (dark) async {
      await tester.pumpWidget(_app(const HomeView(), dark: dark));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Bağlantı koptu'), findsOneWidget);
      expect(find.text('Kartımı göster'), findsOneWidget);
      expect(find.text('Çevrimdışısın · kayıtlı içerik gösteriliyor'), findsOneWidget);
    });
  });

  testWidgets('B2 Arama: öneriler → sonuçlar', (tester) async {
    await _forEachVariant(tester, (dark) async {
      await tester.pumpWidget(_app(const SearchView(), dark: dark));
      await tester.pump();
      expect(find.text('Son aramalar'), findsOneWidget);
      expect(find.text('#Teleferik'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Teleferik');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('FIRSATLAR'), findsOneWidget);
      expect(find.text('Tümü · 6'), findsOneWidget);
    });
  });

  testWidgets('B3 Bildirimler', (tester) async {
    await _forEachVariant(tester, (dark) async {
      await tester.pumpWidget(_app(const NotificationsView(), dark: dark));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Tümünü okundu yap'), findsOneWidget);
      expect(find.text('Yeni'), findsWidgets);
    });
  });

  testWidgets('B4 Hikâye', (tester) async {
    await _forEachVariant(tester, (dark) async {
      await tester.pumpWidget(_app(const StoryView(storyId: 'sto-genclik-kampi'), dark: dark));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Gençlik Kampı kayıtları açıldı!'), findsOneWidget);
      await tester.pump(const Duration(seconds: 6));
      await tester.pump();
      expect(find.text('Kitaplarda %20 öğrenci indirimi'), findsOneWidget);
    });
  });
}
