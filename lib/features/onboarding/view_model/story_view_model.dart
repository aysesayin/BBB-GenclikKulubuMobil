import '../../../core/base/base_view_model.dart';
import '../../../data/repositories/app_repository.dart';
import '../../../data/repositories/auth_repository.dart';

/// A2 · 2 × 6 sn hikâye (şehir → coin). Sağa dokun ileri, sola geri, basılı tut duraklat.
/// Son hikâyede coin'e dokunmak onboarding bonusunu cihazda bekletir
/// (kayıtta hesaba aktarılır). İlk hikâyedeki "Hemen Başla" doğrudan karşılamaya götürür.
class StoryViewModel extends BaseViewModel {
  StoryViewModel(this._auth, this._app) : _coinPopped = _auth.onboardingBonusHeld;

  final AuthRepository _auth;
  final AppRepository _app;

  static const count = 2;
  static const segment = Duration(seconds: 6);

  int _index = 0;
  int get index => _index;
  bool get isLast => _index == count - 1;

  bool _paused = false;
  bool get paused => _paused;

  bool _coinPopped;
  bool get coinPopped => _coinPopped;

  /// Panelden gelen onboarding bonusu (BUAN).
  int get bonus => _app.current.onboardingBonus;

  /// Devam yalnız coin'e dokunduktan sonra (Atla / Hemen Başla her zaman açık).
  bool get canFinish => _coinPopped;

  void next() => goTo(_index + 1);
  void prev() => goTo(_index - 1);

  void goTo(int i) {
    final n = i.clamp(0, count - 1);
    if (n == _index) return;
    _index = n;
    _paused = false;
    notify();
  }

  /// Segment süresi doldu: son hikâyede beklenir.
  void onSegmentDone() {
    if (!isLast) next();
  }

  void setPaused({required bool value}) {
    if (_paused == value) return;
    _paused = value;
    notify();
  }

  Future<void> popCoin() async {
    if (_coinPopped) return;
    _coinPopped = true;
    notify();
    await _auth.holdOnboardingBonus();
  }
}
