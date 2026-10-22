import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_link.dart';

part 'home_items.freezed.dart';
part 'home_items.g.dart';

/// Hikâye halkası (Keşfet üst şeridi).
@freezed
abstract class HomeStory with _$HomeStory {
  const factory HomeStory({
    required String id,
    required String label,

    /// İkon anahtarı (bkz. `HomeIcons.of`).
    @Default('megaphone') String icon,

    /// Pastel karo tonu 1–6 (`palette.tile1..6`).
    @Default(1) int tone,
    @Default(false) bool seen,
  }) = _HomeStory;

  factory HomeStory.fromJson(Map<String, dynamic> json) => _$HomeStoryFromJson(json);
}

/// "Bugünün Görevleri" kartı.
@freezed
abstract class HomeTask with _$HomeTask {
  const factory HomeTask({
    required String id,
    required String title,
    @Default('') String subtitle,
    @Default(0) int points,

    /// 0–1 arası ilerleme (halka).
    @Default(0) double progress,
    @Default('sparkle') String icon,

    /// Halka/ikon vurgu rengi: green · teal · pink · purple · yellow.
    @Default('teal') String accent,
    required AppLink link,
  }) = _HomeTask;

  factory HomeTask.fromJson(Map<String, dynamic> json) => _$HomeTaskFromJson(json);
}

/// Banner karuseli öğesi (1400×800 görsel oranı 1.75).
@freezed
abstract class HomeBanner with _$HomeBanner {
  const factory HomeBanner({
    required String id,
    @Default('') String kicker,
    required String title,
    String? ctaLabel,

    /// Vurgu tonu: buan (mor) · spin (sarı/CTA) · event (turkuaz-yeşil) · opportunity (pembe).
    @Default('buan') String tone,
    required AppLink link,
  }) = _HomeBanner;

  factory HomeBanner.fromJson(Map<String, dynamic> json) => _$HomeBannerFromJson(json);
}

/// Kısayol ızgarası öğesi.
@freezed
abstract class HomeShortcut with _$HomeShortcut {
  const factory HomeShortcut({
    required String id,
    required String label,
    required String icon,
    @Default(1) int tone,
    required AppLink link,
  }) = _HomeShortcut;

  factory HomeShortcut.fromJson(Map<String, dynamic> json) => _$HomeShortcutFromJson(json);
}

/// "Sana Özel Fırsatlar" kartı.
@freezed
abstract class HomeDeal with _$HomeDeal {
  const factory HomeDeal({
    required String id,
    required String brand,
    @Default('') String logo,

    /// Kartın sol üstündeki rozet: "%25", "1+1".
    @Default('') String badge,
    required String title,
    @Default(0) int daysLeft,
    @Default(3) int tone,
  }) = _HomeDeal;

  factory HomeDeal.fromJson(Map<String, dynamic> json) => _$HomeDealFromJson(json);
}

/// "Bu Hafta Etkinlikler" satırı.
@freezed
abstract class HomeEvent with _$HomeEvent {
  const factory HomeEvent({
    required String id,
    required String title,
    required DateTime startsAt,
    @Default('') String place,
    @Default(0) int capacity,
    @Default(0) int filled,
    @Default(2) int tone,
  }) = _HomeEvent;

  factory HomeEvent.fromJson(Map<String, dynamic> json) => _$HomeEventFromJson(json);
}
