import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/session/session_controller.dart';

part 'auth_session.freezed.dart';
part 'auth_session.g.dart';

/// `/auth/login`, `/auth/register`, `/auth/biometric` yanıtı.
@freezed
abstract class AuthSession with _$AuthSession {
  const factory AuthSession({
    required String accessToken,
    required String refreshToken,
    required AuthUser user,

    /// Yalnız kayıtta gelir: Zirve ekranındaki kart doğuşu ve bonus dökümü.
    WelcomeCard? welcome,
  }) = _AuthSession;

  factory AuthSession.fromJson(Map<String, dynamic> json) => _$AuthSessionFromJson(json);
}

@freezed
abstract class AuthUser with _$AuthUser {
  const factory AuthUser({
    required String id,
    @Default('') String firstName,
    @Default('') String lastName,
    String? avatarUrl,
  }) = _AuthUser;

  factory AuthUser.fromJson(Map<String, dynamic> json) => _$AuthUserFromJson(json);
}

/// Kayıt sonrası dijital kart özeti + hoş geldin bonusları (panelden).
@freezed
abstract class WelcomeCard with _$WelcomeCard {
  const factory WelcomeCard({
    @Default('') String memberNo,
    @Default('') String levelName,
    @Default('') String checkInCode,
    @Default('') String qrToken,
    @Default(0) int welcomeBonus,
    @Default(0) int onboardingBonus,
    @Default(0) int inviteReward,
  }) = _WelcomeCard;

  factory WelcomeCard.fromJson(Map<String, dynamic> json) => _$WelcomeCardFromJson(json);
}

extension AuthUserX on AuthUser {
  SessionUser toSessionUser() => SessionUser(id: id, firstName: firstName, lastName: lastName, avatarUrl: avatarUrl);
}
