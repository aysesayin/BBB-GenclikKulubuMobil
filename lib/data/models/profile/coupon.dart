import 'package:freezed_annotation/freezed_annotation.dart';

part 'coupon.freezed.dart';
part 'coupon.g.dart';

enum CouponKind {
  @JsonValue('amount')
  amount,
  @JsonValue('percent')
  percent,
}

/// `GET /coupons` — kupon bakiyesi + kupon listesi.
@freezed
abstract class CouponWallet with _$CouponWallet {
  const factory CouponWallet({@Default(0) num balance, @Default(<Coupon>[]) List<Coupon> items}) = _CouponWallet;

  factory CouponWallet.fromJson(Map<String, dynamic> json) => _$CouponWalletFromJson(json);
}

@freezed
abstract class Coupon with _$Coupon {
  const factory Coupon({
    required String id,
    required String title,
    @JsonKey(unknownEnumValue: CouponKind.amount) @Default(CouponKind.amount) CouponKind kind,
    @Default(0) num value,

    /// Kaynak açıklaması (API içeriği): "Gürsu Havuzu iptali".
    @Default('') String source,
    String? code,
    DateTime? expiresAt,
    @Default(false) bool used,
    DateTime? usedAt,
  }) = _Coupon;

  factory Coupon.fromJson(Map<String, dynamic> json) => _$CouponFromJson(json);
}

/// `GET /coupons/movements` öğesi. [value] işaretlidir (+ tanımlandı, − kullanıldı).
@freezed
abstract class CouponMovement with _$CouponMovement {
  const factory CouponMovement({
    required String id,
    required String title,
    required DateTime date,
    @JsonKey(unknownEnumValue: CouponKind.amount) @Default(CouponKind.amount) CouponKind kind,
    @Default(0) num value,
  }) = _CouponMovement;

  factory CouponMovement.fromJson(Map<String, dynamic> json) => _$CouponMovementFromJson(json);
}
