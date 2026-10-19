import 'package:freezed_annotation/freezed_annotation.dart';

part 'discount.freezed.dart';
part 'discount.g.dart';

/// `GET /discount-types` öğesi (personel, şehit/gazi yakını, engelli, öğrenci, kardeş, yoksulluk belgesi).
@freezed
abstract class DiscountType with _$DiscountType {
  const factory DiscountType({required String id, required String name, @Default('') String requiredDocument}) = _DiscountType;

  factory DiscountType.fromJson(Map<String, dynamic> json) => _$DiscountTypeFromJson(json);
}

enum DiscountStatus {
  @JsonValue('pending')
  pending,
  @JsonValue('approved')
  approved,
  @JsonValue('rejected')
  rejected,
  @JsonValue('expiring')
  expiring,
  @JsonValue('expired')
  expired,
}

/// `GET /users/me/discounts` öğesi.
@freezed
abstract class UserDiscount with _$UserDiscount {
  const UserDiscount._();

  const factory UserDiscount({
    required String id,
    required String typeId,
    @Default('') String typeName,
    @JsonKey(unknownEnumValue: DiscountStatus.pending) @Default(DiscountStatus.pending) DiscountStatus status,
    DateTime? submittedAt,
    DateTime? validUntil,
    String? rejectReason,
  }) = _UserDiscount;

  factory UserDiscount.fromJson(Map<String, dynamic> json) => _$UserDiscountFromJson(json);

  /// Gösterilecek durum: onaylı ama 15 gün içinde bitiyorsa "Süresi doluyor".
  // TODO(varsayım): Hatırlatma eşiği tasarım metnindeki 15 gün; sunucu `expiring` gönderirse o geçerli.
  DiscountStatus effectiveStatus(DateTime today) {
    final until = validUntil;
    if (status == DiscountStatus.approved && until != null) {
      final left = DateTime(until.year, until.month, until.day).difference(DateTime(today.year, today.month, today.day)).inDays;
      if (left < 0) return DiscountStatus.expired;
      if (left <= 15) return DiscountStatus.expiring;
    }
    return status;
  }
}
