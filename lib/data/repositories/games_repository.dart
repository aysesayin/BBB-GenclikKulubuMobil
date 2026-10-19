import '../../core/network/api_result.dart';
import '../models/games/game.dart';
import '../services/games_service.dart';

abstract interface class GamesRepository {
  Future<ApiResult<List<Game>>> games();

  /// Aktif turnuva yoksa `Success(null)`.
  Future<ApiResult<Tournament?>> tournament();
  Future<ApiResult<GameScoreResult>> submitScore(String gameId, {required int moves, required int durationMs, required String sessionId});
}

class GamesRepositoryImpl implements GamesRepository {
  GamesRepositoryImpl(this._s);
  final GamesService _s;

  @override
  Future<ApiResult<List<Game>>> games() => _s.games();
  @override
  Future<ApiResult<Tournament?>> tournament() => _s.tournament();
  @override
  Future<ApiResult<GameScoreResult>> submitScore(String gameId, {required int moves, required int durationMs, required String sessionId}) =>
      _s.submitScore(gameId, moves: moves, durationMs: durationMs, sessionId: sessionId);
}
