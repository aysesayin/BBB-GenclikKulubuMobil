import '../../core/network/api_result.dart';
import '../models/profile/coupon.dart';
import '../services/coupon_service.dart';

abstract interface class CouponRepository {
  Future<ApiResult<CouponWallet>> wallet();
  Future<ApiResult<List<CouponMovement>>> movements();
  Future<ApiResult<Coupon>> redeem(String code);
}

class CouponRepositoryImpl implements CouponRepository {
  CouponRepositoryImpl(this._service);

  final CouponService _service;

  @override
  Future<ApiResult<CouponWallet>> wallet() => _service.wallet();

  @override
  Future<ApiResult<List<CouponMovement>>> movements() => _service.movements();

  @override
  Future<ApiResult<Coupon>> redeem(String code) => _service.redeem(code);
}
