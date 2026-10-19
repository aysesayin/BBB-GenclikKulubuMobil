import 'package:freezed_annotation/freezed_annotation.dart';

part 'otp_challenge.freezed.dart';
part 'otp_challenge.g.dart';

/// `/auth/otp/send` ve `/auth/otp/resend` yanıtı.
@freezed
abstract class OtpChallenge with _$OtpChallenge {
  const factory OtpChallenge({
    @Default('') String maskedPhone,

    /// Tekrar göndermeye kadar bekleme (sn).
    @Default(45) int resendIn,
    @Default(6) int length,
  }) = _OtpChallenge;

  factory OtpChallenge.fromJson(Map<String, dynamic> json) => _$OtpChallengeFromJson(json);
}

/// `/auth/otp/verify` yanıtı.
@freezed
abstract class OtpVerification with _$OtpVerification {
  const factory OtpVerification({required String verificationToken}) = _OtpVerification;

  factory OtpVerification.fromJson(Map<String, dynamic> json) => _$OtpVerificationFromJson(json);
}

/// `/auth/mernis/verify` yanıtı.
@freezed
abstract class MernisResult with _$MernisResult {
  const factory MernisResult({@Default(false) bool verified, String? message}) = _MernisResult;

  factory MernisResult.fromJson(Map<String, dynamic> json) => _$MernisResultFromJson(json);
}
