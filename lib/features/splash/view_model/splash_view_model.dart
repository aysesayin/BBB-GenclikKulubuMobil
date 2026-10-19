import '../../../core/base/base_view_model.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/router/routes.dart';
import '../../../core/session/session_controller.dart';
import '../../../data/repositories/app_repository.dart';

enum SplashPhase { loading, maintenance, ready }

/// A1 · Açılış: oturumu geri yükler + uzak yapılandırmayı çeker, sonra
/// gidilecek yolu belirler: onboarding görülmediyse hikâye, üye ise Keşfet,
/// değilse karşılama. Bakım modunda bekleme ekranı.
class SplashViewModel extends BaseViewModel {
  SplashViewModel(this._session, this._app);

  final SessionController _session;
  final AppRepository _app;

  SplashPhase _phase = SplashPhase.loading;
  SplashPhase get phase => _phase;

  String? _destination;

  /// [phase] `ready` olduğunda gidilecek yol.
  String? get destination => _destination;

  String? _maintenanceMessage;

  /// Panelden gelen bakım mesajı (yoksa görünüm genel metni gösterir).
  String? get maintenanceMessage => _maintenanceMessage;

  Future<void> start() async {
    _phase = SplashPhase.loading;
    notify();
    final restoring = _session.restore();
    final config = await _app.fetchConfig();
    await restoring;
    if (isDisposed) return;

    final maintenance = switch (config) {
      Failure(:final MaintenanceException error) => (true, error.serverMessage),
      _ => (false, null),
    };
    final current = config.dataOrNull ?? _app.current;
    if (maintenance.$1 || current.maintenance) {
      _maintenanceMessage = maintenance.$2 ?? current.maintenanceMessage;
      _phase = SplashPhase.maintenance;
      notify();
      return;
    }
    // TODO(varsayım): minVersion (zorunlu güncelleme) kontrolü package_info_plus ile
    // mağaza bağlantıları belli olunca eklenecek.
    _destination = !_session.onboardingSeen
        ? Routes.onboarding
        : (_session.isAuthenticated ? Routes.home : Routes.welcome);
    _phase = SplashPhase.ready;
    notify();
  }
}
