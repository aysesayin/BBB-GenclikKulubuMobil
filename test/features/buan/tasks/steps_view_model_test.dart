import 'dart:async';

import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan_tasks/steps.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/buan_tasks_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/tasks/steps/view_model/step_source.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/tasks/steps/view_model/steps_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements StepsRepository {}

class _Sensor implements StepSensor {
  final controller = StreamController<int>.broadcast();
  @override
  Stream<int> stepsSinceBoot() => controller.stream;
}

StepTracker _memoryTracker([String? initial]) {
  var store = initial;
  return StepTracker(read: () => store, write: (v) async => store = v);
}

void main() {
  final now = DateTime(2026, 10, 16, 15);
  final summary = StepsSummary(
    date: DateTime(2026, 10, 16),
    goal: 8000,
    reward: 750,
    steps: 6240,
    week: [
      StepDay(date: DateTime(2026, 10, 15), steps: 9000),
      StepDay(date: DateTime(2026, 10, 14), steps: 3000),
    ],
  );
  late _Repo repo;
  late _Sensor sensor;

  setUp(() {
    repo = _Repo();
    sensor = _Sensor();
    when(() => repo.summary()).thenAnswer((_) async => Success(summary));
  });

  StepsViewModel make({StepTracker? tracker, Duration timeout = const Duration(seconds: 6)}) =>
      StepsViewModel(repo, sensor: sensor, tracker: tracker ?? _memoryTracker(), clock: () => now, sensorTimeout: timeout);

  group('StepTracker', () {
    test('aynı gün farkı biriktirir, yeniden başlatmayı tolere eder', () {
      final t = _memoryTracker();
      expect(t.record(1000, now), 0, reason: 'günün ilk okuması taban olur');
      expect(t.record(1500, now), 500);
      expect(t.record(200, now), 700, reason: 'sayaç sıfırlandı → yeni değer eklenir');
      expect(t.today(now), 700);
      expect(t.today(now.add(const Duration(days: 1))), 0);
      expect(t.record(5000, now.add(const Duration(days: 1))), 0, reason: 'yeni gün sıfırdan');
    });
  });

  test('sunucu değeri gösterilir, hedefe kalan hesaplanır', () async {
    final vm = make();
    await vm.start();
    expect(vm.todaySteps, 6240);
    expect(vm.reached, isFalse);
    expect(vm.remaining, 1760);
    expect(vm.goalDays, 1);
    expect(vm.distanceKm, closeTo(4.68, .01));
    vm.dispose();
  });

  test('sensör adımı sunucuyu geçince ödül alınır', () async {
    when(
      () => repo.report(
        date: any(named: 'date'),
        steps: any(named: 'steps'),
      ),
    ).thenAnswer((_) async => Success(summary.copyWith(steps: 8100, claimed: true, awarded: 750)));
    final vm = make(tracker: _memoryTracker('{"day":"2026-10-16","last":100,"acc":8000}'));
    await vm.start();
    // Kayıtlı 8000 cihaz adımı > sunucu 6240 → açılışta eşitlenir.
    verify(() => repo.report(date: '2026-10-16', steps: 8000)).called(1);
    expect(vm.claimed, isTrue);
    expect(vm.takeAward(), 750);
    expect(vm.takeAward(), 0, reason: 'ödül bir kez gösterilir');
    expect(vm.syncedAt, now);
    vm.dispose();
  });

  test('sensör olayı state günceller; hedefte claim gönderir', () async {
    when(
      () => repo.report(
        date: any(named: 'date'),
        steps: any(named: 'steps'),
      ),
    ).thenAnswer((_) async => Success(summary.copyWith(steps: 8300, claimed: true, awarded: 750)));
    final vm = make();
    await vm.start();
    sensor.controller.add(1000);
    await Future<void>.delayed(Duration.zero);
    expect(vm.sensorState, StepSensorState.active);
    sensor.controller.add(9300);
    await Future<void>.delayed(Duration.zero);
    expect(vm.todaySteps, 8300);
    expect(vm.reached, isTrue);
    await vm.claim();
    verify(() => repo.report(date: '2026-10-16', steps: 8300)).called(1);
    expect(vm.claimed, isTrue);
    await vm.claim();
    verifyNever(
      () => repo.report(
        date: any(named: 'date'),
        steps: any(named: 'steps'),
      ),
    );
    vm.dispose();
  });

  test('izin reddi → denied; yanıt yoksa → unavailable', () async {
    final vm = make(timeout: const Duration(milliseconds: 10));
    await vm.start();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(vm.sensorState, StepSensorState.unavailable);

    vm.retrySensor();
    expect(vm.sensorState, StepSensorState.starting);
    sensor.controller.addError(const StepSensorException(denied: true));
    await Future<void>.delayed(Duration.zero);
    expect(vm.sensorState, StepSensorState.denied);
    vm.dispose();
  });

  test('bildirim hatası yayınlanır', () async {
    when(
      () => repo.report(
        date: any(named: 'date'),
        steps: any(named: 'steps'),
      ),
    ).thenAnswer((_) async => const Failure(NetworkException()));
    final vm = make();
    await vm.start();
    await vm.sync();
    expect(vm.error, isA<NetworkException>());
    expect(vm.syncing, isFalse);
    vm.dispose();
  });
}
