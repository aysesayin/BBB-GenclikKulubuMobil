import '../../../core/base/base_view_model.dart';
import '../../../core/router/routes.dart';
import '../../../core/session/session_controller.dart';
import '../permission_gateway.dart';

/// A8 · İzin kartı destesi. Her kart "İzin Ver" (sağa fırlar → OS istemi) ya da
/// "Şimdi değil" (sola fırlar). Bitince "Hazırsın!" → İlk günün listesi.
class PermissionsViewModel extends BaseViewModel {
  PermissionsViewModel(this._gateway, this._session);

  final PermissionGateway _gateway;
  final SessionController _session;

  static const cards = OnbPermission.values;

  /// Kart kararı: true → izin verildi, false → şimdi değil / reddedildi.
  final Map<OnbPermission, bool> _results = {};

  /// Fırlatma yönü (görünüm animasyonu): true → sağ.
  final Map<OnbPermission, bool> _flungRight = {};

  bool _busy = false;
  bool get busy => _busy;

  /// Sıradaki (üstteki) kartın indeksi; hepsi bittiyse [cards.length].
  int get current {
    final i = cards.indexWhere((c) => !_flungRight.containsKey(c));
    return i < 0 ? cards.length : i;
  }

  bool get done => current >= cards.length;
  int get granted => _results.values.where((v) => v).length;

  bool? flungRight(OnbPermission p) => _flungRight[p];
  bool? result(OnbPermission p) => _results[p];

  Future<void> allow() async {
    if (done || _busy) return;
    final p = cards[current];
    _flungRight[p] = true;
    _busy = true;
    notify();
    // Kart önce fırlar, OS diyaloğu ardından gelir.
    final ok = await _gateway.request(p);
    _results[p] = ok;
    _busy = false;
    notify();
  }

  void skip() {
    if (done || _busy) return;
    final p = cards[current];
    _flungRight[p] = false;
    _results[p] = false;
    notify();
  }

  /// "Şehre çık": onboarding tamamlandı → İlk günün kontrol listesi.
  Future<String> finish() async {
    // TODO(varsayım): İzin tercihleri /users/me/preferences'a profil özelliği yazacak; burada yalnız OS izni istenir.
    await _session.markOnboardingSeen();
    return Routes.firstDay;
  }
}
