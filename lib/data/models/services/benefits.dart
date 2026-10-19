import 'package:freezed_annotation/freezed_annotation.dart';

part 'benefits.freezed.dart';
part 'benefits.g.dart';

// Not: `/users/me/discounts` ve `/coupons` profil özelliğiyle ortak uçlardır; alan adları
// lib/data/models/profile/{discount,coupon}.dart ile aynı tutulur. Sepet yalnız gereken alanları okur.

enum DiscountStatus { approved, expiring, pending, rejected, expired, unknown }

/// `GET /users/me/discounts` öğesi — sepetteki "Uygun indirimler" satırı.
@freezed
abstract class EligibleDiscount with _$EligibleDiscount {
  const EligibleDiscount._();

  const factory EligibleDiscount({
    required String id,
    @Default('') String typeId,
    @JsonKey(name: 'typeName') @Default('') String name,

    /// Yüzde (50 → %50).
    @Default(0) int rate,
    @JsonKey(unknownEnumValue: DiscountStatus.unknown) @Default(DiscountStatus.pending) DiscountStatus status,
    DateTime? validUntil,
  }) = _EligibleDiscount;

  factory EligibleDiscount.fromJson(Map<String, dynamic> json) => _$EligibleDiscountFromJson(json);

  bool get usable => (status == DiscountStatus.approved || status == DiscountStatus.expiring) && rate > 0;
}

/// `GET /coupons` öğesi (yalnız sepetin ihtiyaç duyduğu alanlar).
@freezed
abstract class Coupon with _$Coupon {
  const factory Coupon({
    required String id,
    @Default('') String title,

    /// `amount` | `percent`
    @Default('amount') String kind,
    @Default(0) num value,
    @Default(false) bool used,
  }) = _Coupon;

  factory Coupon.fromJson(Map<String, dynamic> json) => _$CouponFromJson(json);
}

/// `GET /coupons` — tutar kuponlarının bakiyesi (rapor telafisi vb.).
@freezed
abstract class CouponWallet with _$CouponWallet {
  const CouponWallet._();

  const factory CouponWallet({
    @Default(0) num balance,
    @Default(<Coupon>[]) List<Coupon> items,
  }) = _CouponWallet;

  factory CouponWallet.fromJson(Map<String, dynamic> json) => _$CouponWalletFromJson(json);

  /// Bakiyenin kaynağını anlatan ilk kullanılmamış tutar kuponu ("Telafi kuponu").
  Coupon? get primaryAmountCoupon => items.where((c) => !c.used && c.kind == 'amount').firstOrNull;
}
