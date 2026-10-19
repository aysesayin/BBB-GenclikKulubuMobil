import 'package:freezed_annotation/freezed_annotation.dart';

part 'referral.freezed.dart';
part 'referral.g.dart';

enum InviteeStatus {
  @JsonValue('rewarded')
  rewarded,
  @JsonValue('pending')
  pending,
  @JsonValue('notRegistered')
  notRegistered,
}

/// Davet edilen kişi — ad "Ad S." biçiminde kısaltılmış gelir (KVKK).
@freezed
abstract class Invitee with _$Invitee {
  const factory Invitee({
    required String id,
    required String name,
    required String initials,
    @Default(InviteeStatus.notRegistered) InviteeStatus status,
    @Default(0) int reward,
  }) = _Invitee;

  factory Invitee.fromJson(Map<String, dynamic> json) => _$InviteeFromJson(json);
}

/// `GET /buan/referral` — davet kodu, ödüller ve istatistik.
@freezed
abstract class Referral with _$Referral {
  const factory Referral({
    required String code,
    required int inviterReward,
    required int inviteeReward,
    @Default(1) int weeklyLimit,
    @Default(0) int weeklyUsed,
    DateTime? nextResetAt,
    @Default(<Invitee>[]) List<Invitee> invitees,
  }) = _Referral;

  factory Referral.fromJson(Map<String, dynamic> json) => _$ReferralFromJson(json);
}
