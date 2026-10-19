import 'package:freezed_annotation/freezed_annotation.dart';

part 'buan_reward.freezed.dart';
part 'buan_reward.g.dart';

enum BuanLimitPeriod { total, day, week, month }

@freezed
abstract class BuanRewardCategory with _$BuanRewardCategory {
  const factory BuanRewardCategory({required String id, required String label}) = _BuanRewardCategory;

  factory BuanRewardCategory.fromJson(Map<String, dynamic> json) => _$BuanRewardCategoryFromJson(json);
}

/// Pazar ödülü. Fiyat, stok, kişi başı limit ve "ilk N kişi" panelden yönetilir.
@freezed
abstract class BuanReward with _$BuanReward {
  const BuanReward._();

  const factory BuanReward({
    required String id,
    required String title,
    @Default('') String description,
    required String categoryId,
    @Default('') String categoryLabel,
    required int price,

    /// Kalan stok (null → sınırsız / gösterilmez).
    int? stock,
    int? perPersonLimit,
    @JsonKey(unknownEnumValue: BuanLimitPeriod.total) @Default(BuanLimitPeriod.total) BuanLimitPeriod perPersonPeriod,

    /// "İlk 20 kişi" kampanyası ve kalan yer.
    int? firstN,
    int? firstNLeft,

    /// Kart üstü etiket ("Popüler", "Son 4").
    String? tag,
    @Default(false) bool featured,

    /// Hesaplanamayan özel limit metni ("Ayda 5 kişi").
    String? limitNote,
    @Default(1) int tile,

    /// İkon anahtarı (bkz. BuanIcons.reward).
    @Default('gift') String icon,
    @Default(<String>[]) List<String> rules,

    /// Takas sonrası gösterilecek kullanım talimatı.
    String? redeemInfo,
  }) = _BuanReward;

  factory BuanReward.fromJson(Map<String, dynamic> json) => _$BuanRewardFromJson(json);

  /// Kalan adet: ilk-N kampanyasında kalan yer, yoksa stok.
  int? get remaining => firstN != null ? firstNLeft : stock;
  bool get soldOut => remaining != null && remaining! <= 0;
}

/// `GET /buan/rewards` — kategoriler + ödüller.
@freezed
abstract class BuanMarket with _$BuanMarket {
  const factory BuanMarket({
    @Default(<BuanRewardCategory>[]) List<BuanRewardCategory> categories,
    @Default(<BuanReward>[]) List<BuanReward> items,
  }) = _BuanMarket;

  factory BuanMarket.fromJson(Map<String, dynamic> json) => _$BuanMarketFromJson(json);
}

/// `POST /buan/rewards/{id}/redeem` yanıtı.
@freezed
abstract class BuanRedeemResult with _$BuanRedeemResult {
  const factory BuanRedeemResult({
    required String code,
    String? info,

    /// Sunucunun hesapladığı yeni bakiye (yoksa istemci fiyattan hesaplar).
    int? balance,
    DateTime? expiresAt,
  }) = _BuanRedeemResult;

  factory BuanRedeemResult.fromJson(Map<String, dynamic> json) => _$BuanRedeemResultFromJson(json);
}
