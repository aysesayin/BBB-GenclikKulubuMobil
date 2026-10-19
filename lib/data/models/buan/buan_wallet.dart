import 'package:freezed_annotation/freezed_annotation.dart';

part 'buan_wallet.freezed.dart';
part 'buan_wallet.g.dart';

/// `GET /buan/wallet` — güncel BUAN bakiyesi.
@freezed
abstract class BuanWallet with _$BuanWallet {
  const factory BuanWallet({
    required int balance,

    /// Onay bekleyen (ör. davet doğrulaması) toplam BUAN.
    @Default(0) int pending,
  }) = _BuanWallet;

  factory BuanWallet.fromJson(Map<String, dynamic> json) => _$BuanWalletFromJson(json);
}

/// `GET /buan/level` — seviye ve sonraki seviyeye kalan puan. Seviye adları panelden.
@freezed
abstract class BuanLevel with _$BuanLevel {
  const factory BuanLevel({
    required int level,
    required String name,
    String? nextName,
    @Default(0) int pointsToNext,

    /// Tüm seviye yolundaki ilerleme (0–1); çubuk tüm seviyeleri kapsar.
    @Default(0) double progress,

    /// Çubuğun altındaki seviye adları (Çaylak … Bursa Elçisi).
    @Default(<String>[]) List<String> tiers,
  }) = _BuanLevel;

  factory BuanLevel.fromJson(Map<String, dynamic> json) => _$BuanLevelFromJson(json);
}

/// `GET /buan/streak` — günlük seri ve bu haftanın 7 günü.
@freezed
abstract class BuanStreak with _$BuanStreak {
  const factory BuanStreak({
    required int days,

    /// "10. günde +500 bonus" — panelden.
    int? bonusDay,
    int? bonusAmount,
    @Default(<BuanStreakDay>[]) List<BuanStreakDay> week,
  }) = _BuanStreak;

  factory BuanStreak.fromJson(Map<String, dynamic> json) => _$BuanStreakFromJson(json);
}

@freezed
abstract class BuanStreakDay with _$BuanStreakDay {
  const factory BuanStreakDay({required DateTime date, @Default(false) bool done, @Default(false) bool today}) = _BuanStreakDay;

  factory BuanStreakDay.fromJson(Map<String, dynamic> json) => _$BuanStreakDayFromJson(json);
}
