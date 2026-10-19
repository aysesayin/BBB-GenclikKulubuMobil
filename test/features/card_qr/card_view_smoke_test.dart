import 'package:bbb_genclik_kulubu_app/core/di/locator.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/core/router/routes.dart';
import 'package:bbb_genclik_kulubu_app/data/models/card/digital_card.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/card_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/card_qr/view/card_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../opportunities/test_app.dart';
import 'card_mocks.dart';

void main() {
  late MockCardRepository repo;
  final routes = [GoRoute(path: Routes.card, builder: (_, _) => const CardView())];

  setUp(() {
    repo = MockCardRepository();
    when(() => repo.card()).thenAnswer(
      (_) async => const Success(DigitalCard(firstName: 'Ayşe', lastName: 'Su', memberNo: '0016 4821', level: 3, levelName: 'Kâşif')),
    );
    when(() => repo.token()).thenAnswer((_) async => const Success(CardToken(token: 'tok-1', pin: '8315')));
    sl.registerSingleton<CardRepository>(repo);
  });

  tearDown(() => sl.reset());

  testWidgets('üye: kart, geri sayım ve 4 haneli kod', (tester) async {
    await pumpTestApp(tester, session: await testSession(member: true), routes: routes, initial: Routes.card);
    expect(find.text('Ayşe Su'), findsOneWidget);
    expect(find.text('Sv 3 · Kâşif'), findsOneWidget);
    expect(find.text('Kod 30 sn sonra yenilenir'), findsOneWidget);
    expect(find.bySemanticsLabel('Dört haneli kod 8 3 1 5'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('çevrimdışı: son kod gösterilir', (tester) async {
    when(() => repo.token()).thenAnswer((_) async => const Failure(NetworkException()));
    when(() => repo.lastPin()).thenAnswer((_) async => '7719');
    await pumpTestApp(tester, session: await testSession(member: true), routes: routes, initial: Routes.card);
    expect(find.bySemanticsLabel('Dört haneli kod 7 7 1 9'), findsOneWidget);
    expect(find.text('Çevrimdışı · son geçerli kodun'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('misafir: yumuşak duvar, veri istenmez', (tester) async {
    await pumpTestApp(tester, session: await testSession(member: false), routes: routes, initial: Routes.card);
    expect(find.text('Dijital kartın seni bekliyor'), findsOneWidget);
    expect(find.text('Kartımı oluştur'), findsOneWidget);
    verifyNever(() => repo.card());
    await disposeApp(tester);
  });
}
