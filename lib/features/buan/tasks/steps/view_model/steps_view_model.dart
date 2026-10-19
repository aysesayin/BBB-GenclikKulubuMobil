import 'dart:async';
import 'dart:math' as math;

import '../../../../../core/base/base_view_model.dart';
import '../../../../../core/base/view_state.dart';
import '../../../../../core/network/api_result.dart';
import '../../../../../core/network/app_exception.dart';
import '../../../../../data/models/buan_tasks/steps.dart';
import '../../../../../data/repositories/buan_tasks_repository.dart';
import '../../widgets/task_dates.dart';
import 'step_source.dart';

enum StepSensorState { starting, active, denied, unavailable }

/// E9 · Bir Adım At. Cihaz adımını sunucuya `{date, steps}` olarak bildirir;
/// günlük üst limiti ve ödülü sunucu uygular.
class StepsViewModel extends LoadableViewModel<StepsSummary> {
  StepsViewModel(
    this._repo, {
    required StepSensor sensor,
    required StepTracker tracker,
    DateTime Function()? clock,
    this.sensorTimeout = const Duration(seconds: 6),
  }) : _sensor = sensor,
       _tracker = tracker,
       _clock = clock ?? DateTime.now;

  final StepsRepository _repo;
  final StepSensor _sensor;
  final StepTracker _tracker;
  final DateTime Function() _clock;
  final Duration sensorTimeout;

  StreamSubscription<int>? _sub;
  Timer? _timeout;
  StepSensorState _sensorState = StepSensorState.starting;
  int _device = 0;
  bool _syncing = false;
  DateTime? _syncedAt;
  int _pendingAward = 0;
  AppException? _error;

  StepSensorState get sensorState => _sensorState;
  bool get syncing => _syncing;
  DateTime? get syncedAt => _syncedAt;
  AppException? get error => _error;
  StepsSummary? get summary => state.dataOrNull;

  int get todaySteps => math.max(summary?.steps ?? 0, _device);
  int get goal => summary?.goal ?? 0;
  bool get reached => goal > 0 && todaySteps >= goal;
  bool get claimed => summary?.claimed ?? false;
  int get remaining => math.max(0, goal - todaySteps);
  double get progress => goal <= 0 ? 0 : math.min(1, todaySteps / goal);

  // TODO(varsayım): Mesafe ve aktif süre cihazda tahmin edilir (adım 0,75 m; dakikada ~110 adım).
  double get distanceKm => todaySteps * 0.00075;
  int get activeMinutes => (todaySteps / 110).round();

  /// Hedefe ulaşılan gün sayısı (önceki günler + bugün).
  int get goalDays => (summary?.week.where((d) => d.steps >= goal).length ?? 0) + (reached ? 1 : 0);

  @override
  Future<ApiResult<StepsSummary>> fetch() => _repo.summary();

  /// Ekran açılınca: sunucu özeti + sensör dinleme.
  Future<void> start() async {
    _device = _tracker.today(_clock());
    _listen();
    await load();
    if (_device > (summary?.steps ?? 0)) await sync();
  }

  void _listen() {
    _sub?.cancel();
    _sensorState = StepSensorState.starting;
    _timeout = Timer(sensorTimeout, () {
      if (_sensorState == StepSensorState.starting) {
        _sensorState = StepSensorState.unavailable;
        notify();
      }
    });
    _sub = _sensor.stepsSinceBoot().listen(
      (raw) {
        _device = _tracker.record(raw, _clock());
        _sensorState = StepSensorState.active;
        notify();
      },
      onError: (Object e) {
        _sensorState = e is StepSensorException && e.denied ? StepSensorState.denied : StepSensorState.unavailable;
        notify();
      },
    );
  }

  /// Ayarlardan dönünce yeniden dene.
  void retrySensor() {
    _timeout?.cancel();
    _listen();
    notify();
  }

  /// Bugünkü adımı bildirir. Sunucu hedef tamamsa ödülü verir (yanıt `awarded`).
  Future<void> sync() async {
    if (_syncing) return;
    _syncing = true;
    notify();
    final now = _clock();
    final r = await _repo.report(date: isoDay(now), steps: todaySteps);
    if (isDisposed) return;
    _syncing = false;
    switch (r) {
      case Success(:final data):
        _syncedAt = now;
        _pendingAward += data.awarded;
        state = ViewSuccess(data);
      case Failure(:final error):
        _error = error;
        notify();
    }
  }

  /// "750 BUAN'ı al".
  Future<void> claim() async {
    if (!reached || claimed) return;
    await sync();
  }

  /// Gösterilmemiş ödül tutarını bir kez döndürür (toast + konfeti için).
  int takeAward() {
    final a = _pendingAward;
    _pendingAward = 0;
    return a;
  }

  void clearError() => _error = null;

  @override
  void dispose() {
    _sub?.cancel();
    _timeout?.cancel();
    super.dispose();
  }
}
