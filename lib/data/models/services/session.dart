import 'package:freezed_annotation/freezed_annotation.dart';

import 'facility.dart';

part 'session.freezed.dart';
part 'session.g.dart';

enum DayStatus { open, holiday, maintenance, closed, unknown }

enum SlotStatus { open, full, cancelled, maintenance, holiday, unknown }

enum Gender { male, female, mixed, unknown }

enum Relation { self, child, unknown }

/// Kimin için: kullanıcının kendisi veya kayıtlı çocuğu.
@freezed
abstract class Participant with _$Participant {
  const factory Participant({
    required String id,
    required String name,
    required int age,
    @JsonKey(unknownEnumValue: Gender.unknown) @Default(Gender.unknown) Gender gender,
    @JsonKey(unknownEnumValue: Relation.unknown) @Default(Relation.self) Relation relation,
  }) = _Participant;

  factory Participant.fromJson(Map<String, dynamic> json) => _$ParticipantFromJson(json);
}

@freezed
abstract class SessionDay with _$SessionDay {
  const factory SessionDay({
    required DateTime date,
    @JsonKey(unknownEnumValue: DayStatus.unknown) @Default(DayStatus.open) DayStatus status,
  }) = _SessionDay;

  factory SessionDay.fromJson(Map<String, dynamic> json) => _$SessionDayFromJson(json);
}

/// Tek seans / grup. Kontenjan canlıdır: [booked] / [capacity].
@freezed
abstract class SessionSlot with _$SessionSlot {
  const SessionSlot._();

  const factory SessionSlot({
    required String id,
    required DateTime start,
    required DateTime end,

    /// "Bay Günlük", "Sal–Per Grubu" — API içeriği.
    required String label,
    @JsonKey(unknownEnumValue: Gender.unknown) @Default(Gender.mixed) Gender gender,
    @Default(0) num price,

    /// Geç katılım indirimi öncesi liste fiyatı (varsa).
    num? listPrice,
    int? lateJoinRate,
    @Default(0) int capacity,
    @Default(0) int booked,
    @JsonKey(unknownEnumValue: SlotStatus.unknown) @Default(SlotStatus.open) SlotStatus status,
  }) = _SessionSlot;

  factory SessionSlot.fromJson(Map<String, dynamic> json) => _$SessionSlotFromJson(json);

  bool get isFull => status == SlotStatus.full || (capacity > 0 && booked >= capacity);
}

@freezed
abstract class ItemRules with _$ItemRules {
  const factory ItemRules({
    @Default(false) bool requiresSwimConfirmation,
    @Default(AgeRules()) AgeRules ageRules,

    /// Kalemin kendi yaş aralığı (ör. kurs 6–15). null → sınır yok.
    int? minAge,
    int? maxAge,
  }) = _ItemRules;

  factory ItemRules.fromJson(Map<String, dynamic> json) => _$ItemRulesFromJson(json);
}

/// `GET /services/items/{id}/sessions?from=&to=` — haftalık ızgara.
@freezed
abstract class SessionWeek with _$SessionWeek {
  const factory SessionWeek({
    required String itemId,
    required String title,
    @Default('') String facilityName,

    /// Sepette kontenjan ayırma süresi (dk).
    @Default(5) int holdMinutes,
    @Default(ItemRules()) ItemRules rules,
    @Default(<Participant>[]) List<Participant> participants,
    @Default(<SessionDay>[]) List<SessionDay> days,
    @Default(<SessionSlot>[]) List<SessionSlot> slots,
  }) = _SessionWeek;

  factory SessionWeek.fromJson(Map<String, dynamic> json) => _$SessionWeekFromJson(json);
}
