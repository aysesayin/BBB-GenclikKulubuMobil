import 'package:freezed_annotation/freezed_annotation.dart';

import 'opportunity.dart';

part 'claim.freezed.dart';
part 'claim.g.dart';

/// `POST /opportunities/{id}/claim` → `{type, code, qr, pin, expiresAt}`.
///
/// - [ClaimType.code]: [code] kopyalanır (online alışveriş).
/// - [ClaimType.qr]: [qr] kasada okutulur, [pin] 4 haneli kişisel kod.
/// - [ClaimType.pnr]: PNR ([pin]) QR'a dönüştürülmüştür ([qr] yoksa PNR'nin kendisi QR'lanır).
@freezed
abstract class ClaimResult with _$ClaimResult {
  const ClaimResult._();

  const factory ClaimResult({
    required String opportunityId,
    @JsonKey(unknownEnumValue: ClaimType.code) @Default(ClaimType.code) ClaimType type,
    String? code,
    String? qr,
    String? pin,
    required DateTime expiresAt,
    @Default(0) int buanReward,
    @Default('') String brand,
    @Default('') String logoText,
    @Default('') String title,
  }) = _ClaimResult;

  factory ClaimResult.fromJson(Map<String, dynamic> json) => _$ClaimResultFromJson(json);

  /// QR'a basılacak veri.
  String get qrData => qr ?? pin ?? code ?? opportunityId;

  /// Kutucuklara bölünmüş kişisel kod: 4 hane → tek tek, PNR → ikişerli.
  List<String> get pinParts {
    final p = (pin ?? '').replaceAll(RegExp(r'[\s-]'), '');
    if (p.isEmpty) return const [];
    final size = type == ClaimType.pnr ? 2 : 1;
    return [for (var i = 0; i < p.length; i += size) p.substring(i, (i + size).clamp(0, p.length))];
  }
}

enum WalletStatus { active, used, expired }

/// `GET /opportunities/mine` — kullanıcının fırsat cüzdanı öğesi.
@freezed
abstract class WalletItem with _$WalletItem {
  const factory WalletItem({
    required String id,
    required String opportunityId,
    @Default('') String brand,
    @Default('') String logoText,
    @Default('') String discountLabel,
    @Default('') String title,
    @Default(1) int tone,
    @JsonKey(unknownEnumValue: WalletStatus.expired) @Default(WalletStatus.active) WalletStatus status,
    DateTime? expiresAt,
    DateTime? usedAt,
    @Default(0) int buanEarned,

    /// Aktif öğelerde kodun kendisi (çevrimdışı da gösterilebilsin diye).
    ClaimResult? claim,
  }) = _WalletItem;

  factory WalletItem.fromJson(Map<String, dynamic> json) => _$WalletItemFromJson(json);
}

/// `POST /opportunities/{id}/rating` → "Fırsat Kullan Kazan" ödülü.
/// [label] sunucunun toast başlığı; yoksa l10n `oppRatingToast`.
@freezed
abstract class RatingResult with _$RatingResult {
  const factory RatingResult({@Default('') String opportunityId, @Default(0) int buanReward, String? label}) = _RatingResult;

  factory RatingResult.fromJson(Map<String, dynamic> json) => _$RatingResultFromJson(json);
}
