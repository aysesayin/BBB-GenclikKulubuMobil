import '../../../../../core/base/base_view_model.dart';
import '../../../../../core/base/view_state.dart';
import '../../../../../core/network/api_endpoints.dart';
import '../../../../../core/network/api_result.dart';
import '../../../../../core/network/app_exception.dart';
import '../../../../../core/router/routes.dart';
import '../../../../../data/models/buan/buan_task.dart';
import '../../../../../data/repositories/buan_repository.dart';

/// Genel görev detayındaki ana eylem türü.
enum TaskPrimaryAction {
  /// "Takip ettim, beyan et" → `POST complete {declared: true}` → panel onayı bekler.
  declare,

  /// "Başvur" → `POST complete` → panel onayı bekler.
  apply,

  /// Dış BİKO sitesi (url_launcher).
  openBiko,

  /// Çek Kazan ekranının "Fikir" sekmesi.
  openIdea,

  /// Fırsatlar sekmesi.
  openOpportunities,

  /// Eylem yok (bilinmeyen tür / kilitli / tamamlanmış).
  none,
}

/// Genel görev detayı (Takip Et, Gönül Dostu, BİKO, Fikrin ile Kazan, Fırsat Kullan ve
/// bilinmeyen türler). Görev `/buan/tasks` listesinden id ile bulunur; ayrı uç nokta yok.
class TaskDetailViewModel extends LoadableViewModel<BuanTask> {
  TaskDetailViewModel(this._repo, {required this.taskId});

  /// Çek Kazan ekranını "Fikir" sekmesinde açan sorgu (`/buan/cek?tur=idea`).
  // TODO(varsayım): Fikir türünün API id'si `idea` (photo-reports.types.json ile aynı).
  static const ideaTypeId = 'idea';
  static const ideaRoute = '${Routes.photoReport}?tur=$ideaTypeId';

  final BuanRepository _repo;
  final String taskId;

  bool _submitting = false;
  AppException? _error;

  bool get submitting => _submitting;
  AppException? get error => _error;

  BuanTask? get task => state.dataOrNull;

  /// Dış bağlantı: yalnız api_endpoints'ten.
  Uri get bikoUri => Uri.parse(ApiEndpoints.bikoUrl);

  TaskPrimaryAction get primaryAction {
    final t = task;
    if (t == null || t.isLocked || t.isDone || t.status == BuanTaskStatus.pending) return TaskPrimaryAction.none;
    return switch (t.type) {
      BuanTaskType.follow => TaskPrimaryAction.declare,
      BuanTaskType.volunteer => TaskPrimaryAction.apply,
      BuanTaskType.biko => TaskPrimaryAction.openBiko,
      BuanTaskType.idea => TaskPrimaryAction.openIdea,
      BuanTaskType.useOpportunity => TaskPrimaryAction.openOpportunities,
      _ => TaskPrimaryAction.none,
    };
  }

  @override
  Future<ApiResult<BuanTask>> fetch() async {
    final r = await _repo.tasks();
    return switch (r) {
      Failure(:final error) => Failure(error),
      Success(:final data, :final fromCache) => () {
        for (final g in data) {
          for (final t in g.tasks) {
            if (t.id == taskId) return Success(t, fromCache: fromCache);
          }
        }
        return const Failure<BuanTask>(NotFoundException());
      }(),
    };
  }

  /// Beyan (Takip Et) ya da başvuru (Gönül Dostu). Başarılıysa görev durumu
  /// sunucunun döndürdüğü duruma (genelde `pending`) geçer; puan panel onayıyla yüklenir.
  Future<bool> complete() async {
    final t = task;
    if (t == null || _submitting) return false;
    _submitting = true;
    _error = null;
    notify();
    final r = await _repo.completeTask(t.id, declared: t.type == BuanTaskType.follow);
    if (isDisposed) return false;
    _submitting = false;
    switch (r) {
      case Success(:final data):
        state = ViewSuccess(t.copyWith(status: data.status));
        return true;
      case Failure(:final error):
        _error = error;
        notify();
        return false;
    }
  }

  void clearError() {
    _error = null;
    notify();
  }
}
