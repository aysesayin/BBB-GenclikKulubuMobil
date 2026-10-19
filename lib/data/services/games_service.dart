import '../../core/network/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../models/games/game.dart';

/// F · Oyunlar uç noktaları.
class GamesService {
  GamesService(this._client);

  final DioClient _client;

  Future<ApiResult<List<Game>>> games() => _client.get(ApiEndpoints.games, parse: (d) => Json.list(d, Game.fromJson), cacheKey: 'games');

  Future<ApiResult<Tournament?>> tournament() =>
      _client.get(ApiEndpoints.gameTournament, parse: (d) => d == null ? null : Tournament.fromJson(Json.map(d)), cacheKey: 'games.tournament');

  /// Oyun yalnız ham ilerlemeyi bildirir; BUAN sunucuda hesaplanır.
  Future<ApiResult<GameScoreResult>> submitScore(String gameId, {required int moves, required int durationMs, required String sessionId}) =>
      _client.post(
        ApiEndpoints.submitGameScore(gameId),
        parse: (d) => GameScoreResult.fromJson(Json.map(d)),
        body: {'moves': moves, 'durationMs': durationMs, 'sessionId': sessionId},
        headers: {'Idempotency-Key': sessionId},
      );
}
