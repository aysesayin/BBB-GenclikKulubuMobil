import '../../../../core/base/base_view_model.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/app_exception.dart';
import '../../../../core/utils/validators.dart';
import '../../../../data/models/profile/account_settings.dart';
import '../../../../data/repositories/profile_repository.dart';

enum ContactStep { enter, verify }

/// Telefon / e-posta değiştirme: 1) yeni değer → OTP gönder, 2) OTP doğrula.
class ContactChangeViewModel extends BaseViewModel {
  ContactChangeViewModel(this._repo, this.kind);

  final ProfileRepository _repo;
  final ContactKind kind;

  ContactStep _step = ContactStep.enter;
  ContactStep get step => _step;

  bool _busy = false;
  bool get busy => _busy;

  ValidationIssue? _issue;
  ValidationIssue? get issue => _issue;

  AppException? _error;
  AppException? get error => _error;

  ContactChallenge? _challenge;
  ContactChallenge? get challenge => _challenge;
  int get codeLength => _challenge?.codeLength ?? 6;

  String _target = '';

  /// Kullanıcının girdiği yeni değer (OTP adımında gösterilir).
  String get target => _target;

  static String normalize(ContactKind kind, String raw) {
    if (kind == ContactKind.email) return raw.trim().toLowerCase();
    final d = raw.replaceAll(RegExp(r'\D'), '');
    return d.length == 10 ? '0$d' : d;
  }

  Future<bool> sendCode(String raw) async {
    if (_busy) return false;
    final issue = kind == ContactKind.phone ? Validators.phone(raw) : Validators.email(raw);
    _issue = issue;
    _error = null;
    if (issue != null) {
      notify();
      return false;
    }
    _target = normalize(kind, raw);
    return _request();
  }

  Future<bool> resend() => _request();

  Future<bool> _request() async {
    _busy = true;
    notify();
    final result = await _repo.updateContact(kind, _target);
    _busy = false;
    switch (result) {
      case Success(:final data):
        _challenge = data;
        _step = ContactStep.verify;
        _error = null;
      case Failure(:final error):
        _error = error;
    }
    notify();
    return result is Success;
  }

  /// true → doğrulandı, sheet kapanabilir.
  Future<bool> verify(String code) async {
    final challenge = _challenge;
    if (_busy || challenge == null) return false;
    final digits = code.replaceAll(RegExp(r'\D'), '');
    _issue = Validators.otp(digits, length: codeLength);
    _error = null;
    if (_issue != null) {
      notify();
      return false;
    }
    _busy = true;
    notify();
    final result = await _repo.verifyContact(challenge.challengeId, digits);
    _busy = false;
    if (result case Failure(:final error)) _error = error;
    notify();
    return result is Success;
  }

  void editTarget() {
    _step = ContactStep.enter;
    _issue = null;
    _error = null;
    notify();
  }
}
