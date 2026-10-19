import '../../../../core/base/base_view_model.dart';
import '../../../../core/network/api_result.dart';
import '../../../../data/models/services/sports.dart';
import '../../../../data/repositories/facility_repository.dart';

enum QuotaLevel { plenty, last, full, none }

/// Branş kartında gösterilecek grup + kontenjan seviyesi.
class BranchTile {
  const BranchTile(this.branch, this.offer);

  final SportBranch branch;

  /// Seçili dönem + yaş grubundaki grup; yoksa null.
  final BranchOffer? offer;

  QuotaLevel get level => quotaLevelOf(offer?.left);
}

// TODO(varsayım): "Son N" eşiği 3 yer; panelden gelirse API değeri kullanılmalı.
const lastSpotsThreshold = 3;

QuotaLevel quotaLevelOf(int? left) => switch (left) {
      null => QuotaLevel.none,
      0 => QuotaLevel.full,
      final n when n <= lastSpotsThreshold => QuotaLevel.last,
      _ => QuotaLevel.plenty,
    };

/// H4 · Spor Okulları: dönem → yaş grubu filtresi → branş ızgarası (+ Tenis sekmesi).
class SportsSchoolViewModel extends LoadableViewModel<SportsCatalog> {
  SportsSchoolViewModel(this._repo);

  final FacilityRepository _repo;

  int _tab = 0;
  String? _termId;
  String? _ageGroupId;

  /// 0 → Spor Okulları, 1 → Tenis.
  int get tab => _tab;
  String? get termId => _termId;
  String? get ageGroupId => _ageGroupId;
  List<SportTerm> get terms => state.dataOrNull?.terms ?? const [];
  List<AgeGroup> get ageGroups => state.dataOrNull?.ageGroups ?? const [];

  @override
  Future<ApiResult<SportsCatalog>> fetch() => _repo.sportsCatalog();

  @override
  Future<void> load() async {
    await super.load();
    if (isDisposed || state.dataOrNull == null) return;
    if (!terms.any((t) => t.id == _termId)) _termId = terms.firstOrNull?.id;
    if (!ageGroups.any((a) => a.id == _ageGroupId)) _ageGroupId = ageGroups.firstOrNull?.id;
    notify();
  }

  void setTab(int i) {
    if (i == _tab) return;
    _tab = i;
    notify();
  }

  void selectTerm(String id) {
    _termId = id;
    notify();
  }

  void selectAgeGroup(String id) {
    _ageGroupId = id;
    notify();
  }

  List<BranchTile> get branches => [
        for (final b in state.dataOrNull?.branches ?? const <SportBranch>[])
          BranchTile(b, b.offers.where((o) => o.termId == _termId && o.ageGroupId == _ageGroupId).firstOrNull),
      ];
}
