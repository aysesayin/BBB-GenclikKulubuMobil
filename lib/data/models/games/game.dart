import 'package:freezed_annotation/freezed_annotation.dart';

part 'game.freezed.dart';
part 'game.g.dart';

/// Oyun türü — ikon ve açılış davranışını belirler.
enum GameKind {
  @JsonValue('quiz')
  quiz,
  @JsonValue('whereIsIt')
  whereIsIt,
  @JsonValue('memory')
  memory,
  @JsonValue('other')
  other,
}

/// `GET /games` öğesi.
@freezed
abstract class Game with _$Game {
  const factory Game({
    required String id,
    required String title,
    @Default('') String description,
    @Default(GameKind.other) GameKind kind,
    @Default(0) int reward,

    /// Günlük hak (null → sınırsız pratik).
    int? playsPerDay,
    @Default(0) int playsLeft,
  }) = _Game;

  factory Game.fromJson(Map<String, dynamic> json) => _$GameFromJson(json);
}

/// `GET /games/tournament/current`.
@freezed
abstract class Tournament with _$Tournament {
  const factory Tournament({
    required String id,
    required String title,
    required String gameId,
    required int totalPrize,
    @Default(10) int winnerCount,
    required DateTime endsAt,
    int? rank,
    @Default(0) int participants,
  }) = _Tournament;

  factory Tournament.fromJson(Map<String, dynamic> json) => _$TournamentFromJson(json);
}

/// `POST /games/{id}/score` yanıtı — puan sunucuda hesaplanır.
@freezed
abstract class GameScoreResult with _$GameScoreResult {
  const factory GameScoreResult({@Default(0) int awarded, int? rank}) = _GameScoreResult;

  factory GameScoreResult.fromJson(Map<String, dynamic> json) => _$GameScoreResultFromJson(json);
}
