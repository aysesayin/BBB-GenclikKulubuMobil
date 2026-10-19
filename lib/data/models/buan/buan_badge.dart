import 'package:freezed_annotation/freezed_annotation.dart';

part 'buan_badge.freezed.dart';
part 'buan_badge.g.dart';

/// `GET /buan/badges` — kazanılan / kilitli rozetler.
@freezed
abstract class BuanBadge with _$BuanBadge {
  const factory BuanBadge({
    required String id,
    required String title,

    /// Kazanıldıysa açıklama ("İlk görevini tamamladın").
    @Default('') String description,

    /// Kilitliyse koşul ("Uludağ etkinliğine katıl", "7 / 10 merkez").
    @Default('') String condition,
    @Default(false) bool earned,
    DateTime? earnedAt,
    @Default('star') String icon,
    @Default(1) int tile,
  }) = _BuanBadge;

  factory BuanBadge.fromJson(Map<String, dynamic> json) => _$BuanBadgeFromJson(json);
}
