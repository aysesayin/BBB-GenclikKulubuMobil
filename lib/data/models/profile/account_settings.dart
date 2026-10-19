import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_settings.freezed.dart';
part 'account_settings.g.dart';

/// `GET/PUT /users/me/preferences` — bildirim tercihleri ve dil.
@freezed
abstract class NotificationPrefs with _$NotificationPrefs {
  const factory NotificationPrefs({
    @Default(true) bool opportunities,
    @Default(true) bool events,
    @Default(true) bool streakReminder,
    @Default(false) bool announcements,
    @Default(true) bool achievements,
    @Default('tr') String language,
  }) = _NotificationPrefs;

  factory NotificationPrefs.fromJson(Map<String, dynamic> json) => _$NotificationPrefsFromJson(json);
}

enum ContactKind { phone, email }

/// `PUT /users/me/contact` yanıtı: yeni adrese OTP gönderildi.
@freezed
abstract class ContactChallenge with _$ContactChallenge {
  const factory ContactChallenge({
    required String challengeId,
    @Default('') String maskedTarget,
    @Default(120) int expiresIn,
    @Default(6) int codeLength,
  }) = _ContactChallenge;

  factory ContactChallenge.fromJson(Map<String, dynamic> json) => _$ContactChallengeFromJson(json);
}
