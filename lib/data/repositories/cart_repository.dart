import '../../core/network/api_result.dart';
import '../models/services/benefits.dart';
import '../models/services/cart.dart';
import '../services/cart_service.dart';

typedef Clock = DateTime Function();

/// Sepet: 5 dk kontenjan rezervi, indirim/kupon, ödeme başlatma.
abstract interface class CartRepository {
  /// Sepeti getirir; rezerv bitişi cihaz saatine çevrilmiş olarak döner.
  Future<ApiResult<CartSnapshot>> cart();
  Future<ApiResult<CartHold>> hold({
    required String itemId,
    required String sessionId,
    required String participantId,
    required bool swimConfirmed,
  });
  Future<ApiResult<void>> removeItem(String id);

  /// Süre dolunca / kullanıcı boşaltınca.
  Future<ApiResult<void>> clear();
  Future<ApiResult<List<EligibleDiscount>>> discounts();
  Future<ApiResult<CouponWallet>> coupons();
  Future<ApiResult<CheckoutResult>> checkout({required String? discountId, required bool useCoupon, required String idempotencyKey});
}

/// Sunucu saatine göre rezerv bitişini cihaz saatine çevirir.
///
/// `kalan = expiresAt − serverTime` yanıt anında ölçülür, `deadline = şimdi + kalan`.
/// Böylece cihaz saati yanlış olsa da sayaç sunucuyla aynı kalır; arka plandan
/// dönüldüğünde de mutlak [deadline] üzerinden hesaplandığı için kaymaz.
/// Bir rezerv yeniden senkronlanırken süre asla uzatılmaz (yalnız [reset] ile).
class HoldClock {
  HoldClock({Clock? now}) : _now = now ?? DateTime.now;

  final Clock _now;
  DateTime? _deadline;

  DateTime? get deadline => _deadline;

  DateTime? sync({required DateTime? expiresAt, DateTime? serverTime, bool reset = false}) {
    if (expiresAt == null) return _deadline = null;
    final now = _now();
    final remaining = expiresAt.difference(serverTime ?? now);
    final local = now.add(remaining.isNegative ? Duration.zero : remaining);
    final current = _deadline;
    if (!reset && current != null && current.isAfter(now) && current.isBefore(local)) return current;
    return _deadline = local;
  }

  void clear() => _deadline = null;
}

class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl(this._service, {HoldClock? clock}) : _clock = clock ?? HoldClock();

  final CartService _service;
  final HoldClock _clock;

  @override
  Future<ApiResult<CartSnapshot>> cart() async => (await _service.cart()).map((c) {
        if (c.items.isEmpty) {
          _clock.clear();
          return CartSnapshot(cart: c, deadline: null);
        }
        return CartSnapshot(cart: c, deadline: _clock.sync(expiresAt: c.expiresAt, serverTime: c.serverTime));
      });

  @override
  Future<ApiResult<CartHold>> hold({
    required String itemId,
    required String sessionId,
    required String participantId,
    required bool swimConfirmed,
  }) async {
    final r = await _service.hold(itemId: itemId, sessionId: sessionId, participantId: participantId, swimConfirmed: swimConfirmed);
    // TODO(varsayım): Yeni kalem eklenince sunucu tüm sepetin rezervini yeniden 5 dk'ya kurar.
    if (r case Success(:final data)) _clock.sync(expiresAt: data.expiresAt, serverTime: data.serverTime, reset: true);
    return r;
  }

  @override
  Future<ApiResult<void>> removeItem(String id) => _service.removeItem(id);

  @override
  Future<ApiResult<void>> clear() {
    _clock.clear();
    return _service.clear();
  }

  @override
  Future<ApiResult<List<EligibleDiscount>>> discounts() => _service.discounts();

  @override
  Future<ApiResult<CouponWallet>> coupons() => _service.coupons();

  @override
  Future<ApiResult<CheckoutResult>> checkout({required String? discountId, required bool useCoupon, required String idempotencyKey}) async {
    final r = await _service.checkout(discountId: discountId, useCoupon: useCoupon, idempotencyKey: idempotencyKey);
    if (r is Success<CheckoutResult>) _clock.clear();
    return r;
  }
}
