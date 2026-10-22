import 'package:bbb_genclik_kulubu_app/core/di/locator.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/router/routes.dart';
import 'package:bbb_genclik_kulubu_app/data/models/opportunities/claim.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/opportunity_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/opportunities/opportunities_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'opp_fixtures.dart';
import 'test_app.dart';

/// C3 · Yakalandı: uyanık kalma ipucu, "Kullandım" (mock) → puanlama sayfası → "+100" toast.
void main() {
  const id = 'opp-extrempark';
  late MockOpportunityRepository repo;

  setUp(() {
    (repo, _) = mockRepo();
    when(() => repo.mine()).thenAnswer((_) async => Success(walletItems));
    sl.registerSingleton<OpportunityRepository>(repo);
  });

  tearDown(() => sl.reset());

  final routes = <RouteBase>[
    ...opportunitiesRootRoutes,
    GoRoute(path: Routes.myOpportunities, builder: (_, _) => const SizedBox()),
    GoRoute(path: Routes.opportunities, builder: (_, _) => const SizedBox()),
  ];

  testWidgets('Kullandım → yıldız + yorum → Gönder → toast ve "Kullanıldı" rozeti', (tester) async {
    when(
      () => repo.rate(id, stars: 4, comment: any(named: 'comment')),
    ).thenAnswer((_) async => const Success(RatingResult(opportunityId: id, buanReward: 100, label: 'Fırsat Kullan Kazan')));
    await pumpTestApp(tester, session: await testSession(member: true), routes: routes, initial: Routes.opportunityClaimed(id));

    expect(find.text('Fırsat senin!'), findsOneWidget);
    expect(find.textContaining('Ekran kapanırsa'), findsOneWidget);

    await tester.tap(find.text('Kullandım'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Fırsat nasıldı?'), findsOneWidget);
    expect(find.text('Kullanıldı'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('4 yıldız'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'Harika');
    await tester.tap(find.text('Gönder'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    verify(() => repo.rate(id, stars: 4, comment: 'Harika')).called(1);
    expect(find.text('Fırsat nasıldı?'), findsNothing);
    expect(find.text('Fırsat Kullan Kazan'), findsOneWidget);
    expect(find.text('+100'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await disposeApp(tester);
  });

  testWidgets('Kolay Mod: alt butonlar alt alta tam genişlik', (tester) async {
    await pumpTestApp(
      tester,
      session: await testSession(member: true),
      routes: routes,
      initial: Routes.opportunityClaimed(id),
      easyMode: true,
    );
    final mine = tester.getRect(find.text('Fırsatlarım'));
    final done = tester.getRect(find.text('Tamam'));
    expect(done.top, greaterThan(mine.bottom));
    await disposeApp(tester);
  });
}
