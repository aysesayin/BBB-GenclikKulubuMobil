import 'dart:async';
import 'dart:math' as math;

import '../../../../../core/base/base_view_model.dart';
import '../../../../../core/network/api_result.dart';
import '../../../../../core/network/app_exception.dart';
import '../../../../../data/models/buan_tasks/watch_video.dart';
import '../../../../../data/repositories/buan_tasks_repository.dart';

/// E8 · İzle Kazan. İzlenen süre yalnız ön plandayken ve oynatılırken artar;
/// ileri sarma engellenir (bkz. [onPosition]). Her 10 sn'de bir heartbeat,
/// eşik (%90) aşılınca `complete` gönderilir; ödülü sunucu verir.
class WatchEarnViewModel extends LoadableViewModel<WatchVideo> {
  WatchEarnViewModel(this._repo, {this.heartbeatInterval = const Duration(seconds: 10)});

  final WatchEarnRepository _repo;
  final Duration heartbeatInterval;

  /// İleri sarma sayılmadan kabul edilen en büyük sıçrama (sn).
  static const seekTolerance = 2.0;

  Timer? _hb;
  double _watched = 0;
  double _position = 0;
  bool _playing = false;
  bool _foreground = true;
  bool _completing = false;
  bool _completeFailed = false;
  VideoCompleteResult? _completion;
  AppException? _error;

  WatchVideo? get video => state.dataOrNull;
  double get watchedSec => _watched;
  double get positionSec => _position;
  bool get playing => _playing;
  bool get foreground => _foreground;
  bool get completing => _completing;
  VideoCompleteResult? get completion => _completion;
  AppException? get error => _error;

  double get progress {
    final d = video?.durationSec ?? 0;
    if (video?.completed ?? false) return 1;
    return d <= 0 ? 0 : math.min(1, _watched / d);
  }

  bool get thresholdReached => progress >= (video?.completeRatio ?? .9);

  /// Bu videonun ödülü alındı (bu oturumda ya da daha önce).
  bool get done => _completion != null || (video?.completed ?? false);

  @override
  Future<ApiResult<WatchVideo>> fetch() => _repo.current();

  @override
  Future<void> load() async {
    await super.load();
    final v = video;
    if (v != null) {
      _watched = math.max(_watched, v.watchedSec.toDouble());
      _position = _watched;
      notify();
    }
  }

  /// Oynatıcıdan gelen konum. İleri sarılmışsa geri dönülecek saniyeyi döndürür.
  double? onPosition(double sec) {
    if (video == null || done) return null;
    if (sec > _watched + seekTolerance) return _watched;
    _position = sec;
    if (_playing && _foreground && sec > _watched) _watched = sec;
    notify();
    if (thresholdReached && !_completing && !_completeFailed) unawaited(complete());
    return null;
  }

  void setPlaying(bool value) {
    if (_playing == value) return;
    _playing = value && _foreground && !done;
    _hb?.cancel();
    if (_playing) {
      _hb = Timer.periodic(heartbeatInterval, (_) => heartbeat());
    } else {
      unawaited(heartbeat());
    }
    notify();
  }

  /// Uygulama arka plana geçince süre sayılmaz; görünüm oynatıcıyı da durdurur.
  void setForeground(bool value) {
    _foreground = value;
    if (!value) setPlaying(false);
    notify();
  }

  Future<void> heartbeat() async {
    final v = video;
    if (v == null || done) return;
    // Tamamlama ağ hatasıyla düştüyse bir sonraki heartbeat'te yeniden denenir.
    if (_completeFailed && thresholdReached) return complete();
    await _repo.heartbeat(v.id, positionSec: _position.round(), watchedSec: _watched.round());
  }

  Future<void> complete() async {
    final v = video;
    if (v == null || done || _completing) return;
    _completing = true;
    notify();
    final r = await _repo.complete(v.id, watchedSec: _watched.round());
    if (isDisposed) return;
    _completing = false;
    switch (r) {
      case Success(:final data):
        _completion = data;
        _completeFailed = false;
        _playing = false;
        _hb?.cancel();
      case Failure(:final error):
        _completeFailed = true;
        _error = error;
    }
    notify();
  }

  void clearError() => _error = null;

  @override
  void dispose() {
    _hb?.cancel();
    super.dispose();
  }
}
