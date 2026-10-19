import '../../../core/base/base_view_model.dart';
import '../../../core/base/view_state.dart';
import '../../../core/network/api_result.dart';
import '../../../data/models/events/event_item.dart';
import '../../../data/repositories/event_repository.dart';

/// G1 · Etkinlik listesi: gün şeridi + kategori çipleri + kartlar.
///
/// TODO(varsayım): Liste [windowDays] günlük pencere için tek çağrıyla (`?from=&to=`) alınır;
/// gün ve kategori filtreleri istemcide uygulanır (gün şeridindeki noktalar için tüm pencere
/// gerekir, mock da sorgu parametrelerini yok sayar). Veri büyürse sunucu `?date=&cat=` filtresine geçilir.
class EventListViewModel extends LoadableViewModel<EventFeed> {
  EventListViewModel(this._repo, {DateTime Function()? clock, this.windowDays = 14}) : _clock = clock ?? DateTime.now;

  final EventRepository _repo;
  final DateTime Function() _clock;

  /// TODO(varsayım): Gün şeridi bugünden itibaren 14 gün gösterir.
  final int windowDays;

  DateTime? _selectedDay;
  String? _categoryId;

  /// null → tüm günler.
  DateTime? get selectedDay => _selectedDay;

  /// null → "Tümü".
  String? get categoryId => _categoryId;
  bool get hasFilters => _selectedDay != null || _categoryId != null;

  DateTime get today {
    final n = _clock();
    return DateTime(n.year, n.month, n.day);
  }

  List<DateTime> get days {
    final t = today;
    return List.generate(windowDays, (i) => DateTime(t.year, t.month, t.day + i));
  }

  /// Şeridin üstündeki "Ekim 2026" başlığı.
  DateTime get monthAnchor => _selectedDay ?? today;

  /// Yenileme sürerken de son veri (liste boş görünmesin).
  EventFeed? get _feed => switch (state) {
        ViewLoading(:final previous) => previous,
        final s => s.dataOrNull,
      };

  List<EventCategory> get categories => _feed?.categories ?? const [];

  List<EventItem> get _all => _feed?.items ?? const [];

  /// Filtrelenmiş ve başlangıç saatine göre sıralı etkinlikler.
  List<EventItem> get events {
    final day = _selectedDay;
    final cat = _categoryId;
    return _all
        .where((e) => (day == null || e.occursOn(day)) && (cat == null || e.categoryId == cat))
        .toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  }

  /// Gün şeridindeki nokta: o gün (kategori filtresine bakılmaksızın) etkinlik var mı?
  bool hasEventsOn(DateTime day) => _all.any((e) => e.occursOn(day));

  bool isSelectedDay(DateTime day) {
    final s = _selectedDay;
    return s != null && s.year == day.year && s.month == day.month && s.day == day.day;
  }

  /// Aynı güne tekrar dokunmak seçimi kaldırır (tüm günler).
  void selectDay(DateTime day) {
    _selectedDay = isSelectedDay(day) ? null : DateTime(day.year, day.month, day.day);
    notify();
  }

  /// null → "Tümü".
  void selectCategory(String? id) {
    _categoryId = id == null || id == _categoryId ? null : id;
    notify();
  }

  void clearFilters() {
    _selectedDay = null;
    _categoryId = null;
    notify();
  }

  @override
  Future<ApiResult<EventFeed>> fetch() => _repo.feed(from: today, to: days.last);

  @override
  bool isEmpty(EventFeed data) => data.items.isEmpty;
}
