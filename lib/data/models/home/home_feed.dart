import 'package:freezed_annotation/freezed_annotation.dart';

import 'home_items.dart';

part 'home_feed.freezed.dart';
part 'home_feed.g.dart';

/// `GET /home` — Keşfet ekranının tüm blokları tek çağrıda.
/// [blocks] panelin belirlediği sırayı verir (bilinmeyen anahtarlar yok sayılır).
@freezed
abstract class HomeFeed with _$HomeFeed {
  const factory HomeFeed({
    /// Misafirde null.
    HomeUser? user,

    /// Misafirde null.
    HomeWallet? wallet,
    @Default(0) int unreadCount,
    @Default(<String>[]) List<String> blocks,
    @Default(<HomeStory>[]) List<HomeStory> stories,
    @Default(<HomeTask>[]) List<HomeTask> tasks,
    @Default(<HomeBanner>[]) List<HomeBanner> banners,
    @Default(<HomeShortcut>[]) List<HomeShortcut> shortcuts,
    @Default(<HomeDeal>[]) List<HomeDeal> deals,
    @Default(<HomeEvent>[]) List<HomeEvent> events,
    HomeNearby? nearby,
    HomeLeague? league,
  }) = _HomeFeed;

  factory HomeFeed.fromJson(Map<String, dynamic> json) => _$HomeFeedFromJson(json);
}

@freezed
abstract class HomeUser with _$HomeUser {
  const factory HomeUser({required String firstName, @Default('') String lastName}) = _HomeUser;

  factory HomeUser.fromJson(Map<String, dynamic> json) => _$HomeUserFromJson(json);
}

@freezed
abstract class HomeWallet with _$HomeWallet {
  const factory HomeWallet({@Default(0) int balance, @Default(0) int streak}) = _HomeWallet;

  factory HomeWallet.fromJson(Map<String, dynamic> json) => _$HomeWalletFromJson(json);
}

/// "Yakınındaki Yerler" mini harita özeti.
@freezed
abstract class HomeNearby with _$HomeNearby {
  const factory HomeNearby({
    required String placeId,
    required String label,
    @Default(0) int distanceMeters,

    /// Haritadaki "+6" kümesi.
    @Default(0) int moreCount,
  }) = _HomeNearby;

  factory HomeNearby.fromJson(Map<String, dynamic> json) => _$HomeNearbyFromJson(json);
}

/// Haftalık lig kartı.
@freezed
abstract class HomeLeague with _$HomeLeague {
  const factory HomeLeague({
    required String tier,
    required int rank,

    /// Sezon bitimine kalan saniye (sunucu saatine göre).
    @Default(0) int secondsLeft,

    /// Yükselme bölgesine ilerleme 0–1.
    @Default(0) double progress,
    @Default(0) int pointsToPromotion,

    /// Yükselmeye yakın (sunucu hesaplar; ör. kalan ≤ 1000) → kart "Bugünün Görevleri"nin hemen altına taşınır.
    // TODO(varsayım): Eşik (1000 BUAN) sunucuda; istemci yalnız bayrağı okur.
    @Default(false) bool nearPromotion,
  }) = _HomeLeague;

  factory HomeLeague.fromJson(Map<String, dynamic> json) => _$HomeLeagueFromJson(json);
}
