import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_detail.freezed.dart';
part 'event_detail.g.dart';

/// Kategori kotası ("6 ayda 1 katılım"). Metin ve hak durumu sunucudan gelir.
@freezed
abstract class EventQuota with _$EventQuota {
  const factory EventQuota({
    required String title,
    @Default('') String message,
    @Default(true) bool eligible,
  }) = _EventQuota;

  factory EventQuota.fromJson(Map<String, dynamic> json) => _$EventQuotaFromJson(json);
}

/// Katılımcı avatarı (yalnız baş harfler — KVKK).
@freezed
abstract class EventAttendee with _$EventAttendee {
  const factory EventAttendee({required String initials, @Default('tile2') String tone}) = _EventAttendee;

  factory EventAttendee.fromJson(Map<String, dynamic> json) => _$EventAttendeeFromJson(json);
}

/// `GET /events/{id}` (G2).
@freezed
abstract class EventDetail with _$EventDetail {
  const EventDetail._();

  const factory EventDetail({
    required String id,
    required String title,
    required String categoryId,
    required String categoryLabel,
    required DateTime startsAt,
    DateTime? endsAt,
    DateTime? applyDeadline,
    @Default('') String placeName,
    String? placeNote,
    String? placeId,
    double? lat,
    double? lng,

    /// 0 → ücretsiz.
    @Default(0) num price,
    String? priceNote,
    int? ageMin,
    int? ageMax,
    String? ageNote,
    @Default(0) int capacity,
    @Default(0) int attendeeCount,
    @Default(<EventAttendee>[]) List<EventAttendee> attendees,

    /// Check-in'de kazanılacak BUAN (null → rozet yok).
    int? checkInBuan,
    EventQuota? quota,
    @Default('') String program,

    /// Kapak: görsel adresi yoksa [cover] çizimi (mountain, generic) kullanılır.
    String? coverUrl,
    @Default('generic') String cover,
    @Default('calendar') String icon,
    @Default('tile4') String tone,
    @Default(false) bool waitlistOpen,

    /// none | applied | waitlisted
    @Default('none') String applicationStatus,
  }) = _EventDetail;

  factory EventDetail.fromJson(Map<String, dynamic> json) => _$EventDetailFromJson(json);

  bool get isFull => capacity > 0 && attendeeCount >= capacity;
  bool get hasApplied => applicationStatus == 'applied';
  bool get isWaitlisted => applicationStatus == 'waitlisted';
  double get fillRatio => capacity <= 0 ? 0 : (attendeeCount / capacity).clamp(0, 1).toDouble();

  /// Son başvuru geçti mi? Yalnız tarih verilmişse (00:00) gün sonuna kadar açık sayılır.
  bool isClosed(DateTime now) {
    final d = applyDeadline;
    if (d == null) return false;
    final end = d.hour == 0 && d.minute == 0 ? d.add(const Duration(days: 1)) : d;
    return now.isAfter(end);
  }
}

/// `POST /events/{id}/apply` yanıtı.
@freezed
abstract class EventApplyResult with _$EventApplyResult {
  const factory EventApplyResult({
    /// applied | waitlisted
    @Default('applied') String status,
    int? attendeeCount,
    String? message,
  }) = _EventApplyResult;

  factory EventApplyResult.fromJson(Map<String, dynamic> json) => _$EventApplyResultFromJson(json);
}
