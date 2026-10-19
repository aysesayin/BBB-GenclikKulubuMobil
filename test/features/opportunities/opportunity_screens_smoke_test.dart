import 'package:bbb_genclik_kulubu_app/core/di/locator.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/router/routes.dart';
import 'package:bbb_genclik_kulubu_app/core/theme/app_theme.dart';
import 'package:bbb_genclik_kulubu_app/data/models/opportunities/opportunity.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/opportunity_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/opportunities/opportunities_routes.dart';
import 'package:bbb_genclik_kulubu_app/features/opportunities/view/opportunity_list_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import 'opp_fixtures.dart';
import 'test_app.dart';

/// Ekranlar 393 px'te taşmadan çizilir (açık + koyu), boş durum ve yaş kilidi görünür.
void main() {
  late MockOpportunityRepository repo;

  setUpAll(() async {
    registerFallbackValue(OpportunityFilter.nearby);
    await initializeDateFormatting('tr');
  });

  setUp(() {
    (repo, _) = mockRepo();
    when(
      () => repo.categories(),
    ).thenAnswer((_) async => const Success([OpportunityCategory(id: 'cat-ulasim', label: 'Ulaşım', icon: 'bus')]));
    when(() => repo.mine()).thenAnswer((_) async => Success(walletItems));
    when(
      () => repo.list(
        category: any(named: 'category'),
        filter: any(named: 'filter'),
        page: any(named: 'page'),
      ),
    ).thenAnswer((_) async => Success(demoList, meta: const PageMeta(page: 1, pageSize: 20, total: 4)));
    sl.registerSingleton<OpportunityRepository>(repo);
  });

  tearDown(() => sl.reset());

  final routes = <RouteBase>[
    GoRoute(path: Routes.opportunities, builder: (_, _) => const OpportunityListView(), routes: opportunitiesBranchRoutes),
    ...opportunitiesRootRoutes,
  ];

  for (final dark in [false, true]) {
    testWidgets('liste (${dark ? 'koyu' : 'açık'}): kartlar, cüzdan sayacı, favoriler boş durumu', (tester) async {
      await pumpTestApp(
        tester,
        session: await testSession(member: true),
        routes: routes,
        initial: Routes.opportunities,
        theme: dark ? AppTheme.dark : null,
      );
      expect(find.text('Cüzdan · 2'), findsOneWidget);
      expect(find.text('4 fırsat'), findsOneWidget);
      expect(find.text('Başlık opp-burulas'), findsOneWidget);

      when(
        () => repo.list(
          category: any(named: 'category'),
          filter: any(named: 'filter'),
          page: any(named: 'page'),
        ),
      ).thenAnswer((_) async => Success([opp('x')], meta: const PageMeta(page: 1, pageSize: 20, total: 1)));
      await tester.ensureVisible(find.text('Favoriler'));
      await tester.tap(find.text('Favoriler'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Fırsatlara göz at'), findsOneWidget);
      await disposeApp(tester);
    });
  }

  testWidgets('cüzdan: segmentler ve kupon kartları', (tester) async {
    await pumpTestApp(tester, session: await testSession(member: true), routes: routes, initial: Routes.myOpportunities);
    expect(find.text('Aktif · 2'), findsOneWidget);
    expect(find.text('Kullanıldı · 1'), findsOneWidget);
    await tester.tap(find.text('Kullanıldı · 1'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('+100 BUAN'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('detay: yaş uygun değilse CTA pasif ve gerekçe görünür', (tester) async {
    when(() => repo.detail('opp-dilokulu')).thenAnswer((_) async => Success(detailOf(opp('opp-dilokulu'), eligible: false, minAge: 18)));
    await pumpTestApp(tester, session: await testSession(member: true), routes: routes, initial: Routes.opportunity('opp-dilokulu'));
    expect(find.text('Bu içerik 18–30 yaş için'), findsOneWidget);
    await tester.tap(find.text('Fırsatı Yakala'));
    await tester.pump();
    verifyNever(() => repo.claim(any()));
    await disposeApp(tester);
  });
}
