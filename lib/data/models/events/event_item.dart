import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_item.freezed.dart';
part 'event_item.g.dart';

/// Etkinlik kategorisi (panelden yönetilir): "Doğa Yürüyüşü", "Zumba", "Kariyer"…
@freezed
abstract class EventCategory with _$EventCategory {
  const factory EventCategory({required String id, required String label}) = _EventCategory;

  factory EventCategory.fromJson(Map<String, dynamic> json) => _$EventCategoryFromJson(json);
}

/// Etkinlik listesi kartı (G1).
@freezed
abstract class EventItem with _$EventItem {
  const EventItem._();

  const factory EventItem({
    required String id,
    required String title,
    required String categoryId,
    required String categoryLabel,
    required DateTime startsAt,
    DateTime? endsAt,
    @Default('') String placeName,
    @Default(0) int capacity,
    @Default(0) int attendeeCount,
    @Default(<String>[]) List<String> tags,

    /// Kart ikonu anahtarı (mountain, tent, briefcase, chip, music…).
    @Default('calendar') String icon,

    /// Kart zemini: palette adı (tile1…tile6).
    @Default('tile4') String tone,
    @Default(false) bool waitlistOpen,

    /// Check-in'de kazanılacak BUAN (kapak rozeti; null → rozet yok).
    int? checkInBuan,
  }) = _EventItem;

  factory EventItem.fromJson(Map<String, dynamic> json) => _$EventItemFromJson(json);

  bool get isFull => capacity > 0 && attendeeCount >= capacity;
  int get seatsLeft => capacity <= 0 ? 0 : (capacity - attendeeCount).clamp(0, capacity);

  /// Son 3 kişi ve altı → "az kaldı" vurgusu.
  bool get isLow => !isFull && capacity > 0 && seatsLeft <= 3;
  double get fillRatio => capacity <= 0 ? 0 : (attendeeCount / capacity).clamp(0, 1).toDouble();

  /// Etkinlik [day] gününe denk geliyor mu (çok günlü etkinlikler dahil)?
  bool occursOn(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final start = DateTime(startsAt.year, startsAt.month, startsAt.day);
    final endRef = endsAt ?? startsAt;
    final end = DateTime(endRef.year, endRef.month, endRef.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }
}

/// `GET /events` yanıtı: kategori listesi + etkinlikler.
@freezed
abstract class EventFeed with _$EventFeed {
  const factory EventFeed({
    @Default(<EventCategory>[]) List<EventCategory> categories,
    @Default(<EventItem>[]) List<EventItem> items,
  }) = _EventFeed;

  factory EventFeed.fromJson(Map<String, dynamic> json) => _$EventFeedFromJson(json);
}
