import '../../core/network/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../models/profile/coupon.dart';

/// Kupon uç noktaları: bakiye + kuponlar, kod ekleme, hareketler.
class CouponService {
  CouponService(this._client);

  final DioClient _client;

  Future<ApiResult<CouponWallet>> wallet() => _client.get(ApiEndpoints.coupons, parse: parseWallet, cacheKey: 'coupons.wallet');

  Future<ApiResult<List<CouponMovement>>> movements() =>
      _client.get(ApiEndpoints.couponMovements, parse: (d) => Json.list(d, CouponMovement.fromJson), cacheKey: 'coupons.movements');

  Future<ApiResult<Coupon>> redeem(String code) =>
      _client.post(ApiEndpoints.coupons, body: {'code': code}, parse: (d) => Coupon.fromJson(Json.map(d)));

  /// Yanıt `{balance, items}` ya da yalnız liste olabilir (sepet ekranı aynı ucu kullanır);
  /// liste gelirse bakiye kullanılmamış tutar kuponlarının toplamıdır.
  static CouponWallet parseWallet(Object? d) {
    if (d is List) {
      final items = Json.list(d, Coupon.fromJson);
      final balance = items.where((c) => !c.used && c.kind == CouponKind.amount).fold<num>(0, (a, c) => a + c.value);
      return CouponWallet(balance: balance, items: items);
    }
    return CouponWallet.fromJson(Json.map(d));
  }
}
