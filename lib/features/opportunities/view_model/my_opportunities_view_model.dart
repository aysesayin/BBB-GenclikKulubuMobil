import '../../../core/base/base_view_model.dart';
import '../../../core/network/api_result.dart';
import '../../../data/models/opportunities/claim.dart';
import '../../../data/repositories/opportunity_repository.dart';

/// C4 · Fırsatlarım (cüzdan): Aktif / Kullanıldı / Süresi doldu.
class MyOpportunitiesViewModel extends LoadableViewModel<List<WalletItem>> {
  MyOpportunitiesViewModel(this._repo);

  final OpportunityRepository _repo;

  static const segments = [WalletStatus.active, WalletStatus.used, WalletStatus.expired];

  int _tab = 0;
  int get tab => _tab;
  WalletStatus get status => segments[_tab];

  @override
  Future<ApiResult<List<WalletItem>>> fetch() => _repo.mine();

  List<WalletItem> itemsOf(WalletStatus s) => (state.dataOrNull ?? const []).where((w) => w.status == s).toList();

  List<WalletItem> get items => itemsOf(status);

  int countOf(WalletStatus s) => itemsOf(s).length;

  void selectTab(int i) {
    if (i == _tab || i < 0 || i >= segments.length) return;
    _tab = i;
    notify();
  }
}
