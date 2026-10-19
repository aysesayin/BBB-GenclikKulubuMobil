import '../../../../core/base/base_view_model.dart';
import '../../../../core/base/view_state.dart';
import '../../../../core/network/api_result.dart';
import '../../../../data/models/services/facility.dart';
import '../../../../data/repositories/facility_repository.dart';

/// H1 · Havuzlar: havuz seçimi + seçili havuzun hizmet kalemleri.
class PoolsViewModel extends LoadableViewModel<PoolCatalog> {
  PoolsViewModel(this._repo);

  final FacilityRepository _repo;

  String? _selectedId;
  ViewState<List<ServiceItem>> _items = const ViewIdle();
  int _request = 0;

  String? get selectedId => _selectedId;
  ViewState<List<ServiceItem>> get items => _items;

  Pool? get selectedPool {
    final pools = state.dataOrNull?.items ?? const <Pool>[];
    for (final p in pools) {
      if (p.id == _selectedId) return p;
    }
    return null;
  }

  @override
  Future<ApiResult<PoolCatalog>> fetch() => _repo.pools();

  @override
  bool isEmpty(PoolCatalog data) => data.items.isEmpty;

  @override
  Future<void> load() async {
    await super.load();
    final pools = state.dataOrNull?.items ?? const <Pool>[];
    if (pools.isEmpty || isDisposed) return;
    if (!pools.any((p) => p.id == _selectedId)) _selectedId = pools.first.id;
    await loadItems();
  }

  Future<void> select(String id) async {
    if (id == _selectedId) return;
    _selectedId = id;
    notify();
    await loadItems();
  }

  Future<void> loadItems() async {
    final id = _selectedId;
    if (id == null) return;
    final request = ++_request;
    _items = const ViewLoading();
    notify();
    final result = await _repo.items(id);
    if (isDisposed || request != _request) return;
    _items = switch (result) {
      Success(:final data, :final fromCache) => data.isEmpty ? const ViewEmpty() : ViewSuccess(data, fromCache: fromCache),
      Failure(:final error, :final cached) => ViewError(error, cached: cached),
    };
    notify();
  }
}
