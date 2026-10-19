import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/router/routes.dart';
import 'package:bbb_genclik_kulubu_app/core/theme/app_theme.dart';
import 'package:bbb_genclik_kulubu_app/data/models/services/cart.dart';
import 'package:bbb_genclik_kulubu_app/data/services/cart_payment_launcher.dart';
import 'package:bbb_genclik_kulubu_app/features/services/cart/view/cart_view.dart';
import 'package:bbb_genclik_kulubu_app/features/services/cart/view_model/cart_view_model.dart';
import 'package:bbb_genclik_kulubu_app/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import 'svc_fixtures.dart';

void main() {
  late MockCartRepository repo;
  late MockPaymentLauncher payment;
  late FakeClock clock;

  setUpAll(() => initializeDateFormatting('tr'));

  setUp(() {
    repo = MockCartRepository();
    payment = MockPaymentLauncher();
    clock = FakeClock(kNow);
    when(() => repo.cart()).thenAnswer((_) async => Success(cartSnapshot(kNow.add(const Duration(minutes: 5)))));
    when(() => repo.discounts()).thenAnswer((_) async => const Success([kStudent, kSibling]));
    when(() => repo.coupons()).thenAnswer((_) async => const Success(kWallet));
    when(() => repo.clear()).thenAnswer((_) async => const Success<void>(null));
  });

  Future<void> pumpCart(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: Routes.cart,
      routes: [
        GoRoute(
          path: Routes.cart,
          builder: (_, _) => CartView(
            createViewModel: () => CartViewModel(repo, payment: payment, now: clock.call),
          ),
        ),
        GoRoute(
          path: Routes.applications,
          builder: (_, _) => const Scaffold(body: Text('basvurular-ekrani')),
        ),
        GoRoute(
          path: Routes.pools,
          builder: (_, _) => const Scaffold(body: Text('havuzlar-ekrani')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: AppTheme.light,
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
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  /// Sahte saati ve zamanlayıcıları birlikte ilerletir.
  Future<void> tick(WidgetTester tester, Duration d) async {
    clock.advance(d);
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('sepet: sayaç, indirim/kupon toplamları ve süre dolunca boşaltma', (tester) async {
    await pumpCart(tester);

    expect(find.text('Kontenjanın ayrıldı'), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);
    expect(find.text('Bayan Günlük Giriş'), findsOneWidget);
    expect(find.text('Öğrenci indirimi'), findsOneWidget);
    expect(find.text('Ödemeye geç · 20,00 ₺'), findsOneWidget);

    await tester.tap(find.text('İndirim kullanma'));
    await tester.pump();
    expect(find.text('Ödemeye geç · 70,00 ₺'), findsOneWidget);

    await tester.ensureVisible(find.byType(Switch));
    await tester.pump();
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(find.text('Ödemeye geç · 100,00 ₺'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, 600));
    await tester.pump();

    await tick(tester, const Duration(minutes: 4, seconds: 10));
    expect(find.text('Acele et!'), findsOneWidget);
    expect(find.text('00:50'), findsOneWidget);

    await tick(tester, const Duration(seconds: 60));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Süre doldu'), findsOneWidget);
    expect(find.text('Seansı yeniden seç'), findsOneWidget);
    expect(find.text('Bayan Günlük Giriş'), findsNothing);
    verify(() => repo.clear()).called(1);

    await tester.tap(find.text('Seansı yeniden seç'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('havuzlar-ekrani'), findsOneWidget);
  });

  testWidgets('ödeme başarılı → Başvurularım\'a gider', (tester) async {
    when(
      () => repo.checkout(
        discountId: any(named: 'discountId'),
        useCoupon: any(named: 'useCoupon'),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer((_) async => const Success(CheckoutResult(orderId: 'o1', paymentUrl: 'https://pos.test/3d')));
    when(() => payment.open(any())).thenAnswer((_) async => PaymentOutcome.success);
    await pumpCart(tester);

    await tester.tap(find.text('Ödemeye geç · 20,00 ₺'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('basvurular-ekrani'), findsOneWidget);
    expect(find.text('Ödemen alındı, başvurun onaylandı.'), findsOneWidget);
    verify(
      () => repo.checkout(
        discountId: 'dsc-ogrenci',
        useCoupon: true,
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).called(1);
  });

  testWidgets('boş sepet → boş durum', (tester) async {
    when(() => repo.cart()).thenAnswer((_) async => Success(cartSnapshot(kNow, items: const [])));
    await pumpCart(tester);
    expect(find.text('Sepetin boş'), findsOneWidget);
  });
}
