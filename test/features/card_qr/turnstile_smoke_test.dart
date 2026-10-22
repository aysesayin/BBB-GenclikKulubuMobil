import 'package:bbb_genclik_kulubu_app/core/di/locator.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/router/routes.dart';
import 'package:bbb_genclik_kulubu_app/data/models/card/digital_card.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/card_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/card_qr/view/turnstile_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../opportunities/test_app.dart';
import 'card_mocks.dart';

/// Turnike modu: dev QR (≥ 260 px), 48 px kod, "Kapat" ve otomatik kapanış.
void main() {
  late MockCardRepository repo;
  final routes = [
    GoRoute(path: Routes.card, builder: (_, _) => const Scaffold(body: Text('Kartım'))),
    GoRoute(path: Routes.turnstile, builder: (_, _) => const TurnstileView(autoClose: Duration(seconds: 5))),
  ];

  setUp(() {
    repo = MockCardRepository();
    when(() => repo.card()).thenAnswer((_) async => const Success(DigitalCard(firstName: 'Ayşe', memberNo: '0016 4821')));
    when(() => repo.token()).thenAnswer((_) async => const Success(CardToken(token: 'tok-1', pin: '8315')));
    sl.registerSingleton<CardRepository>(repo);
  });

  tearDown(() => sl.reset());

  testWidgets('QR, 4 haneli kod, halka ve Kapat', (tester) async {
    await pumpTestApp(tester, session: await testSession(member: true), routes: routes, initial: Routes.turnstile);
    expect(find.text('Turnike modu'), findsOneWidget);
    expect(find.bySemanticsLabel('Check-in QR kodu'), findsOneWidget);
    expect(find.bySemanticsLabel('Dört haneli kod 8 3 1 5'), findsOneWidget);
    expect(find.text('Kod 30 sn sonra yenilenir'), findsOneWidget);
    final qr = tester.getSize(find.bySemanticsLabel('Check-in QR kodu'));
    expect(qr.width, greaterThanOrEqualTo(260));
    expect(find.text('Kapat'), findsOneWidget);
    await disposeApp(tester);
  });

  testWidgets('Kapat → Kartım sekmesi', (tester) async {
    await pumpTestApp(tester, session: await testSession(member: true), routes: routes, initial: Routes.turnstile);
    expect(find.text('Turnike modu'), findsOneWidget);
    await tester.tap(find.text('Kapat'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Turnike modu'), findsNothing);
    await disposeApp(tester);
  });

  testWidgets('otomatik kapanış zamanlayıcısı', (tester) async {
    await pumpTestApp(tester, session: await testSession(member: true), routes: routes, initial: Routes.turnstile);
    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Turnike modu'), findsNothing);
    await disposeApp(tester);
  });
}
