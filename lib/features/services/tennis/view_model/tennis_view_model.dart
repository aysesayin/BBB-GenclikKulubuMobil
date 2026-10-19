import '../../../../core/base/base_view_model.dart';
import '../../../../core/network/api_result.dart';
import '../../../../data/models/services/sports.dart';
import '../../../../data/repositories/facility_repository.dart';

/// H4 · Tenis: özel ders, açık/kapalı/toprak kort, yetişkin kursu, takım akademisi, pickleball, kort kirası.
class TennisViewModel extends LoadableViewModel<List<TennisProduct>> {
  TennisViewModel(this._repo);

  final FacilityRepository _repo;

  @override
  Future<ApiResult<List<TennisProduct>>> fetch() => _repo.tennisProducts();

  @override
  bool isEmpty(List<TennisProduct> data) => data.isEmpty;

  /// Yaş grubuna uygun ürünler (ürünün yaş listesi boşsa herkese açık).
  List<TennisProduct> visible(String? ageGroupId) => [
        for (final p in state.dataOrNull ?? const <TennisProduct>[])
          if (ageGroupId == null || p.ageGroupIds.isEmpty || p.ageGroupIds.contains(ageGroupId)) p,
      ];
}
