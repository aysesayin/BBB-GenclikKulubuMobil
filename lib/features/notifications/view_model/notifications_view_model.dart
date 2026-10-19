import '../../../core/base/base_view_model.dart';
import '../../../core/base/view_state.dart';
import '../../../core/network/api_result.dart';
import '../../../data/models/notifications/app_notification.dart';
import '../../../data/repositories/notification_repository.dart';

/// Gün başlıkları: BUGÜN · DÜN · BU HAFTA · DAHA ÖNCE.
enum NotificationGroup { today, yesterday, thisWeek, earlier }

class NotificationSection {
  const NotificationSection(this.group, this.items);
  final NotificationGroup group;
  final List<AppNotification> items;
}

/// B3 · Bildirim merkezi: kategori filtresi, gün grupları, tümünü okundu yap.
class NotificationsViewModel extends LoadableViewModel<List<AppNotification>> {
  NotificationsViewModel(this._repo, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final NotificationRepository _repo;
  final DateTime Function() _clock;

  NotificationCategory? _category;

  /// null → Tümü.
  NotificationCategory? get category => _category;

  bool _readingAll = false;
  bool get readingAll => _readingAll;

  DateTime get now => _clock();

  @override
  Future<ApiResult<List<AppNotification>>> fetch() => _repo.list(category: _category);

  void selectCategory(NotificationCategory? value) {
    if (_category == value) return;
    _category = value;
    load();
  }

  /// Seçili kategoriye göre (mock sorguyu yok saydığı için istemcide de süzülür).
  List<AppNotification> get visible {
    final all = state.dataOrNull ?? const <AppNotification>[];
    return _category == null ? all : all.where((n) => n.category == _category).toList();
  }

  List<NotificationSection> get sections {
    final now = _clock();
    final map = <NotificationGroup, List<AppNotification>>{};
    for (final n in visible) {
      map.putIfAbsent(groupOf(n.createdAt, now), () => []).add(n);
    }
    return [
      for (final g in NotificationGroup.values)
        if (map[g] case final items?) NotificationSection(g, items),
    ];
  }

  bool get hasUnread => (state.dataOrNull ?? const []).any((n) => n.unread);

  /// İyimser güncelleme; sunucu hatasında eski liste geri yüklenir. Başarı → true.
  Future<bool> readAll() async {
    final before = state;
    final data = before.dataOrNull;
    if (data == null || !hasUnread || _readingAll) return false;
    _readingAll = true;
    _replace(before, [for (final n in data) n.copyWith(unread: false)]);
    final r = await _repo.readAll();
    _readingAll = false;
    if (isDisposed) return false;
    if (r is Failure) {
      state = before;
      return false;
    }
    notify();
    return true;
  }

  /// Satır açıldığında yerelde okundu işaretlenir.
  // TODO(varsayım): Tek bildirim için "okundu" uç noktası yok; sunucu satır açılışını ayrıca izlemiyor varsayıldı.
  void markRead(String id) {
    final data = state.dataOrNull;
    if (data == null) return;
    _replace(state, [for (final n in data) n.id == id ? n.copyWith(unread: false) : n]);
  }

  void _replace(ViewState<List<AppNotification>> from, List<AppNotification> next) {
    state = switch (from) {
      ViewSuccess(:final fromCache) => ViewSuccess(next, fromCache: fromCache),
      ViewError(:final error) => ViewError(error, cached: next),
      _ => ViewSuccess(next),
    };
  }

  static NotificationGroup groupOf(DateTime t, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return NotificationGroup.today;
    if (diff == 1) return NotificationGroup.yesterday;
    if (diff < 7) return NotificationGroup.thisWeek;
    return NotificationGroup.earlier;
  }
}
