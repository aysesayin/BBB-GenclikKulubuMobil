import '../../../core/base/base_view_model.dart';
import '../../../core/session/session_controller.dart';
import '../../../data/models/auth/auth_session.dart';
import '../../../data/repositories/app_repository.dart';
import '../../../data/repositories/auth_repository.dart';

/// A7 · Zirve: kart doğuşu + "onboarding + hoş geldin = toplam" bonus dökümü.
/// Kart bilgisi son kayıt yanıtından gelir; yoksa (ör. uygulama yeniden açıldı)
/// oturumdaki ad + panel varsayılanları kullanılır.
class SummitViewModel extends BaseViewModel {
  SummitViewModel(this._auth, this._app, this._session);

  final AuthRepository _auth;
  final AppRepository _app;
  final SessionController _session;

  WelcomeCard? get _card => _auth.lastRegistration?.welcome;

  String get fullName {
    final u = _session.user;
    if (u == null) return '';
    return [u.firstName, u.lastName].where((s) => s.isNotEmpty).join(' ');
  }

  String get memberNo => _card?.memberNo ?? '';
  String get levelName => _card?.levelName ?? '';
  String get checkInCode => _card?.checkInCode ?? '';

  /// QR içeriği: kayıtta gelen dinamik jeton (yoksa kullanıcı kimliği).
  String get qrData {
    final token = _card?.qrToken ?? '';
    return token.isNotEmpty ? token : (_session.user?.id ?? '');
  }

  int get onboardingBonus => _card?.onboardingBonus ?? (_auth.onboardingBonusHeld ? _app.current.onboardingBonus : 0);
  int get welcomeBonus => _card?.welcomeBonus ?? _app.current.welcomeBonus;
  int get total => onboardingBonus + welcomeBonus;

  /// "Arkadaşını Davet Et · +2.000 BUAN" — tutar yoksa yalnız başlık gösterilir.
  int get inviteReward => _card?.inviteReward ?? 0;

  /// Tekrar oynat sayacı: görünüm animasyonu baştan başlatır.
  int _replays = 0;
  int get replays => _replays;

  void replay() {
    _replays++;
    notify();
  }
}
