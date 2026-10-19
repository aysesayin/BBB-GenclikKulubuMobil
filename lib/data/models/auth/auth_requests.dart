import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_requests.freezed.dart';
part 'auth_requests.g.dart';

/// Giriş yöntemi (sekme): T.C. Kimlik No, cep telefonu, e-posta.
enum LoginMethod { tckn, phone, email }

@freezed
abstract class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required LoginMethod method,
    required String identifier,
    required String password,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);
}

@freezed
abstract class EmergencyContact with _$EmergencyContact {
  const factory EmergencyContact({required String name, required String phone}) = _EmergencyContact;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) => _$EmergencyContactFromJson(json);
}

/// Zorunlu sözleşmeler (dördü de) + ayrı, isteğe bağlı Açık Rıza.
/// [key] `/app/legal/{key}` için kullanılır.
enum LegalDoc {
  terms('terms'),
  privacy('privacy'),
  kvkk('kvkk'),
  health('health'),
  explicitConsent('explicit-consent');

  const LegalDoc(this.key);
  final String key;

  static const required = [terms, privacy, kvkk, health];
}

@freezed
abstract class RegisterRequest with _$RegisterRequest {
  @JsonSerializable(explicitToJson: true)
  const factory RegisterRequest({
    required String tckn,

    /// `yyyy-MM-dd`
    required String birthDate,
    required String phone,
    required String email,
    required EmergencyContact emergencyContact,

    /// OTP doğrulamasından dönen tek kullanımlık jeton.
    required String otpToken,
    required List<String> acceptedConsents,
    @Default(false) bool explicitConsent,
    String? referralCode,

    /// Hikâyedeki coin'e dokunulduysa cihazda bekleyen onboarding bonusu.
    @Default(false) bool onboardingBonusClaimed,
  }) = _RegisterRequest;

  factory RegisterRequest.fromJson(Map<String, dynamic> json) => _$RegisterRequestFromJson(json);
}
