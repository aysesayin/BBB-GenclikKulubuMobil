import 'package:freezed_annotation/freezed_annotation.dart';

part 'buan_league.freezed.dart';
part 'buan_league.g.dart';

enum BuanLeagueScope { global, district, friends }

@freezed
abstract class BuanLeagueEntry with _$BuanLeagueEntry {
  const factory BuanLeagueEntry({
    required int rank,
    required String userId,

    /// Sunucu "Ad S." biçiminde gönderir; istemci yine de kısaltır (KVKK).
    required String name,
    @Default('') String initials,
    required int points,
    @Default(false) bool isMe,
    @Default(false) bool isFriend,
    String? districtId,
  }) = _BuanLeagueEntry;

  factory BuanLeagueEntry.fromJson(Map<String, dynamic> json) => _$BuanLeagueEntryFromJson(json);
}

@freezed
abstract class BuanDistrict with _$BuanDistrict {
  const factory BuanDistrict({required String id, required String name}) = _BuanDistrict;

  factory BuanDistrict.fromJson(Map<String, dynamic> json) => _$BuanDistrictFromJson(json);
}

/// `GET /buan/leaderboard?scope=&district=` — haftalık lig.
@freezed
abstract class BuanLeague with _$BuanLeague {
  const factory BuanLeague({
    /// Yanıtın gerçekten ait olduğu kapsam (mock tüm kapsamlar için aynı veriyi döner).
    @JsonKey(unknownEnumValue: BuanLeagueScope.global) @Default(BuanLeagueScope.global) BuanLeagueScope scope,
    required String tierName,
    String? promoteTo,
    String? relegateTo,
    @Default(0) int promoteCount,
    @Default(0) int relegateCount,
    required DateTime seasonEndsAt,
    @Default(<BuanLeagueEntry>[]) List<BuanLeagueEntry> entries,
    BuanLeagueEntry? me,
    int? pointsToPromotion,
    String? districtId,
    @Default(<BuanDistrict>[]) List<BuanDistrict> districts,
  }) = _BuanLeague;

  factory BuanLeague.fromJson(Map<String, dynamic> json) => _$BuanLeagueFromJson(json);
}
