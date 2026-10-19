import 'package:freezed_annotation/freezed_annotation.dart';

part 'opportunity.freezed.dart';
part 'opportunity.g.dart';

/// Kod teslim tipi (C3): indirim kodu · QR + 4 hane · PNR → QR.
enum ClaimType { code, qr, pnr }

/// Liste filtresi; [query] sunucuya giden `filter=` değeri.
enum OpportunityFilter {
  nearby('nearby'),
  newest('new'),
  ending('ending'),
  favorites('favs');

  const OpportunityFilter(this.query);
  final String query;
}

/// `GET /opportunities` liste öğesi.
@freezed
abstract class Opportunity with _$Opportunity {
  const Opportunity._();

  const factory Opportunity({
    required String id,
    required String title,
    required String brand,
    @Default('') String logoText,
    String? logoUrl,
    String? imageUrl,
    @Default('') String categoryId,
    @Default('') String discountLabel,
    @JsonKey(unknownEnumValue: ClaimType.code) @Default(ClaimType.code) ClaimType claimType,

    /// "2,4 km", "Tüm şehir", "Online" — sunucu metni.
    @Default('') String locationLabel,
    int? distanceMeters,
    required DateTime endsAt,
    @Default(0) int stockRemaining,
    @Default(0) int stockTotal,
    @Default(false) bool isFavorite,
    @Default(false) bool isNew,

    /// Görsel alanının pastel tonu: 1–6 → `palette.tile1..tile6`.
    @Default(1) int tone,
  }) = _Opportunity;

  factory Opportunity.fromJson(Map<String, dynamic> json) => _$OpportunityFromJson(json);

  double get stockRatio => stockTotal <= 0 ? 0 : (stockRemaining / stockTotal).clamp(0, 1).toDouble();

  /// Stok %20'nin altında → sıcak pembe çubuk.
  bool get isLowStock => stockRatio < .2;

  /// Takvim günü farkı (bugün bitiyorsa 0).
  int daysLeft(DateTime now) {
    final e = endsAt.toLocal();
    final d = DateTime(e.year, e.month, e.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    return d < 0 ? 0 : d;
  }

  // TODO(varsayım): "Bitmek üzere" = son 5 gün (tasarımdaki örneklerde 3 ve 5 gün kalanlar işaretli).
  bool isEndingSoon(DateTime now) => daysLeft(now) <= 5;
}

/// Kategori karosu (`GET /opportunities/categories`). [icon] → `OppIcons.byKey`.
@freezed
abstract class OpportunityCategory with _$OpportunityCategory {
  const factory OpportunityCategory({required String id, required String label, @Default('grid') String icon, @Default(6) int tone}) =
      _OpportunityCategory;

  factory OpportunityCategory.fromJson(Map<String, dynamic> json) => _$OpportunityCategoryFromJson(json);
}

/// Fırsat şubesi (mini harita + yol tarifi).
@freezed
abstract class OpportunityBranch with _$OpportunityBranch {
  const factory OpportunityBranch({
    required String name,
    @Default('') String distanceLabel,
    @Default('') String hours,
    double? lat,
    double? lng,
  }) = _OpportunityBranch;

  factory OpportunityBranch.fromJson(Map<String, dynamic> json) => _$OpportunityBranchFromJson(json);
}

/// Detay uç noktası liste alanlarını da düz biçimde içerir → [summary].
Object? _self(Map<dynamic, dynamic> json, String _) => json;

/// `GET /opportunities/{id}`.
@Freezed(toJson: false)
abstract class OpportunityDetail with _$OpportunityDetail {
  const OpportunityDetail._();

  const factory OpportunityDetail({
    @JsonKey(readValue: _self) required Opportunity summary,
    @Default('') String categoryName,
    String? bannerUrl,
    int? minAge,
    int? maxAge,
    @Default(0) int buanReward,
    @Default(<String>[]) List<String> steps,
    @Default(<String>[]) List<String> conditions,
    @Default(<String>[]) List<String> validity,
    OpportunityBranch? branch,

    /// Yaş sınırı vb. kurallar sunucuda değerlendirilir (panelden yönetilir).
    @Default(true) bool eligible,
    String? ineligibleReason,

    /// Kullanıcı bu fırsatı zaten yakaladıysa (aktif kod var).
    @Default(false) bool isClaimed,
  }) = _OpportunityDetail;

  factory OpportunityDetail.fromJson(Map<String, dynamic> json) => _$OpportunityDetailFromJson(json);

  String get id => summary.id;
  bool get soldOut => summary.stockTotal > 0 && summary.stockRemaining <= 0;
}
