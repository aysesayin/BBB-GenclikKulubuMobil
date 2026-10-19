import 'package:freezed_annotation/freezed_annotation.dart';

part 'steps.freezed.dart';
part 'steps.g.dart';

/// Haftalık grafik için bir gün.
@freezed
abstract class StepDay with _$StepDay {
  const factory StepDay({required DateTime date, required int steps}) = _StepDay;

  factory StepDay.fromJson(Map<String, dynamic> json) => _$StepDayFromJson(json);
}

/// `GET /buan/steps` ve `POST /buan/steps` yanıtı — günlük hedef + hafta.
@freezed
abstract class StepsSummary with _$StepsSummary {
  const factory StepsSummary({
    required DateTime date,
    required int goal,
    required int reward,

    /// Sunucunun bugün için kabul ettiği adım (üst limit uygulanmış).
    @Default(0) int steps,

    /// Bugünün ödülü verildi mi?
    @Default(false) bool claimed,

    /// Haftada hedefe ulaşılması beklenen gün sayısı ("Hedefe 4 / 6 gün").
    @Default(6) int weeklyTargetDays,

    /// Önceki günler (bugün hariç, eskiden yeniye).
    @Default(<StepDay>[]) List<StepDay> week,

    /// Bu POST'ta verilen BUAN (yalnız POST yanıtında).
    @Default(0) int awarded,
  }) = _StepsSummary;

  factory StepsSummary.fromJson(Map<String, dynamic> json) => _$StepsSummaryFromJson(json);
}
