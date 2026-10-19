import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_config.freezed.dart';
part 'app_config.g.dart';

/// `/app/config` — uzaktan yapılandırma: bakım modu, zorunlu güncelleme,
/// özellik bayrakları ve panelden yönetilen sayılar/metinler.
@freezed
abstract class AppConfig with _$AppConfig {
  const factory AppConfig({
    @Default('1.0.0') String minVersion,
    @Default(false) bool maintenance,
    String? maintenanceMessage,
    @Default(<String, bool>{}) Map<String, bool> features,

    /// Kayıt sonrası hoş geldin bonusu (BUAN).
    @Default(500) int welcomeBonus,

    /// Onboarding'deki "coin'e dokun" bonusu (BUAN).
    @Default(100) int onboardingBonus,

    /// Maskot adı (panelden).
    @Default('Buancık') String mascotName,
  }) = _AppConfig;

  factory AppConfig.fromJson(Map<String, dynamic> json) => _$AppConfigFromJson(json);
}
