import '../../../../core/base/base_view_model.dart';
import '../../../../core/base/view_state.dart';
import '../../../../core/network/api_result.dart';
import '../../../../core/network/app_exception.dart';
import '../../../../data/models/services/application.dart';
import '../../../../data/repositories/application_repository.dart';
import '../../../../data/repositories/cart_repository.dart';

enum ApplicationsTab { active, past }

/// H5 · Başvurularım: Aktif / Geçmiş filtresi, QR bilet aç-kapa, onaylı iptal.
class ApplicationsViewModel extends LoadableViewModel<List<Application>> {
  ApplicationsViewModel(this._repo, {Clock? now}) : _now = now ?? DateTime.now;

  final ApplicationRepository _repo;
  final Clock _now;

  ApplicationsTab _tab = ApplicationsTab.active;
  String? _openTicketId;
  bool _ticketTouched = false;
  final Set<String> _busy = {};
  int? _activeCount;

  ApplicationsTab get tab => _tab;
  String? get openTicketId => _openTicketId;
  bool isBusy(String id) => _busy.contains(id);

  /// "Aktif · 3" — geçmiş sekmesindeyken son bilinen değer.
  int get activeCount => _activeCount ?? 0;

  List<Application> get visible {
    final all = state.dataOrNull ?? const <Application>[];
    return [for (final a in all) if (a.isActive == (_tab == ApplicationsTab.active)) a];
  }

  @override
  Future<ApiResult<List<Application>>> fetch() => _repo.list(status: _tab.name);

  @override
  bool isEmpty(List<Application> data) => !data.any((a) => a.isActive == (_tab == ApplicationsTab.active));

  @override
  Future<void> load() async {
    await super.load();
    if (isDisposed) return;
    final all = state.dataOrNull;
    if (all != null && _tab == ApplicationsTab.active) _activeCount = all.where((a) => a.isActive).length;
    if (_tab == ApplicationsTab.active && state is ViewEmpty) _activeCount = 0;
    if (!_ticketTouched) _openTicketId = visible.where((a) => a.ticket != null).firstOrNull?.id;
    notify();
  }

  Future<void> setTab(ApplicationsTab t) async {
    if (t == _tab) return;
    _tab = t;
    await load();
  }

  void toggleTicket(String id) {
    _ticketTouched = true;
    _openTicketId = _openTicketId == id ? null : id;
    notify();
  }

  /// Ödeme son tarihine kalan saat (yukarı yuvarlanır); geçtiyse 0.
  int? hoursLeft(Application a) {
    final due = a.paymentDueAt;
    if (due == null) return null;
    final m = due.difference(_now()).inMinutes;
    return m <= 0 ? 0 : (m / 60).ceil();
  }

  /// POST /applications/{id}/cancel. null → başarılı, aksi halde hata.
  Future<AppException?> cancel(String id) async {
    if (_busy.contains(id)) return null;
    _busy.add(id);
    notify();
    final r = await _repo.cancel(id);
    if (isDisposed) return null;
    _busy.remove(id);
    switch (r) {
      case Failure(:final error):
        notify();
        return error;
      case Success(:final data):
        final all = state.dataOrNull ?? const <Application>[];
        final updated = [
          for (final a in all)
            a.id == id ? a.copyWith(status: data.status, couponAmount: data.couponAmount ?? a.couponAmount, canCancel: false, ticket: null) : a,
        ];
        if (_openTicketId == id) _openTicketId = null;
        _activeCount = updated.where((a) => a.isActive).length;
        state = isEmpty(updated) ? const ViewEmpty() : ViewSuccess(updated);
        return null;
    }
  }
}
