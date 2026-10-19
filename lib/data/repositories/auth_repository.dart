import '../../core/network/api_result.dart';
import '../../core/storage/cache_store.dart';
import '../models/auth/auth_requests.dart';
import '../models/auth/auth_session.dart';
import '../models/auth/otp_challenge.dart';
import '../services/auth_service.dart';

/// Giriş, kayıt (OTP + MERNİS) ve onboarding bonusunun cihazda bekletilmesi.
abstract interface class AuthRepository {
  Future<ApiResult<AuthSession>> login(LoginRequest request);
  Future<ApiResult<AuthSession>> biometricLogin();
  Future<ApiResult<OtpChallenge>> sendOtp(String phone, {bool resend = false});
  Future<ApiResult<OtpVerification>> verifyOtp(String phone, String code);
  Future<ApiResult<MernisResult>> verifyMernis({required String tckn, required String birthDate});
  Future<ApiResult<AuthSession>> register(RegisterRequest request);
  Future<ApiResult<void>> forgotPassword(LoginMethod method, String identifier);
  Future<ApiResult<void>> requestParentConsent({required String tckn, required String birthDate, required String parentPhone});

  /// Hikâyedeki coin'e dokunuldu mu (bonus kayıtta hesaba aktarılır).
  bool get onboardingBonusHeld;
  Future<void> holdOnboardingBonus();

  /// Son başarılı kaydın yanıtı (Zirve ekranı kartı ve bonus dökümü için).
  AuthSession? get lastRegistration;
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._service, this._cache);

  final AuthService _service;
  final CacheStore _cache;
  AuthSession? _lastRegistration;
  String? _registerKey;

  static const _kBonus = 'pref.onboardingBonusHeld';

  @override
  Future<ApiResult<AuthSession>> login(LoginRequest request) => _service.login(request);

  @override
  Future<ApiResult<AuthSession>> biometricLogin() => _service.biometricLogin();

  @override
  Future<ApiResult<OtpChallenge>> sendOtp(String phone, {bool resend = false}) => _service.sendOtp(phone, resend: resend);

  @override
  Future<ApiResult<OtpVerification>> verifyOtp(String phone, String code) => _service.verifyOtp(phone, code);

  @override
  Future<ApiResult<MernisResult>> verifyMernis({required String tckn, required String birthDate}) =>
      _service.verifyMernis(tckn: tckn, birthDate: birthDate);

  @override
  Future<ApiResult<AuthSession>> register(RegisterRequest request) async {
    // Aynı kayıt tekrar denenirse (ağ kopması) sunucu çift hesap açmasın.
    _registerKey ??= 'reg-${DateTime.now().microsecondsSinceEpoch}';
    final r = await _service.register(request, idempotencyKey: _registerKey);
    if (r case Success(:final data)) {
      _lastRegistration = data;
      _registerKey = null;
      await _cache.remove(_kBonus);
    }
    return r;
  }

  @override
  Future<ApiResult<void>> forgotPassword(LoginMethod method, String identifier) =>
      _service.forgotPassword(method, identifier);

  @override
  Future<ApiResult<void>> requestParentConsent({required String tckn, required String birthDate, required String parentPhone}) =>
      _service.requestParentConsent(tckn: tckn, birthDate: birthDate, parentPhone: parentPhone);

  @override
  bool get onboardingBonusHeld => _cache.readBool(_kBonus) ?? false;

  @override
  Future<void> holdOnboardingBonus() => _cache.writeBool(_kBonus, value: true);

  @override
  AuthSession? get lastRegistration => _lastRegistration;
}
