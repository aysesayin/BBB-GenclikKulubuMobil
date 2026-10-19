import '../../../core/base/base_view_model.dart';
import '../../../core/base/view_state.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/app_exception.dart';
import '../../../data/models/opportunities/claim.dart';
import '../../../data/repositories/opportunity_repository.dart';

/// C3 · Fırsat yakalandı. Sonuç GoRouter `extra` ile gelir; yoksa (deep link,
/// uygulama yeniden açıldı) cüzdandan aktif kod yeniden çekilir.
class ClaimedViewModel extends LoadableViewModel<ClaimResult> {
  ClaimedViewModel(this._repo, this.opportunityId, {ClaimResult? initial, bool fresh = true}) : celebrate = initial != null && fresh {
    if (initial != null) state = ViewSuccess(initial);
  }

  final OpportunityRepository _repo;
  final String opportunityId;

  /// Taze yakalamada konfeti + toast; cüzdandan açılışta yok.
  final bool celebrate;

  bool _copied = false;
  bool get copied => _copied;

  @override
  Future<void> load() async {
    if (state is ViewSuccess<ClaimResult>) return;
    await super.load();
  }

  @override
  Future<ApiResult<ClaimResult>> fetch() async {
    final r = await _repo.mine();
    return switch (r) {
      Success(:final data, :final fromCache) =>
        _find(data) == null ? const Failure(NotFoundException()) : Success(_find(data)!, fromCache: fromCache),
      Failure(:final error, :final cached) => Failure(error, cached: cached == null ? null : _find(cached)),
    };
  }

  ClaimResult? _find(List<WalletItem> items) => items
      .where((w) => w.opportunityId == opportunityId && w.status == WalletStatus.active && w.claim != null)
      .map((w) => w.claim!)
      .firstOrNull;

  void markCopied() {
    _copied = true;
    notify();
  }
}
