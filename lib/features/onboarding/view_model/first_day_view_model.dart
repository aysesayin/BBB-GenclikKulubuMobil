import '../../../core/base/base_view_model.dart';
import '../../../core/network/api_result.dart';
import '../../../core/router/routes.dart';
import '../../../core/session/session_controller.dart';
import '../../../data/models/auth/first_day_task.dart';
import '../../../data/repositories/auth_repository.dart';

/// A9 · "İlk günün": kayıt sonrası 3 görevlik kontrol listesi (`GET /auth/first-day`).
/// Tamamlanma durumu cihazda tutulur (`user.firstDay.<id>`); "Keşfet'e geç" onboarding'i kapatır.
class FirstDayViewModel extends LoadableViewModel<List<FirstDayTask>> {
  FirstDayViewModel(this._auth, this._session);

  final AuthRepository _auth;
  final SessionController _session;

  /// Sekme kökleri `go` ile açılır (alt navigasyon), diğer yollar `push` ile üstte açılır.
  static const _tabRoots = {Routes.home, Routes.opportunities, Routes.card, Routes.buan, Routes.profile};

  int _doneTick = 0;

  List<FirstDayTask> get tasks => state.dataOrNull ?? const [];
  int get totalReward => tasks.fold(0, (sum, t) => sum + t.reward);
  int get doneCount => tasks.where((t) => isDone(t.id)).length;
  bool get allDone => tasks.isNotEmpty && doneCount == tasks.length;

  bool isDone(String id) => _auth.isFirstDayDone(id);

  /// Görünüm yeniden çizimi için (cihaz kaydı senkron okunur).
  int get doneTick => _doneTick;

  @override
  Future<ApiResult<List<FirstDayTask>>> fetch() => _auth.firstDayTasks();

  @override
  bool isEmpty(List<FirstDayTask> data) => data.isEmpty;

  /// Satıra dokunuldu: görev cihazda "yapıldı" sayılır, hedef yol döner.
  /// TODO(varsayım): Gerçek tamamlanma (fırsat yakalandı, QR okundu, davet kabul edildi) sunucu
  /// /buan/tasks ile raporladığında oradan okunacak; şimdilik dokunmak yeterli.
  Future<String> open(FirstDayTask task) async {
    await _auth.markFirstDayDone(task.id);
    _doneTick++;
    notify();
    return task.route.isEmpty ? Routes.home : task.route;
  }

  /// true → `context.go` (sekme kökü), false → `context.push`.
  static bool isTabRoute(String route) => _tabRoots.contains(route);

  /// "Keşfet'e geç": onboarding tamamlandı.
  Future<String> finish() async {
    await _session.markOnboardingSeen();
    return Routes.home;
  }
}
