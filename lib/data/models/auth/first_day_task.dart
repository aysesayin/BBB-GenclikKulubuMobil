import 'package:freezed_annotation/freezed_annotation.dart';

part 'first_day_task.freezed.dart';
part 'first_day_task.g.dart';

/// Kayıt sonrası "İlk günün" kontrol listesi kalemi (`GET /auth/first-day`).
/// [route] uygulama içi yol (`Routes.*` ile aynı dize), [icon] `AppIcons` anahtarı.
@freezed
abstract class FirstDayTask with _$FirstDayTask {
  const factory FirstDayTask({
    required String id,
    required String title,
    @Default('') String subtitle,
    @Default(0) int reward,
    @Default('sparkle') String icon,
    @Default('') String route,
  }) = _FirstDayTask;

  factory FirstDayTask.fromJson(Map<String, dynamic> json) => _$FirstDayTaskFromJson(json);
}
