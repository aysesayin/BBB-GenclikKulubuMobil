import 'package:freezed_annotation/freezed_annotation.dart';

part 'buan_task.freezed.dart';
part 'buan_task.g.dart';

/// Görev türü — kartın hangi ekrana gideceğini belirler.
enum BuanTaskType { watch, steps, spin, quiz, idea, invite, volunteer, biko, follow, qr, photo, useOpportunity, unknown }

enum BuanTaskStatus { available, pending, done, locked }

/// Kilit nedeni: yaş sınırı ya da sıklık limiti (ör. "12 haftada 1").
enum BuanTaskLock { none, age, limit }

/// `GET /buan/tasks` — değer, sıklık, yaş sınırı ve kurallar panelden gelir.
@freezed
abstract class BuanTask with _$BuanTask {
  const BuanTask._();

  const factory BuanTask({
    required String id,
    @JsonKey(unknownEnumValue: BuanTaskType.unknown) required BuanTaskType type,
    required String title,
    @Default('') String subtitle,
    required int points,

    /// Aralıklı ödül (Günlük Şans "+10–200") için üst değer.
    int? pointsMax,
    @JsonKey(unknownEnumValue: BuanTaskStatus.available) @Default(BuanTaskStatus.available) BuanTaskStatus status,
    @JsonKey(unknownEnumValue: BuanTaskLock.none) @Default(BuanTaskLock.none) BuanTaskLock lock,

    /// Sunucu hazır kilit metni verirse doğrudan gösterilir.
    String? lockLabel,

    /// Sıklık limiti dolduğunda tekrar yapılabileceği an.
    DateTime? availableAt,
    int? minAge,
    int? maxAge,

    /// 0–1 ilerleme (adım, haftada 2 quiz …). null → çubuk yok.
    double? progress,

    /// Pastel karo rengi 1–6 (palette.tile1…tile6).
    int? tile,

    /// "12 haftada 1" gibi sıklık açıklaması.
    String? frequency,
    @Default(<String>[]) List<String> rules,
  }) = _BuanTask;

  factory BuanTask.fromJson(Map<String, dynamic> json) => _$BuanTaskFromJson(json);

  bool get isLocked => status == BuanTaskStatus.locked;
  bool get isDone => status == BuanTaskStatus.done;
}

/// Görev bölümü (Günlük / Haftalık / Tek Seferlik / Özel Kampanyalar) — başlık ve not panelden.
@freezed
abstract class BuanTaskGroup with _$BuanTaskGroup {
  const factory BuanTaskGroup({
    required String id,
    required String title,
    @Default('') String note,
    @Default(<BuanTask>[]) List<BuanTask> tasks,
  }) = _BuanTaskGroup;

  factory BuanTaskGroup.fromJson(Map<String, dynamic> json) => _$BuanTaskGroupFromJson(json);
}
