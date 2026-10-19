import '../../../core/base/base_view_model.dart';
import '../../../core/network/api_result.dart';
import '../../../data/models/games/game.dart';
import '../../../data/repositories/games_repository.dart';

/// Oyun merkezi verisi: oyunlar + (varsa) haftalık turnuva.
class GamesHub {
  const GamesHub({required this.games, this.tournament});
  final List<Game> games;
  final Tournament? tournament;
}

/// F1 · Oyunlar. Turnuva alınamazsa liste yine gösterilir.
class GamesViewModel extends LoadableViewModel<GamesHub> {
  GamesViewModel(this._repo);

  final GamesRepository _repo;

  @override
  Future<ApiResult<GamesHub>> fetch() async {
    final gamesF = _repo.games();
    final tournamentF = _repo.tournament();
    final games = await gamesF;
    final tournament = (await tournamentF).dataOrNull;
    return switch (games) {
      Success(:final data, :final fromCache) => Success(
        GamesHub(games: data, tournament: tournament),
        fromCache: fromCache,
      ),
      Failure(:final error, :final cached) => Failure(
        error,
        cached: cached == null ? null : GamesHub(games: cached, tournament: tournament),
      ),
    };
  }

  @override
  bool isEmpty(GamesHub data) => data.games.isEmpty && data.tournament == null;

  Game? gameById(String id) {
    for (final g in state.dataOrNull?.games ?? const <Game>[]) {
      if (g.id == id) return g;
    }
    return null;
  }
}
