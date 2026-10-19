import 'package:freezed_annotation/freezed_annotation.dart';

part 'search_result.freezed.dart';
part 'search_result.g.dart';

/// Arama sonucu türü. Fırsat + BUAN ödülü aynı "Fırsatlar" grubunda gösterilir.
enum SearchResultType { opportunity, reward, event, place }

/// `GET /search?q=&types=` sonucu tek satır.
@freezed
abstract class SearchResult with _$SearchResult {
  const factory SearchResult({
    required String id,
    @JsonKey(unknownEnumValue: SearchResultType.place) required SearchResultType type,
    required String title,
    @Default('') String subtitle,
  }) = _SearchResult;

  factory SearchResult.fromJson(Map<String, dynamic> json) => _$SearchResultFromJson(json);
}
