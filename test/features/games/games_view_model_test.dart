import 'dart:math' as math;

import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/games/game.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/games_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/games/view_model/games_view_model.dart';
import 'package:bbb_genclik_kulubu_app/features/games/view_model/memory_game_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements GamesRepository {}

void main() {
  late _Repo repo;
  const games = [Game(id: 'g1', title: 'Bilgi', kind: GameKind.quiz), Game(id: 'g2', title: 'Hafıza', kind: GameKind.memory)];
  final tournament = Tournament(id: 't', title: 'Turnuva', gameId: 'g1', totalPrize: 5000, endsAt: DateTime(2026, 10, 19));

  setUp(() => repo = _Repo());

  group('GamesViewModel', () {
    test('oyunlar + turnuva', () async {
      when(() => repo.games()).thenAnswer((_) async => const Success(games));
      when(() => repo.tournament()).thenAnswer((_) async => Success(tournament));
      final vm = GamesViewModel(repo);
      await vm.load();
      expect(vm.state.dataOrNull!.games, games);
      expect(vm.state.dataOrNull!.tournament, tournament);
      expect(vm.gameById('g1')!.kind, GameKind.quiz);
      expect(vm.gameById('x'), isNull);
    });

    test('turnuva hatası listeyi engellemez', () async {
      when(() => repo.games()).thenAnswer((_) async => const Success(games));
      when(() => repo.tournament()).thenAnswer((_) async => const Failure(NetworkException()));
      final vm = GamesViewModel(repo);
      await vm.load();
      expect(vm.state, isA<ViewSuccess<GamesHub>>());
      expect(vm.state.dataOrNull!.tournament, isNull);
    });

    test('oyun listesi hatası → hata durumu; boş → boş durum', () async {
      when(() => repo.games()).thenAnswer((_) async => const Failure(NetworkException()));
      when(() => repo.tournament()).thenAnswer((_) async => const Success(null));
      final vm = GamesViewModel(repo);
      await vm.load();
      expect(vm.state, isA<ViewError<GamesHub>>());
      when(() => repo.games()).thenAnswer((_) async => const Success([]));
      await vm.load();
      expect(vm.state, isA<ViewEmpty<GamesHub>>());
    });
  });

  group('MemoryGameViewModel', () {
    MemoryGameViewModel make() => MemoryGameViewModel(repo, gameId: 'g2', pairs: 2, random: math.Random(1), mismatchDelay: Duration.zero);

    (int, int) pairOf(MemoryGameViewModel vm, int symbol) {
      final idx = [
        for (var i = 0; i < vm.deck.length; i++)
          if (vm.deck[i] == symbol) i,
      ];
      return (idx[0], idx[1]);
    }

    test('eşleşmeyenler kapanır, hepsi eşleşince skor gönderilir', () async {
      when(
        () => repo.submitScore(
          any(),
          moves: any(named: 'moves'),
          durationMs: any(named: 'durationMs'),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer((_) async => const Success(GameScoreResult(awarded: 80)));
      final vm = make();
      expect(vm.deck, hasLength(4));
      final (a0, a1) = pairOf(vm, 0);
      final (b0, b1) = pairOf(vm, 1);

      await vm.flip(a0);
      await vm.flip(b0);
      expect(vm.isFaceUp(a0), isFalse, reason: 'eşleşmedi → kapandı');
      expect(vm.moves, 1);

      await vm.flip(a0);
      await vm.flip(a1);
      expect(vm.isMatched(a0) && vm.isMatched(a1), isTrue);
      await vm.flip(a0);
      expect(vm.moves, 2, reason: 'eşleşmiş karta dokunmak hamle sayılmaz');

      await vm.flip(b0);
      await vm.flip(b1);
      expect(vm.finished, isTrue);
      expect(vm.result!.awarded, 80);
      verify(
        () => repo.submitScore(
          'g2',
          moves: 3,
          durationMs: any(named: 'durationMs'),
          sessionId: any(named: 'sessionId'),
        ),
      ).called(1);

      vm.restart();
      expect(vm.finished, isFalse);
      expect(vm.moves, 0);
      expect(vm.result, isNull);
    });

    test('skor gönderimi başarısızsa yeniden denenir', () async {
      when(
        () => repo.submitScore(
          any(),
          moves: any(named: 'moves'),
          durationMs: any(named: 'durationMs'),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer((_) async => const Failure(NetworkException()));
      final vm = make();
      for (final s in [0, 1]) {
        final (x, y) = pairOf(vm, s);
        await vm.flip(x);
        await vm.flip(y);
      }
      expect(vm.submitFailed, isTrue);
      when(
        () => repo.submitScore(
          any(),
          moves: any(named: 'moves'),
          durationMs: any(named: 'durationMs'),
          sessionId: any(named: 'sessionId'),
        ),
      ).thenAnswer((_) async => const Success(GameScoreResult(awarded: 80)));
      await vm.retrySubmit();
      expect(vm.submitFailed, isFalse);
      expect(vm.result!.awarded, 80);
    });
  });
}
