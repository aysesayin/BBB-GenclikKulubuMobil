import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../../core/storage/cache_store.dart';
import '../../widgets/task_dates.dart';

/// Adım sensörü hatası: izin reddi veya donanım/platform desteği yok.
class StepSensorException implements Exception {
  const StepSensorException({required this.denied});
  final bool denied;
}

/// Cihaz adım sayacı soyutlaması (test edilebilirlik + web yedeği).
abstract interface class StepSensor {
  /// Son açılıştan bu yana toplam adım. Hata → [StepSensorException].
  Stream<int> stepsSinceBoot();
}

/// `pedometer` paketi: Android TYPE_STEP_COUNTER, iOS CMPedometer.
// Önce hareket/aktivite izni istenir (Android ACTIVITY_RECOGNITION, iOS Motion).
// TODO(varsayım): HealthKit / Health Connect ile gün boyu eşitleme (tasarımdaki "Apple Sağlık") entegrasyonda eklenecek.
class PedometerStepSensor implements StepSensor {
  const PedometerStepSensor();

  @override
  Stream<int> stepsSinceBoot() {
    if (kIsWeb) return Stream.error(const StepSensorException(denied: false));
    return Stream.fromFuture(_ensurePermission()).asyncExpand((granted) {
      if (!granted) return Stream<int>.error(const StepSensorException(denied: true));
      return _stream();
    });
  }

  static Future<bool> _ensurePermission() async {
    try {
      final perm = defaultTargetPlatform == TargetPlatform.iOS ? Permission.sensors : Permission.activityRecognition;
      final status = await perm.request();
      return status.isGranted || status.isLimited;
    } on Object {
      return true; // eklenti yoksa (test) pedometer kendi hatasını verir
    }
  }

  static Stream<int> _stream() {
    try {
      return Pedometer.stepCountStream
          .map((e) => e.steps)
          .transform(
            StreamTransformer.fromHandlers(
              handleError: (Object e, st, sink) {
                final denied = e is PlatformException && '${e.code} ${e.message}'.toLowerCase().contains('permission');
                sink.addError(StepSensorException(denied: denied));
              },
            ),
          );
    } on Object {
      return Stream.error(const StepSensorException(denied: false));
    }
  }
}

/// "Açılıştan beri" sayacını günlük adıma çevirir ve cihazda saklar.
/// Uygulama gün içinde ilk açıldığında önceki adımlar bilinemez (sunucu değeri korunur).
class StepTracker {
  StepTracker({required String? Function() read, required Future<void> Function(String) write}) : _read = read, _write = write;

  factory StepTracker.cache(CacheStore cache) => StepTracker(read: () => cache.readString(_key), write: (v) => cache.writeString(_key, v));

  static const _key = 'user.steps.tracker';
  final String? Function() _read;
  final Future<void> Function(String) _write;

  /// Ham okumayı kaydeder, bugünün cihaz adımını döndürür.
  int record(int raw, DateTime now) {
    final today = isoDay(now);
    var day = today, last = raw, acc = 0;
    try {
      final j = jsonDecode(_read() ?? '{}') as Map<String, dynamic>;
      if (j['day'] == today) {
        day = today;
        final prev = (j['last'] as num).toInt();
        acc = (j['acc'] as num).toInt() + (raw >= prev ? raw - prev : raw); // raw < prev → cihaz yeniden başladı
      }
    } on Object {
      acc = 0;
    }
    last = raw;
    unawaited(_write(jsonEncode({'day': day, 'last': last, 'acc': acc})));
    return acc;
  }

  /// Bugün daha önce kaydedilen cihaz adımı (sensör açılmadan önce gösterim için).
  int today(DateTime now) {
    try {
      final j = jsonDecode(_read() ?? '{}') as Map<String, dynamic>;
      return j['day'] == isoDay(now) ? (j['acc'] as num).toInt() : 0;
    } on Object {
      return 0;
    }
  }
}
