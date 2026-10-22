import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_stats.freezed.dart';
part 'profile_stats.g.dart';

/// `GET /users/me/stats` — profil sayaçları, vitrindeki rozetler ve menü rozetleri.
// TODO(varsayım): Tasarım notu ayrı `GET /badges/me?featured` diyor; tek çağrı için vitrin rozetleri
// stats yanıtına gömüldü. Backend ayrı uç verirse ProfileService'te ayrıştırılır.
@freezed
abstract class ProfileStats with _$ProfileStats {
  const factory ProfileStats({
    @Default(0) int totalBuanEarned,
    @Default(0) int eventsAttended,
    @Default(0) int opportunitiesUsed,

    /// İlçe liderlik sıralaması (0 → bilinmiyor, karo gizlenir).
    @Default(0) int districtRank,
    @Default(0) int badgeCount,
    @Default(<FeaturedBadge>[]) List<FeaturedBadge> featuredBadges,

    /// "Başvurularım" satırındaki "1 ödeme bekliyor" rozeti.
    @Default(0) int pendingPayments,

    /// "Anketler" satırındaki "2 açık" rozeti.
    @Default(0) int openSurveys,
  }) = _ProfileStats;

  factory ProfileStats.fromJson(Map<String, dynamic> json) => _$ProfileStatsFromJson(json);
}

/// Vitrindeki rozet: [icon] bilinen bir ikon anahtarı, [tone] 1–6 pastel karo.
@freezed
abstract class FeaturedBadge with _$FeaturedBadge {
  const factory FeaturedBadge({required String id, required String name, @Default('star') String icon, @Default(1) int tone}) =
      _FeaturedBadge;

  factory FeaturedBadge.fromJson(Map<String, dynamic> json) => _$FeaturedBadgeFromJson(json);
}
