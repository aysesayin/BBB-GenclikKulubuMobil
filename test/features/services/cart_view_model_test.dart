import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/services/benefits.dart';
import 'package:bbb_genclik_kulubu_app/data/models/services/cart.dart';
import 'package:bbb_genclik_kulubu_app/data/services/cart_payment_launcher.dart';
import 'package:bbb_genclik_kulubu_app/features/services/cart/view_model/cart_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'svc_fixtures.dart';

void main() {
  late MockCartRepository repo;
  late MockPaymentLauncher payment;
  late FakeClock clock;

  CartViewModel build() => CartViewModel(repo, payment: payment, now: clock.call);

  void stubCheckout(ApiResult<CheckoutResult> r) => when(
    () => repo.checkout(
      discountId: any(named: 'discountId'),
      useCoupon: any(named: 'useCoupon'),
      idempotencyKey: any(named: 'idempotencyKey'),
    ),
  ).thenAnswer((_) async => r);

  setUp(() {
    repo = MockCartRepository();
    payment = MockPaymentLauncher();
    clock = FakeClock(kNow);
    when(() => repo.cart()).thenAnswer((_) async => Success(cartSnapshot(kNow.add(const Duration(minutes: 5)))));
    when(() => repo.discounts()).thenAnswer((_) async => const Success([kStudent, kSibling]));
    when(() => repo.coupons()).thenAnswer((_) async => const Success(kWallet));
    when(() => repo.clear()).thenAnswer((_) async => const Success<void>(null));
  });

  group('toplamlar', () {
    test('varsayılan: ilk onaylı indirim + kupon açık → 100 − 50 − 30 = 20', () async {
      final vm = build();
      await vm.load();
      expect(vm.discountId, 'dsc-ogrenci');
      expect(vm.useCoupon, isTrue);
      expect(vm.subtotal, 100);
      expect(vm.discountAmount, 50);
      expect(vm.couponAmount, 30);
      expect(vm.total, 20);
    });

    test('onaysız indirim seçilemez; "indirim kullanma" ve kupon kapatma', () async {
      final vm = build();
      await vm.load();
      vm.selectDiscount('dsc-kardes');
      expect(vm.discountId, 'dsc-ogrenci');
      vm.selectDiscount(null);
      expect(vm.total, 70);
      vm.setUseCoupon(value: false);
      expect(vm.total, 100);
    });

    test('kupon tutarı ödenecekten büyük olamaz', () async {
      when(() => repo.coupons()).thenAnswer((_) async => const Success(CouponWallet(balance: 80)));
      final vm = build();
      await vm.load();
      expect(vm.couponAmount, 50);
      expect(vm.total, 0);
    });

    test('indirim / kupon uçları hata verirse sepet yine açılır', () async {
      when(() => repo.discounts()).thenAnswer((_) async => const Failure(NetworkException()));
      when(() => repo.coupons()).thenAnswer((_) async => const Failure(NetworkException()));
      final vm = build();
      await vm.load();
      expect(vm.state, isA<ViewSuccess<CartData>>());
      expect(vm.total, 100);
    });

    test('boş sepet → ViewEmpty', () async {
      when(() => repo.cart()).thenAnswer((_) async => Success(cartSnapshot(kNow, items: const [])));
      final vm = build();
      await vm.load();
      expect(vm.state, isA<ViewEmpty<CartData>>());
    });
  });

  group('5 dk rezerv', () {
    test('faz: active → low (≤60 sn) → expired; süre dolunca sepet boşaltılır', () async {
      final vm = build();
      await vm.load();
      expect(vm.phase, HoldPhase.active);
      expect(vm.remaining, const Duration(minutes: 5));
      clock.advance(const Duration(minutes: 4, seconds: 1));
      expect(vm.phase, HoldPhase.low);
      vm.checkExpiry();
      verifyNever(() => repo.clear());
      clock.advance(const Duration(seconds: 59));
      vm.checkExpiry();
      expect(vm.phase, HoldPhase.expired);
      expect(vm.expired, isTrue);
      expect(vm.cart?.items, isEmpty);
      expect(vm.canPay, isFalse);
      verify(() => repo.clear()).called(1);
      vm.checkExpiry();
      verifyNever(() => repo.clear());
    });

    test('arka plandan dönüşte süre geçmişse açılışta hemen boşaltılır', () async {
      clock.advance(const Duration(minutes: 6));
      final vm = build();
      await vm.load();
      expect(vm.expired, isTrue);
      verify(() => repo.clear()).called(1);
    });

    test('resync sunucudaki yeni bitişi kullanır', () async {
      final vm = build();
      await vm.load();
      when(() => repo.cart()).thenAnswer((_) async => Success(cartSnapshot(kNow.add(const Duration(minutes: 2)))));
      await vm.resync();
      expect(vm.remaining, const Duration(minutes: 2));
    });

    test('halka ilerlemesi kalan / toplam', () async {
      final vm = build();
      await vm.load();
      clock.advance(const Duration(seconds: 150));
      expect(vm.holdProgress, closeTo(.5, .001));
    });
  });

  group('ödeme', () {
    test('3D Secure URL\'si açılır; başarı → success, aynı idempotency anahtarı tekrar kullanılmaz', () async {
      stubCheckout(const Success(CheckoutResult(orderId: 'o1', paymentUrl: 'https://pos.test/3d')));
      when(() => payment.open(any())).thenAnswer((_) async => PaymentOutcome.success);
      final vm = build();
      await vm.load();
      final o = await vm.checkout();
      expect(o.kind, PaymentOutcome.success);
      verify(
        () => repo.checkout(
          discountId: 'dsc-ogrenci',
          useCoupon: true,
          idempotencyKey: any(named: 'idempotencyKey'),
        ),
      ).called(1);
      verify(() => payment.open('https://pos.test/3d')).called(1);
      expect(vm.paying, isFalse);
    });

    test('sunucu hatasında aynı anahtarla yeniden denenir', () async {
      stubCheckout(const Failure(ServerException()));
      final vm = build();
      await vm.load();
      final o1 = await vm.checkout();
      clock.advance(const Duration(seconds: 3));
      await vm.checkout();
      expect(o1.kind, PaymentOutcome.failed);
      expect(o1.error, isA<ServerException>());
      final keys = verify(
        () => repo.checkout(
          discountId: any(named: 'discountId'),
          useCoupon: any(named: 'useCoupon'),
          idempotencyKey: captureAny(named: 'idempotencyKey'),
        ),
      ).captured;
      expect(keys.toSet(), hasLength(1));
    });

    test('status=paid → ödeme sayfası açılmadan başarı', () async {
      stubCheckout(const Success(CheckoutResult(orderId: 'o1', status: CheckoutStatus.paid)));
      final vm = build();
      await vm.load();
      expect((await vm.checkout()).kind, PaymentOutcome.success);
      verifyNever(() => payment.open(any()));
    });
  });
}
