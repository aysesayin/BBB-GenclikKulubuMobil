import '../../../core/base/base_view_model.dart';
import '../../../core/router/routes.dart';
import '../../../core/session/session_controller.dart';
import '../../../data/repositories/app_repository.dart';

/// A3 · Karşılama / karar: kayıt, giriş ya da misafir olarak gezme.
/// `?from=` (misafir duvarından gelindiyse) girişten sonra dönülecek yol.
class WelcomeViewModel extends BaseViewModel {
  WelcomeViewModel(this._session, this._app, {this.from});

  final SessionController _session;
  final AppRepository _app;
  final String? from;

  /// "100 BUAN seni bekliyor" rozetindeki onboarding bonusu.
  int get bonus => _app.current.onboardingBonus;

  /// Giriş ekranına `from` taşınır.
  String get loginRoute =>
      from == null || from!.isEmpty ? Routes.login : Uri(path: Routes.login, queryParameters: {'from': from}).toString();

  /// Misafir: onboarding bir daha gösterilmez, doğrudan Keşfet.
  Future<String> continueAsGuest() async {
    _session.continueAsGuest();
    await _session.markOnboardingSeen();
    return Routes.home;
  }
}
