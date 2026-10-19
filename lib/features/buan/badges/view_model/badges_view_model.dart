import '../../../../core/base/base_view_model.dart';
import '../../../../core/network/api_result.dart';
import '../../../../data/models/buan/buan_badge.dart';
import '../../../../data/repositories/buan_repository.dart';

/// E5 · Rozetler: kazanılanlar önce, sonra kilitliler (sunucu sırası korunur).
class BadgesViewModel extends LoadableViewModel<List<BuanBadge>> {
  BadgesViewModel(this._repo);

  final BuanRepository _repo;

  @override
  Future<ApiResult<List<BuanBadge>>> fetch() async =>
      (await _repo.badges()).map((list) => [...list.where((b) => b.earned), ...list.where((b) => !b.earned)]);

  @override
  bool isEmpty(List<BuanBadge> data) => data.isEmpty;

  List<BuanBadge> get badges => state.dataOrNull ?? const [];
  int get earnedCount => badges.where((b) => b.earned).length;
  int get total => badges.length;
  double get progress => total == 0 ? 0 : earnedCount / total;
}
