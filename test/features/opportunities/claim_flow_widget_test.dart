import 'package:bbb_genclik_kulubu_app/core/di/locator.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/router/routes.dart';
import 'package:bbb_genclik_kulubu_app/core/session/session_controller.dart';
import 'package:bbb_genclik_kulubu_app/data/models/opportunities/claim.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/opportunity_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/opportunities/opportunities_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'opp_fixtures.dart';
import 'test_app.dart';

/// C2 → C3 kritik akış: detay → "Fırsatı Yakala" → Yakalandı (PNR → QR + kod parçaları).
void main() {
  const id = 'opp-extrempark';
  late MockOpportunityRepository repo;

  Future<SessionController> session({required bool member}) => testSession(member: member);

  Future<void> pumpApp(WidgetTester tester, SessionController s) => pumpTestApp(
    tester,
    session: s,
    initial: Routes.opportunity(id),
    routes: [
      ...opportunitiesRootRoutes,
      GoRoute(path: Routes.myOpportunities, builder: (_, _) => const SizedBox()),
      GoRoute(path: Routes.opportunities, builder: (_, _) => const SizedBox()),
    ],
  );

  setUp(() {
    (repo, _) = mockRepo();
    when(() => repo.detail(id)).thenAnswer((_) async => Success(detailOf(opp(id, daysLeft: 5, remaining: 18, total: 200))));
    sl.registerSingleton<OpportunityRepository>(repo);
  });

  tearDown(() => sl.reset());

  testWidgets('üye: Fırsatı Yakala → Yakalandı ekranı PNR kodunu ve QR\'ı gösterir', (tester) async {
    when(() => repo.claim(id)).thenAnswer((_) async => Success(claimOf(id)));
    await pumpApp(tester, await session(member: true));

    expect(find.text('Başlık $id'), findsOneWidget);
    expect(find.text('18 / 200'), findsOneWidget);

    await tester.tap(find.text('Fırsatı Yakala'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    verify(() => repo.claim(id)).called(1);
    expect(find.text('Fırsat senin!'), findsOneWidget);
    expect(find.text('PNR kodun QR’a dönüştürüldü'), findsOneWidget);
    for (final part in ['K7', 'Q2', 'M8']) {
      expect(find.text(part), findsOneWidget);
    }
    expect(find.bySemanticsLabel('Kasada okutulacak QR kod'), findsOneWidget);
    expect(find.bySemanticsLabel('Kod: K 7 Q 2 M 8'), findsOneWidget);
    expect(find.textContaining('içinde kullan'), findsOneWidget);

    // Toast (2,5 sn) ve konfeti bitsin; ardından ağacı kapat → zamanlayıcı kalmasın.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('üye: indirim kodu kopyalanınca "Kopyalandı" olur', (tester) async {
    final code = ClaimResult(
      opportunityId: id,
      code: 'EXT-7K2Q-91',
      expiresAt: DateTime.now().add(const Duration(hours: 2)),
      brand: 'Extrempark',
      title: 'Tırmanma',
    );
    when(() => repo.claim(id)).thenAnswer((_) async => Success(code));
    await pumpApp(tester, await session(member: true));
    await tester.tap(find.text('Fırsatı Yakala'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('EXT-7K2Q-91'), findsOneWidget);
    expect(find.bySemanticsLabel('Kod: E X T 7 K 2 Q 9 1'), findsOneWidget);
    await tester.ensureVisible(find.text('Kodu kopyala'));
    await tester.tap(find.text('Kodu kopyala'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Kopyalandı'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('misafir: CTA kayıt duvarını açar, kod istenmez', (tester) async {
    await pumpApp(tester, await session(member: false));
    await tester.tap(find.text('Fırsatı Yakala'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Fırsatı kapmak için kayıt ol'), findsOneWidget);
    verifyNever(() => repo.claim(any()));
  });
}
