import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../core/base/base_view_model.dart';
import '../../../core/base/view_state.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/app_exception.dart';
import '../../../data/models/card/digital_card.dart';
import '../../../data/repositories/card_repository.dart';

/// D1 · Kartım: kart bilgisi + 30 sn'de bir yenilenen dinamik QR.
///
/// Çevrimdışıyken (token alınamazsa) güvenli depodaki son geçerli 4 haneli kod gösterilir.
/// Görünüm sekme görünür değilken [setActive] ile sayacı durdurur.
class CardViewModel extends BaseViewModel {
  CardViewModel(this._repo, {DateTime Function()? clock, this.autoTick = true}) : _now = clock ?? DateTime.now;

  final CardRepository _repo;
  final DateTime Function() _now;

  /// Testlerde false → zamanlayıcı yerine [tick] elle çağrılır.
  final bool autoTick;

  ViewState<DigitalCard> _card = const ViewIdle();
  ViewState<DigitalCard> get card => _card;

  CardToken? _token;
  CardToken? get token => _token;
  DateTime? _tokenAt;

  bool _tokenLoading = false;
  bool get tokenLoading => _tokenLoading;

  /// Token alınamadı (ağ yok) → QR yerine son kod.
  bool _offline = false;
  bool get offline => _offline;
  String? _offlinePin;

  AppException? _tokenError;
  AppException? get tokenError => _tokenError;

  DateTime? _lastAttempt;
  Timer? _timer;
  bool _active = false;

  static const _retryEvery = Duration(seconds: 15);

  /// Ekranda gösterilecek 4 haneli kod (çevrimiçi token ya da çevrimdışı son kod).
  String? get pin => _token?.pin ?? _offlinePin;

  int get ttl => math.max(1, _token?.ttlSeconds ?? 30);

  int get secondsLeft {
    final at = _tokenAt;
    if (_token == null || at == null) return 0;
    return (ttl - _now().difference(at).inSeconds).clamp(0, ttl);
  }

  double get ringValue => _token == null ? 0 : secondsLeft / ttl;

  Future<void> load() async {
    _card = ViewLoading(previous: _card.dataOrNull);
    notify();
    await Future.wait([_loadCard(), refreshToken()]);
  }

  Future<void> refresh() => load();

  Future<void> _loadCard() async {
    final r = await _repo.card();
    if (isDisposed) return;
    _card = switch (r) {
      Success(:final data, :final fromCache) => ViewSuccess(data, fromCache: fromCache),
      Failure(:final error, :final cached) => ViewError(error, cached: cached),
    };
    notify();
  }

  Future<void> refreshToken() async {
    if (_tokenLoading) return;
    _tokenLoading = true;
    _lastAttempt = _now();
    notify();
    final r = await _repo.token();
    if (isDisposed) return;
    switch (r) {
      case Success(:final data):
        _token = data;
        _tokenAt = _now();
        _offline = false;
        _offlinePin = null;
        _tokenError = null;
      case Failure(:final error):
        _token = null;
        _tokenAt = null;
        _tokenError = error;
        _offline = error is NetworkException;
        if (_offline) _offlinePin = await _repo.lastPin();
    }
    _tokenLoading = false;
    notify();
  }

  /// Sekme görünür/gizli. Gizliyken sayaç durur; geri gelince süresi dolduysa yenilenir.
  void setActive(bool value) {
    if (_active == value) return;
    _active = value;
    _timer?.cancel();
    _timer = null;
    if (!value) return;
    if (autoTick) _timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
    if (_card is! ViewIdle && _token != null && secondsLeft <= 0) refreshToken();
  }

  bool get active => _active;

  @visibleForTesting
  void tick() {
    if (isDisposed || !_active) return;
    if (!_tokenLoading) {
      final due = _token != null ? secondsLeft <= 0 : (_lastAttempt == null || _now().difference(_lastAttempt!) >= _retryEvery);
      if (due) {
        refreshToken();
        return;
      }
    }
    notify();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
