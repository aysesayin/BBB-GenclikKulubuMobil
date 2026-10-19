import 'dart:math' as math;

import '../../../core/base/base_view_model.dart';
import '../../../core/network/api_result.dart';
import '../../../data/models/games/game.dart';
import '../../../data/repositories/games_repository.dart';

/// "Hafıza Kartları" mini oyunu (yerleşik, Flame'siz). İstemci yalnız hamle
/// sayısı ve süreyi bildirir; BUAN sunucuda hesaplanır.
class MemoryGameViewModel extends BaseViewModel {
  MemoryGameViewModel(
    this._repo, {
    required this.gameId,
    this.pairs = 6,
    math.Random? random,
    DateTime Function()? clock,
    this.mismatchDelay = const Duration(milliseconds: 700),
  }) : _random = random ?? math.Random(),
       _clock = clock ?? DateTime.now {
    _deal();
  }

  final GamesRepository _repo;
  final String gameId;
  final int pairs;
  final math.Random _random;
  final DateTime Function() _clock;
  final Duration mismatchDelay;

  late List<int> _deck;
  final Set<int> _open = {};
  final Set<int> _matched = {};
  int? _first;
  bool _locked = false;
  int _moves = 0;
  DateTime? _startedAt;
  bool _submitting = false;
  GameScoreResult? _result;
  bool _submitFailed = false;
  String _sessionId = '';

  /// Kart → sembol indeksi (0..pairs-1).
  List<int> get deck => _deck;
  int get moves => _moves;
  bool get finished => _matched.length == _deck.length;
  bool get submitting => _submitting;
  GameScoreResult? get result => _result;
  bool get submitFailed => _submitFailed;

  bool isFaceUp(int i) => _open.contains(i) || _matched.contains(i);
  bool isMatched(int i) => _matched.contains(i);

  void _deal() {
    _deck = [
      for (var s = 0; s < pairs; s++) ...[s, s],
    ]..shuffle(_random);
    _open.clear();
    _matched.clear();
    _first = null;
    _locked = false;
    _moves = 0;
    _startedAt = null;
    _result = null;
    _submitFailed = false;
    _sessionId = 'mem-${_clock().microsecondsSinceEpoch}-${_random.nextInt(1000000)}';
  }

  void restart() {
    _deal();
    notify();
  }

  Future<void> flip(int i) async {
    if (_locked || finished || isFaceUp(i)) return;
    _startedAt ??= _clock();
    _open.add(i);
    final first = _first;
    if (first == null) {
      _first = i;
      notify();
      return;
    }
    _first = null;
    _moves++;
    if (_deck[first] == _deck[i]) {
      _open
        ..remove(first)
        ..remove(i);
      _matched.addAll([first, i]);
      notify();
      if (finished) await _submit();
      return;
    }
    _locked = true;
    notify();
    await Future<void>.delayed(mismatchDelay);
    if (isDisposed) return;
    _open
      ..remove(first)
      ..remove(i);
    _locked = false;
    notify();
  }

  Future<void> _submit() async {
    _submitting = true;
    _submitFailed = false;
    notify();
    final ms = _clock().difference(_startedAt ?? _clock()).inMilliseconds;
    final r = await _repo.submitScore(gameId, moves: _moves, durationMs: ms, sessionId: _sessionId);
    if (isDisposed) return;
    _submitting = false;
    switch (r) {
      case Success(:final data):
        _result = data;
      case Failure():
        _submitFailed = true;
    }
    notify();
  }

  Future<void> retrySubmit() async {
    if (finished && _result == null && !_submitting) await _submit();
  }
}
