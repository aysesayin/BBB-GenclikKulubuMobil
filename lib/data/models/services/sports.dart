import 'package:freezed_annotation/freezed_annotation.dart';

part 'sports.freezed.dart';
part 'sports.g.dart';

@freezed
abstract class SportTerm with _$SportTerm {
  const factory SportTerm({required String id, required String label}) = _SportTerm;

  factory SportTerm.fromJson(Map<String, dynamic> json) => _$SportTermFromJson(json);
}

@freezed
abstract class AgeGroup with _$AgeGroup {
  const factory AgeGroup({required String id, required String label}) = _AgeGroup;

  factory AgeGroup.fromJson(Map<String, dynamic> json) => _$AgeGroupFromJson(json);
}

/// Branşın belirli dönem + yaş grubundaki grubu; [itemId] seans ekranına gider.
@freezed
abstract class BranchOffer with _$BranchOffer {
  const factory BranchOffer({
    required String termId,
    required String ageGroupId,
    required String itemId,
    @Default(0) int left,
  }) = _BranchOffer;

  factory BranchOffer.fromJson(Map<String, dynamic> json) => _$BranchOfferFromJson(json);
}

@freezed
abstract class SportBranch with _$SportBranch {
  const factory SportBranch({
    required String id,
    required String name,
    @Default('ball') String icon,
    @Default(3) int tile,
    @Default(<BranchOffer>[]) List<BranchOffer> offers,
  }) = _SportBranch;

  factory SportBranch.fromJson(Map<String, dynamic> json) => _$SportBranchFromJson(json);
}

/// `GET /services/sports-branches` — dönemler, yaş grupları ve branşlar tek yanıtta.
@freezed
abstract class SportsCatalog with _$SportsCatalog {
  const factory SportsCatalog({
    @Default(<SportTerm>[]) List<SportTerm> terms,
    @Default(<AgeGroup>[]) List<AgeGroup> ageGroups,
    @Default(<SportBranch>[]) List<SportBranch> branches,
  }) = _SportsCatalog;

  factory SportsCatalog.fromJson(Map<String, dynamic> json) => _$SportsCatalogFromJson(json);
}

/// `GET /services/tennis-products` — özel ders, kortlar, kurs, akademi, pickleball, kort kirası.
@freezed
abstract class TennisProduct with _$TennisProduct {
  const factory TennisProduct({
    required String id,
    required String itemId,
    required String name,
    @Default('') String subtitle,
    @Default(5) int tile,

    /// Boş → tüm yaş grupları.
    @Default(<String>[]) List<String> ageGroupIds,
  }) = _TennisProduct;

  factory TennisProduct.fromJson(Map<String, dynamic> json) => _$TennisProductFromJson(json);
}
