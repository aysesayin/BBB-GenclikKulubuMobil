import '../../../../core/base/base_view_model.dart';
import '../../../../core/network/api_result.dart';
import '../../../../data/models/buan/buan_league.dart';
import '../../../../data/repositories/buan_repository.dart';
import '../../widgets/buan_ui.dart';

enum LeagueZone { promotion, safe, relegation }

/// E4 · Haftalık lig. Kapsam (Genel / İlçe / Arkadaşlar) sunucuya sorgu olarak
/// gider; yanıt istenen kapsama ait değilse (mock) istemci süzer ve yeniden sıralar.
class LeagueViewModel extends LoadableViewModel<BuanLeague> {
  LeagueViewModel(this._repo);

  final BuanRepository _repo;

  BuanLeagueScope _scope = BuanLeagueScope.global;
  String? _districtId;

  BuanLeagueScope get scope => _scope;

  /// İlçe kapsamında seçili ilçe (varsayılan: kullanıcının ilçesi).
  String? get districtId => _districtId;

  @override
  Future<ApiResult<BuanLeague>> fetch() async {
    final res = await _repo.leaderboard(scope: _scope, districtId: _scope == BuanLeagueScope.district ? districtId : null);
    return res.map(_localize);
  }

  Future<void> setScope(BuanLeagueScope s) async {
    if (s == _scope) return;
    _scope = s;
    await load();
  }

  Future<void> setDistrict(String id) async {
    if (id == districtId && _scope == BuanLeagueScope.district) return;
    _districtId = id;
    await load();
  }

  BuanLeague _localize(BuanLeague data) {
    _districtId ??= data.districtId;
    final sorted = [...data.entries]..sort((a, b) => b.points.compareTo(a.points));
    var list = sorted.map((e) => e.copyWith(name: kvkkShortName(e.name))).toList();
    final localFiltered = data.scope != _scope;
    if (localFiltered) {
      final d = districtId;
      list = switch (_scope) {
        BuanLeagueScope.global => list,
        BuanLeagueScope.friends => list.where((e) => e.isFriend || e.isMe).toList(),
        BuanLeagueScope.district => list.where((e) => d == null || e.districtId == d).toList(),
      };
      list = [for (var i = 0; i < list.length; i++) list[i].copyWith(rank: i + 1)];
    }
    final me = data.me?.copyWith(name: kvkkShortName(data.me!.name));
    final meRanked = list.where((e) => e.isMe).firstOrNull;
    return data.copyWith(entries: list, scope: _scope, me: localFiltered ? meRanked : (meRanked ?? me));
  }

  List<BuanLeagueEntry> get entries => state.dataOrNull?.entries ?? const [];

  /// Podyum: ilk üç (1., 2., 3. sırada).
  List<BuanLeagueEntry> get podium => entries.take(3).toList();
  List<BuanLeagueEntry> get rest => entries.skip(3).toList();
  BuanLeagueEntry? get me => state.dataOrNull?.me;

  /// Bölgeler yalnız Genel kapsamda anlamlıdır (lig grubu).
  bool get showZones => _scope == BuanLeagueScope.global && (state.dataOrNull?.promoteCount ?? 0) > 0;

  LeagueZone? zoneOf(int rank) {
    final d = state.dataOrNull;
    if (d == null || !showZones) return null;
    if (rank <= d.promoteCount) return LeagueZone.promotion;
    if (d.relegateCount > 0 && rank > entries.length - d.relegateCount) return LeagueZone.relegation;
    return LeagueZone.safe;
  }

  /// Bu satırın üstüne bölge başlığı çizilmeli mi? (podyum sonrası ilk satır ve bölge geçişleri)
  LeagueZone? zoneHeaderBefore(int index) {
    final list = rest;
    final z = zoneOf(list[index].rank);
    if (z == null) return null;
    if (index == 0) return z;
    return zoneOf(list[index - 1].rank) == z ? null : z;
  }

  bool get inPromotion => me != null && zoneOf(me!.rank) == LeagueZone.promotion;

  /// Seçili ilçenin adı.
  String? get districtName {
    final d = state.dataOrNull;
    final id = districtId;
    if (d == null || id == null) return null;
    return d.districts.where((x) => x.id == id).firstOrNull?.name;
  }
}
