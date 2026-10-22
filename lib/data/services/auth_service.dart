import '../../core/network/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/network/app_exception.dart';
import '../../core/network/dio_client.dart';
import '../models/auth/auth_requests.dart';
import '../models/auth/auth_session.dart';
import '../models/auth/first_day_task.dart';
import '../models/auth/otp_challenge.dart';

/// Mock modundaki demo değerleri (tasarım notları): OTP 481926, hatalı şifre "yanlis123".
abstract final class AuthDemo {
  static const otpCode = '481926';
  static const wrongPassword = 'yanlis123';
}

/// Uzak veri kaynağı: kimlik doğrulama uç noktaları.
class AuthService {
  AuthService(this._client);

  final DioClient _client;

  static AuthSession _session(Object? d) => AuthSession.fromJson(Json.map(d));

  Future<ApiResult<AuthSession>> login(LoginRequest request) async {
    // Mock dosyası her zaman başarı döner; hatalı şifre senaryosu burada üretilir.
    if (ApiConfig.useMock && request.password == AuthDemo.wrongPassword) {
      await Future<void>.delayed(ApiConfig.mockLatency);
      return const Failure(UnauthorizedException());
    }
    return _client.post(ApiEndpoints.login, body: request.toJson(), parse: _session);
  }

  Future<ApiResult<AuthSession>> biometricLogin({String? deviceId}) =>
      _client.post(ApiEndpoints.biometricLogin, body: {'deviceId': deviceId}, parse: _session);

  Future<ApiResult<OtpChallenge>> sendOtp(String phone, {bool resend = false}) => _client.post(
        resend ? ApiEndpoints.resendOtp : ApiEndpoints.sendOtp,
        body: {'phone': phone, 'purpose': 'register'},
        parse: (d) => OtpChallenge.fromJson(Json.map(d)),
      );

  Future<ApiResult<OtpVerification>> verifyOtp(String phone, String code) async {
    if (ApiConfig.useMock && code != AuthDemo.otpCode) {
      await Future<void>.delayed(ApiConfig.mockLatency);
      return const Failure(ValidationException(fieldErrors: {'code': 'invalid'}));
    }
    return _client.post(
      ApiEndpoints.verifyOtp,
      body: {'phone': phone, 'code': code},
      parse: (d) => OtpVerification.fromJson(Json.map(d)),
    );
  }

  Future<ApiResult<MernisResult>> verifyMernis({required String tckn, required String birthDate}) => _client.post(
        ApiEndpoints.verifyMernis,
        body: {'tckn': tckn, 'birthDate': birthDate},
        parse: (d) => MernisResult.fromJson(Json.map(d)),
      );

  Future<ApiResult<AuthSession>> register(RegisterRequest request, {String? idempotencyKey}) => _client.post(
        ApiEndpoints.register,
        body: request.toJson(),
        headers: idempotencyKey == null ? null : {'Idempotency-Key': idempotencyKey},
        parse: _session,
      );

  Future<ApiResult<void>> forgotPassword(LoginMethod method, String identifier) => _client.post(
        ApiEndpoints.forgotPassword,
        body: {'method': method.name, 'identifier': identifier},
        parse: Json.ignore,
      );

  Future<ApiResult<void>> requestParentConsent({
    required String tckn,
    required String birthDate,
    required String parentPhone,
  }) =>
      _client.post(
        ApiEndpoints.parentConsent,
        body: {'tckn': tckn, 'birthDate': birthDate, 'parentPhone': parentPhone},
        parse: Json.ignore,
      );

  /// Kayıt sonrası "İlk günün" görevleri (başlık, ödül ve hedef yol API'den).
  Future<ApiResult<List<FirstDayTask>>> firstDayTasks() => _client.get(
        ApiEndpoints.firstDay,
        parse: (d) => Json.list(d, FirstDayTask.fromJson),
        cacheKey: 'firstDay',
      );
}
