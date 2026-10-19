import '../../../../../core/base/base_view_model.dart';
import '../../../../../core/base/view_state.dart';
import '../../../../../core/network/api_result.dart';
import '../../../../../core/network/app_exception.dart';
import '../../../../../data/models/buan_tasks/daily_spin.dart';
import '../../../../../data/repositories/buan_tasks_repository.dart';

enum SpinMode { wheel, shake }

/// E7 · Günlük Şans. Sonuç SUNUCUDA belirlenir; görünüm yalnız [pendingResult]'a
/// dönen animasyonu oynatır ve bitince [onSpinAnimationEnd]'i çağırır.
class DailySpinViewModel extends LoadableViewModel<DailySpinStatus> {
  DailySpinViewModel(this._repo, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DailySpinRepository _repo;
  final DateTime Function() _clock;

  SpinMode _mode = SpinMode.wheel;
  SpinMode get mode => _mode;

  bool _spinning = false;

  /// İstek gönderildi ya da çark dönüyor.
  bool get spinning => _spinning;

  SpinResult? _pending;

  /// Sunucudan gelen, animasyonu henüz bitmemiş sonuç.
  SpinResult? get pendingResult => _pending;

  SpinResult? _won;

  /// Animasyon bitti → kazanç penceresi gösterilir.
  SpinResult? get revealed => _won;

  AppException? _error;
  AppException? get error => _error;

  DailySpinStatus? get status => state.dataOrNull;
  bool get canSpin => (status?.available ?? false) && !_spinning;

  @override
  Future<ApiResult<DailySpinStatus>> fetch() => _repo.status();

  void setMode(SpinMode m) {
    if (_mode == m || _spinning) return;
    _mode = m;
    notify();
  }

  Future<void> spin() async {
    if (!canSpin) return;
    _spinning = true;
    _error = null;
    notify();
    final result = await _repo.spin('spin-${_clock().microsecondsSinceEpoch}');
    if (isDisposed) return;
    switch (result) {
      case Success(:final data):
        final count = status?.slices.length ?? 0;
        _pending = count == 0 ? data : data.copyWith(sliceIndex: data.sliceIndex.clamp(0, count - 1));
        // Çark bu dilime dönerken buton "Dönüyor…" kalır.
        _mode = SpinMode.wheel;
      case Failure(:final error):
        _spinning = false;
        _error = error;
    }
    notify();
  }

  /// Görünüm, çark animasyonu (veya azaltılmış hareketle anında) bitince çağırır.
  void onSpinAnimationEnd() {
    final r = _pending;
    if (r == null) return;
    _pending = null;
    _won = r;
    _spinning = false;
    final s = status;
    if (s != null) {
      state = ViewSuccess(s.copyWith(available: false, nextSpinAt: r.nextSpinAt ?? s.nextSpinAt, lastAmount: r.amount));
    } else {
      notify();
    }
  }

  void dismissResult() {
    _won = null;
    notify();
  }

  void clearError() {
    _error = null;
    notify();
  }
}
