import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/data/models/services/cart.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/cart_repository.dart';
import 'package:bbb_genclik_kulubu_app/data/services/cart_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'svc_fixtures.dart';

class _MockCartService extends Mock implements CartService {}

void main() {
  group('HoldClock', () {
    test('cihaz saati sunucudan farklı olsa da kalan süre korunur', () {
      final clock = FakeClock(DateTime.utc(2026, 10, 16, 9)); // cihaz 6 saat geride
      final hold = HoldClock(now: clock.call);
      final d = hold.sync(expiresAt: DateTime.utc(2026, 10, 16, 15, 5), serverTime: DateTime.utc(2026, 10, 16, 15));
      expect(d, DateTime.utc(2026, 10, 16, 9, 5));
    });

    test('yeniden senkronda süre uzatılmaz, reset ile kurulur', () {
      final clock = FakeClock(kNow);
      final hold = HoldClock(now: clock.call);
      final server = DateTime.utc(2026, 10, 16, 15);
      hold.sync(expiresAt: server.add(const Duration(minutes: 5)), serverTime: server);
      clock.advance(const Duration(minutes: 2));
      // Mock/önbellek yine 5 dk dese de kalan 3 dk korunur.
      final again = hold.sync(expiresAt: server.add(const Duration(minutes: 5)), serverTime: server);
      expect(again, kNow.add(const Duration(minutes: 5)));
      // Sunucu daha az derse o geçerli.
      final less = hold.sync(expiresAt: server.add(const Duration(minutes: 1)), serverTime: server);
      expect(less, clock.value.add(const Duration(minutes: 1)));
      final reset = hold.sync(expiresAt: server.add(const Duration(minutes: 5)), serverTime: server, reset: true);
      expect(reset, clock.value.add(const Duration(minutes: 5)));
    });

    test('süresi geçmiş rezerv yenisiyle değiştirilir; expiresAt yoksa temizlenir', () {
      final clock = FakeClock(kNow);
      final hold = HoldClock(now: clock.call);
      hold.sync(expiresAt: kNow.add(const Duration(minutes: 1)), serverTime: kNow);
      clock.advance(const Duration(minutes: 2));
      expect(
        hold.sync(expiresAt: kNow.add(const Duration(minutes: 7)), serverTime: kNow.add(const Duration(minutes: 2))),
        clock.value.add(const Duration(minutes: 5)),
      );
      expect(hold.sync(expiresAt: null), isNull);
      expect(hold.deadline, isNull);
    });
  });

  group('CartRepositoryImpl', () {
    test('hold → cart: rezerv bitişi korunur; boş sepet bitişi temizler', () async {
      final service = _MockCartService();
      final clock = FakeClock(kNow);
      final repo = CartRepositoryImpl(service, clock: HoldClock(now: clock.call));
      final server = DateTime.utc(2026, 10, 16, 15);
      when(
        () => service.hold(itemId: 'i', sessionId: 's', participantId: 'p', swimConfirmed: true),
      ).thenAnswer((_) async => Success(CartHold(cartItemId: 'c', expiresAt: server.add(const Duration(minutes: 5)), serverTime: server)));
      when(() => service.cart()).thenAnswer(
        (_) async => Success(Cart(items: const [kCartItem], expiresAt: server.add(const Duration(minutes: 5)), serverTime: server)),
      );
      await repo.hold(itemId: 'i', sessionId: 's', participantId: 'p', swimConfirmed: true);
      clock.advance(const Duration(seconds: 30));
      final snap = (await repo.cart()).dataOrNull!;
      expect(snap.deadline, kNow.add(const Duration(minutes: 5)));

      when(() => service.cart()).thenAnswer((_) async => const Success(Cart()));
      expect((await repo.cart()).dataOrNull!.deadline, isNull);
    });
  });
}
