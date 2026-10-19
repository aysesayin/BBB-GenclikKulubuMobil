import 'package:freezed_annotation/freezed_annotation.dart';

part 'digital_card.freezed.dart';
part 'digital_card.g.dart';

/// `GET /users/me/card` — dijital gençlik kartı.
@freezed
abstract class DigitalCard with _$DigitalCard {
  const DigitalCard._();

  const factory DigitalCard({
    required String firstName,
    @Default('') String lastName,

    /// "0016 4821"
    required String memberNo,
    @Default(1) int level,
    @Default('') String levelName,

    /// KVKK: yalnız maskeli TCKN gelir ("1234*****90").
    String? maskedTckn,
  }) = _DigitalCard;

  factory DigitalCard.fromJson(Map<String, dynamic> json) => _$DigitalCardFromJson(json);

  String get fullName => lastName.isEmpty ? firstName : '$firstName $lastName';
}

/// `GET /users/me/card/token` — 30 sn'de bir dönen check-in jetonu + 4 haneli kod.
@freezed
abstract class CardToken with _$CardToken {
  const factory CardToken({required String token, required String pin, @Default(30) int ttlSeconds}) = _CardToken;

  factory CardToken.fromJson(Map<String, dynamic> json) => _$CardTokenFromJson(json);
}

/// `POST /buan/qr-checkin` yanıtı.
@freezed
abstract class QrCheckInResult with _$QrCheckInResult {
  const factory QrCheckInResult({
    String? placeId,
    required String placeName,

    /// Sunucunun hazırladığı başlık (Türkçe ek uyumu için) — yoksa l10n kalıbı.
    String? headline,
    @Default(0) int buan,
    String? badgeHint,
  }) = _QrCheckInResult;

  factory QrCheckInResult.fromJson(Map<String, dynamic> json) => _$QrCheckInResultFromJson(json);
}

/// Check-in sırasında gönderilen konum (izin varsa).
class GeoPoint {
  const GeoPoint(this.lat, this.lng);
  final double lat, lng;

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}
