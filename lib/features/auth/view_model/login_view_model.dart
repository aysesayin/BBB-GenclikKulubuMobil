import '../../../core/base/base_view_model.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/router/routes.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/auth/auth_requests.dart';
import '../../../data/models/auth/auth_session.dart';
import '../../../data/repositories/auth_repository.dart';
import '../biometric_authenticator.dart';

/// Giriş hatası türü (görünüm yerelleştirir).
enum LoginError { none, identifier, passwordRequired, wrongPassword, locked, biometricUnavailable, other }

/// A6 · Giriş: TCKN / telefon / e-posta + şifre, Face ID.
class LoginViewModel extends BaseViewModel {
  LoginViewModel(this._auth, this._session, this._biometric, {this.from});

  final AuthRepository _auth;
  final SessionController _session;
  final BiometricAuthenticator _biometric;

  /// Girişten sonra dönülecek yol (misafir duvarından gelindiyse).
  final String? from;

  // TODO(varsayım): Hatalı şifre deneme hakkı sunucudan gelmezse yerel olarak 3 sayılır.
  static const maxAttempts = 3;

  LoginMethod _method = LoginMethod.tckn;
  LoginMethod get method => _method;

  String _identifier = '';
  String _password = '';
  String get identifier => _identifier;

  bool _obscure = true;
  bool get obscure => _obscure;

  bool _busy = false;
  bool get busy => _busy;

  LoginError _error = LoginError.none;
  LoginError get error => _error;

  ValidationIssue? _idIssue;
  ValidationIssue? get identifierIssue => _idIssue;

  AppException? _failure;
  AppException? get failure => _failure;

  int _remaining = maxAttempts;
  int get remainingAttempts => _remaining;

  /// Her hatalı denemede artar → şifre alanı sallanır.
  int _shake = 0;
  int get shakeTick => _shake;

  bool _biometricAvailable = false;
  bool get biometricAvailable => _biometricAvailable;

  bool _forgotSent = false;
  bool get forgotSent => _forgotSent;

  String? _destination;

  /// Başarılı girişte gidilecek yol.
  String? get destination => _destination;

  Future<void> init() async {
    _biometricAvailable = await _biometric.isAvailable();
    notify();
  }

  void setMethod(LoginMethod m) {
    if (m == _method) return;
    _method = m;
    _identifier = '';
    _idIssue = null;
    _clearError();
  }

  void setIdentifier(String v) {
    _identifier = v.trim();
    if (_idIssue != null) _idIssue = null;
    _clearError();
  }

  void setPassword(String v) {
    _password = v;
    if (_error == LoginError.wrongPassword || _error == LoginError.passwordRequired) _clearError();
  }

  void toggleObscure() {
    _obscure = !_obscure;
    notify();
  }

  void _clearError() {
    if (_error == LoginError.locked) return;
    _error = LoginError.none;
    _failure = null;
    notify();
  }

  ValidationIssue? _validateIdentifier() => switch (_method) {
        LoginMethod.tckn => Validators.tckn(_identifier),
        LoginMethod.phone => Validators.phone(_identifier),
        LoginMethod.email => Validators.email(_identifier),
      };

  String get _normalizedId => _method == LoginMethod.email ? _identifier : _identifier.replaceAll(RegExp(r'\D'), '');

  Future<bool> submit() async {
    if (_busy || _error == LoginError.locked) return false;
    _idIssue = _validateIdentifier();
    if (_idIssue != null) {
      _error = LoginError.identifier;
      notify();
      return false;
    }
    if (_password.isEmpty) {
      _error = LoginError.passwordRequired;
      _shake++;
      notify();
      return false;
    }
    _busy = true;
    _error = LoginError.none;
    notify();
    final r = await _auth.login(LoginRequest(method: _method, identifier: _normalizedId, password: _password));
    return _handle(r);
  }

  Future<bool> biometricLogin(String reason) async {
    if (_busy) return false;
    if (!_biometricAvailable) {
      _error = LoginError.biometricUnavailable;
      notify();
      return false;
    }
    if (!await _biometric.authenticate(reason)) return false;
    _busy = true;
    notify();
    return _handle(await _auth.biometricLogin());
  }

  Future<bool> _handle(ApiResult<AuthSession> r) async {
    switch (r) {
      case Success(:final data):
        await _session.signIn(accessToken: data.accessToken, refreshToken: data.refreshToken, user: data.user.toSessionUser());
        await _session.markOnboardingSeen();
        _destination = (from == null || from!.isEmpty) ? Routes.home : from;
        _busy = false;
        notify();
        return true;
      case Failure(:final error):
        _busy = false;
        _failure = error;
        if (error is UnauthorizedException) {
          final server = int.tryParse(error.fieldErrors['remainingAttempts'] ?? '');
          _remaining = (server ?? _remaining - 1).clamp(0, maxAttempts);
          _error = _remaining == 0 ? LoginError.locked : LoginError.wrongPassword;
          _shake++;
        } else if (error is RateLimitException) {
          _error = LoginError.locked;
          _shake++;
        } else {
          _error = LoginError.other;
        }
        notify();
        return false;
    }
  }

  Future<bool> forgotPassword() async {
    _idIssue = _validateIdentifier();
    if (_idIssue != null) {
      _error = LoginError.identifier;
      notify();
      return false;
    }
    final r = await _auth.forgotPassword(_method, _normalizedId);
    _forgotSent = r is Success;
    if (r case Failure(:final error)) {
      _failure = error;
      _error = LoginError.other;
    }
    notify();
    return _forgotSent;
  }
}
