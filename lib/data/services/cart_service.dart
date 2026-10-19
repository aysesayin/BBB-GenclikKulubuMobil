import '../../core/network/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../models/services/benefits.dart';
import '../models/services/cart.dart';

/// Sepet, kontenjan rezervi, indirim/kupon ve ödeme başlatma.
class CartService {
  CartService(this._client);

  final DioClient _client;

  Future<ApiResult<Cart>> cart() => _client.get(ApiEndpoints.cart, parse: (d) => Cart.fromJson(Json.map(d)));

  Future<ApiResult<CartHold>> hold({
    required String itemId,
    required String sessionId,
    required String participantId,
    required bool swimConfirmed,
  }) =>
      _client.post(
        ApiEndpoints.cartHold,
        body: {'itemId': itemId, 'sessionId': sessionId, 'participantId': participantId, 'swimConfirmed': swimConfirmed},
        parse: (d) => CartHold.fromJson(Json.map(d)),
      );

  Future<ApiResult<void>> removeItem(String id) => _client.delete(ApiEndpoints.cartItem(id), parse: Json.ignore);

  Future<ApiResult<void>> clear() => _client.delete(ApiEndpoints.cart, parse: Json.ignore);

  Future<ApiResult<List<EligibleDiscount>>> discounts() =>
      _client.get(ApiEndpoints.discounts, parse: (d) => Json.list(d, EligibleDiscount.fromJson));

  Future<ApiResult<CouponWallet>> coupons() =>
      _client.get(ApiEndpoints.coupons, parse: (d) => CouponWallet.fromJson(Json.map(d)));

  Future<ApiResult<CheckoutResult>> checkout({
    required String? discountId,
    required bool useCoupon,
    required String idempotencyKey,
  }) =>
      _client.post(
        ApiEndpoints.checkout,
        body: {'discountId': discountId, 'useCoupon': useCoupon},
        headers: {'Idempotency-Key': idempotencyKey},
        parse: (d) => CheckoutResult.fromJson(Json.map(d)),
      );
}
