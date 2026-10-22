import 'dart:async';

import '../../../core/base/base_view_model.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/router/routes.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/auth/auth_requests.dart';
import '../../../data/models/auth/auth_session.dart';
import '../../../data/models/auth/otp_challenge.dart';
import '../../../data/repositories/app_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/interests_repository.dart';
import 'register_form.dart';

export 'register_form.dart' show TcknStatus;

enum RegisterStep { identity, contact, otp, agreements, verification, underAge }

enum OtpState { idle, verifying, wrong, ok }

enum VerifyStatus { idle, running, verified, failed }

enum UnderAgeKind { needsParent, tooYoung }

/// A5 · "Uludağ'a tırmanış" kayıt akışı: tek soru / ekran, 5 durak
/// Tophane → Ulu Cami → Kozahan → Teleferik → Zirve.
/// Kimlik → Cep telefonu → SMS kodu → Sözleşmeler → MERNİS + kayıt.
/// E-posta ve acil durum kişisi kayıtta sorulmaz; Zirve'de profilden tamamlanması hatırlatılır.
class RegisterViewModel extends BaseViewModel with RegisterForm {
  RegisterViewModel(
    this._auth,
    this._interests,
    this._app,
    this._session, {
    this.referralCode,
    DateTime Function()? clock,
    this.minScene = const Duration(milliseconds: 2600),
    this.otpAdvance = const Duration(milliseconds: 900),
  }) : _clock = clock ?? DateTime.now {
    setBirthDate(DateTime(_clock().year - 22, 3, 14));
  }

  final AuthRepository _auth;
  final InterestsRepository _interests;
  final AppRepository _app;
  final SessionController _session;
  final DateTime Function() _clock;

  /// `?ref=` davet kodu.
  final String? referralCode;

  /// MERNİS sahnesinin en kısa süresi (kalkan dolumu 2,6 sn) ve OTP doğruysa bekleme.
  final Duration minScene, otpAdvance;

  // TODO(varsayım): Yaş kuralları panelden gelecek; tasarım notu "16–17 veli onayı, 2009+ doğum → 18 altı".
  static const adultAge = 18, minAge = 16;
  static const stopCount = 5;

  RegisterStep _step = RegisterStep.identity;
  RegisterStep get step => _step;
  int get stopIndex => switch (_step) {
        RegisterStep.identity || RegisterStep.underAge => 0,
        RegisterStep.contact => 1,
        RegisterStep.otp => 2,
        RegisterStep.agreements => 3,
        RegisterStep.verification => 4,
      };

  int get firstYear => _clock().year - 36;
  int get lastYear => _clock().year - 14;
  int get onboardingBonus => _app.current.onboardingBonus;

  bool _busy = false;
  bool get busy => _busy;
  AppException? _error;
  AppException? get error => _error;

  bool _tried = false;

  /// Adımda "Devam"a basıldıktan sonra alan hataları gösterilir.
  bool get showIssues => _tried;

  // ---- OTP ----
  OtpChallenge? _challenge;
  String get maskedPhone => (_challenge?.maskedPhone.isNotEmpty ?? false) ? _challenge!.maskedPhone : Fmt.maskPhone(phone11);
  String _otp = '';
  String get otp => _otp;
  OtpState _otpState = OtpState.idle;
  OtpState get otpState => _otpState;
  String? _otpToken;
  int _resendLeft = 0;
  int get resendLeft => _resendLeft;
  Timer? _timer;

  // ---- Doğrulama / 18 yaş altı ----
  VerifyStatus _verify = VerifyStatus.idle;
  VerifyStatus get verifyStatus => _verify;
  UnderAgeKind? _underAge;
  UnderAgeKind? get underAge => _underAge;
  bool _parentSent = false;
  bool get parentSent => _parentSent;

  Future<ApiResult<String>> legalText(LegalDoc d) => _app.legalText(d.key);

  bool get canContinue => switch (_step) {
        RegisterStep.agreements => allRequiredAccepted && !_busy,
        RegisterStep.otp => _otp.length == 6 && _otpState != OtpState.verifying,
        RegisterStep.verification => false,
        RegisterStep.underAge => _underAge == UnderAgeKind.needsParent && !_parentSent && !_busy,
        _ => !_busy,
      };

  void _go(RegisterStep s) {
    _step = s;
    _tried = false;
    _error = null;
    notify();
  }

  Future<void> next() async {
    _tried = true;
    _error = null;
    switch (_step) {
      case RegisterStep.identity:
        if (tcknStatus != TcknStatus.valid) {
          bumpShake();
          return notify();
        }
        final age = Validators.ageOn(birthDate, _clock());
        if (age < adultAge) {
          _underAge = age < minAge ? UnderAgeKind.tooYoung : UnderAgeKind.needsParent;
          return _go(RegisterStep.underAge);
        }
        return _go(RegisterStep.contact);
      case RegisterStep.contact:
        if (phoneIssue != null) return notify();
        if (await _sendOtp(resend: false)) _go(RegisterStep.otp);
      case RegisterStep.otp:
        await verifyOtp();
      case RegisterStep.agreements:
        if (!allRequiredAccepted) return notify();
        _go(RegisterStep.verification);
        await runVerification();
      case RegisterStep.underAge:
        await sendParentConsent();
      case RegisterStep.verification:
        return;
    }
  }

  /// false → ilk adımdayız, görünüm rotadan çıkar.
  bool back() {
    final prev = switch (_step) {
      RegisterStep.identity => null,
      RegisterStep.underAge || RegisterStep.contact => RegisterStep.identity,
      // Sözleşmelerden geri: numara değişebilir, kod yeniden gönderilir.
      RegisterStep.otp || RegisterStep.agreements => RegisterStep.contact,
      RegisterStep.verification => _verify == VerifyStatus.failed ? RegisterStep.agreements : RegisterStep.verification,
    };
    if (prev == null) return false;
    if (prev != _step) _go(prev);
    return true;
  }

  void setOtp(String v) {
    final d = RegisterForm.digits(v);
    _otp = d.length > 6 ? d.substring(0, 6) : d;
    if (_otpState == OtpState.wrong) _otpState = OtpState.idle;
    notify();
    if (_otp.length == 6) verifyOtp();
  }

  Future<bool> _sendOtp({required bool resend}) async {
    _busy = true;
    notify();
    final r = await _auth.sendOtp(phone11, resend: resend);
    _busy = false;
    switch (r) {
      case Success(:final data):
        _challenge = data;
        _otp = '';
        _otpState = OtpState.idle;
        _startResendTimer(data.resendIn);
        notify();
        return true;
      case Failure(:final error):
        _error = error;
        notify();
        return false;
    }
  }

  Future<void> resendOtp() async {
    if (_resendLeft > 0 || _busy) return;
    await _sendOtp(resend: true);
  }

  void _startResendTimer(int seconds) {
    _timer?.cancel();
    _resendLeft = seconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _resendLeft = (_resendLeft - 1).clamp(0, seconds);
      if (_resendLeft == 0) t.cancel();
      notify();
    });
  }

  Future<void> verifyOtp() async {
    if (_otp.length != 6 || _otpState == OtpState.verifying || _otpState == OtpState.ok) return;
    _otpState = OtpState.verifying;
    notify();
    final r = await _auth.verifyOtp(phone11, _otp);
    if (isDisposed) return;
    switch (r) {
      case Success(:final data):
        _otpToken = data.verificationToken;
        _otpState = OtpState.ok;
        _timer?.cancel();
        notify();
        await Future<void>.delayed(otpAdvance);
        if (!isDisposed && _step == RegisterStep.otp) _go(RegisterStep.agreements);
      case Failure(:final error):
        _otpState = error is ValidationException ? OtpState.wrong : OtpState.idle;
        if (error is! ValidationException) _error = error;
        bumpShake();
        notify();
    }
  }

  Future<void> runVerification() async {
    _verify = VerifyStatus.running;
    _error = null;
    notify();
    final scene = Future<void>.delayed(minScene);
    final m = await _auth.verifyMernis(tckn: tckn, birthDate: birthIso);
    if (m case Failure(:final error)) return _fail(error);
    if (m case Success(:final data) when !data.verified) return _fail(ValidationException(serverMessage: data.message));
    final r = await _auth.register(RegisterRequest(
      tckn: tckn,
      birthDate: birthIso,
      phone: phone11,
      otpToken: _otpToken ?? '',
      acceptedConsents: acceptedKeys,
      explicitConsent: explicitConsent,
      referralCode: referralCode,
      onboardingBonusClaimed: _auth.onboardingBonusHeld,
    ));
    switch (r) {
      case Failure(:final error):
        return _fail(error);
      case Success(:final data):
        await _session.signIn(accessToken: data.accessToken, refreshToken: data.refreshToken, user: data.user.toSessionUser());
        await _session.markOnboardingSeen();
        // TODO(varsayım): İlgi alanı kaydı başarısızsa akış durmaz; profilde tekrar sorulur.
        await _interests.saveHeld();
    }
    await scene;
    if (isDisposed) return;
    _verify = VerifyStatus.verified;
    notify();
  }

  void _fail(AppException e) {
    if (isDisposed) return;
    _verify = VerifyStatus.failed;
    _error = e;
    notify();
  }

  Future<void> sendParentConsent() async {
    if (parentPhoneIssue != null) return notify();
    _busy = true;
    notify();
    final r = await _auth.requestParentConsent(tckn: tckn, birthDate: birthIso, parentPhone: parentPhone);
    _busy = false;
    _parentSent = r is Success;
    if (r case Failure(:final error)) _error = error;
    notify();
  }

  /// "Sonra" / "Misafir olarak devam et": onboarding kapanır, Keşfet açılır.
  Future<String> continueAsGuest() async {
    _session.continueAsGuest();
    await _session.markOnboardingSeen();
    return Routes.home;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
