import '../../../../core/base/base_view_model.dart';
import '../../../../core/network/api_result.dart';
import '../../../../data/models/buan/buan_reward.dart';
import '../../../../data/repositories/buan_repository.dart';

/// E2 · BUAN Pazar: kategori + "Bakiyen yetiyor" filtreleri istemci tarafında da
/// uygulanır (mock sorgu parametrelerini yok sayar).
class MarketViewModel extends LoadableViewModel<BuanMarket> {
  MarketViewModel(this._repo) {
    _repo.balance.addListener(notify);
  }

  final BuanRepository _repo;

  String? _categoryId;
  bool _affordableOnly = false;

  /// null → "Tümü".
  String? get categoryId => _categoryId;
  bool get affordableOnly => _affordableOnly;
  int get balance => _repo.balance.value ?? 0;

  @override
  Future<ApiResult<BuanMarket>> fetch() async {
    final market = _repo.market();
    if (_repo.balance.value == null) await _repo.wallet();
    return market;
  }

  List<BuanRewardCategory> get categories => state.dataOrNull?.categories ?? const [];

  /// Büyük ödül (hero). Yoksa null.
  BuanReward? get featured {
    final items = state.dataOrNull?.items ?? const <BuanReward>[];
    for (final r in items) {
      if (r.featured) return r;
    }
    return null;
  }

  List<BuanReward> get visibleItems => (state.dataOrNull?.items ?? const <BuanReward>[])
      .where((r) => _categoryId == null || r.categoryId == _categoryId)
      .where((r) => !_affordableOnly || canAfford(r))
      .toList();

  bool canAfford(BuanReward r) => r.price <= balance;

  void selectCategory(String? id) {
    if (_categoryId == id) return;
    _categoryId = id;
    notify();
  }

  void setAffordableOnly(bool value) {
    if (_affordableOnly == value) return;
    _affordableOnly = value;
    notify();
  }

  void clearFilters() {
    _categoryId = null;
    _affordableOnly = false;
    notify();
  }

  @override
  void dispose() {
    _repo.balance.removeListener(notify);
    super.dispose();
  }
}
