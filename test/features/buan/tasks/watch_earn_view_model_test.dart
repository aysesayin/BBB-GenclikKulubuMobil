import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan_tasks/watch_video.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/buan_tasks_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/tasks/watch/view_model/watch_earn_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements WatchEarnRepository {}

void main() {
  late _Repo repo;
  late WatchEarnViewModel vm;
  const video = WatchVideo(id: 'v1', youtubeId: 'yt', title: 'T', durationSec: 100, reward: 1000, watchedSec: 10);

  setUp(() {
    repo = _Repo();
    vm = WatchEarnViewModel(repo, heartbeatInterval: const Duration(milliseconds: 20));
    when(() => repo.current()).thenAnswer((_) async => const Success(video));
    when(
      () => repo.heartbeat(
        any(),
        positionSec: any(named: 'positionSec'),
        watchedSec: any(named: 'watchedSec'),
      ),
    ).thenAnswer((_) async => const Success(null));
    when(
      () => repo.complete(any(), watchedSec: any(named: 'watchedSec')),
    ).thenAnswer((_) async => const Success(VideoCompleteResult(awarded: 1000)));
  });

  tearDown(() => vm.dispose());

  test('kaldığı yerden başlar', () async {
    await vm.load();
    expect(vm.watchedSec, 10);
    expect(vm.progress, closeTo(.1, 1e-9));
  });

  test('yalnız oynatılırken sayılır; ileri sarma geri döndürülür', () async {
    await vm.load();
    expect(vm.onPosition(11), isNull);
    expect(vm.watchedSec, 10, reason: 'duraklatılmışken artmaz');

    vm.setPlaying(true);
    expect(vm.onPosition(11.5), isNull);
    expect(vm.watchedSec, 11.5);
    expect(vm.onPosition(60), 11.5, reason: 'ileri sarma → son izlenen konuma dön');
    expect(vm.watchedSec, 11.5);
  });

  test('arka planda süre sayılmaz', () async {
    await vm.load();
    vm.setPlaying(true);
    vm.setForeground(false);
    expect(vm.playing, isFalse);
    vm.onPosition(11);
    expect(vm.watchedSec, 10);
  });

  test('heartbeat periyodik gönderilir', () async {
    await vm.load();
    vm.setPlaying(true);
    vm.onPosition(11);
    await Future<void>.delayed(const Duration(milliseconds: 70));
    verify(() => repo.heartbeat('v1', positionSec: 11, watchedSec: 11)).called(greaterThanOrEqualTo(2));
  });

  test('%90 → complete, ödül sunucudan', () async {
    await vm.load();
    vm.setPlaying(true);
    for (var s = 11.0; s <= 92; s += 1.5) {
      vm.onPosition(s);
    }
    await Future<void>.delayed(Duration.zero);
    expect(vm.thresholdReached, isTrue);
    expect(vm.done, isTrue);
    expect(vm.completion!.awarded, 1000);
    expect(vm.playing, isFalse);
    verify(() => repo.complete('v1', watchedSec: any(named: 'watchedSec'))).called(1);
  });

  test('complete hatası heartbeat ile yeniden denenir', () async {
    when(() => repo.complete(any(), watchedSec: any(named: 'watchedSec'))).thenAnswer((_) async => const Failure(NetworkException()));
    await vm.load();
    vm.setPlaying(true);
    for (var s = 11.0; s <= 92; s += 1.5) {
      vm.onPosition(s);
    }
    await Future<void>.delayed(Duration.zero);
    expect(vm.error, isA<NetworkException>());
    expect(vm.done, isFalse);

    when(
      () => repo.complete(any(), watchedSec: any(named: 'watchedSec')),
    ).thenAnswer((_) async => const Success(VideoCompleteResult(awarded: 1000)));
    await vm.heartbeat();
    expect(vm.done, isTrue);
  });

  test('daha önce tamamlanmış video sayılmaz', () async {
    when(() => repo.current()).thenAnswer(
      (_) async => const Success(WatchVideo(id: 'v1', youtubeId: 'yt', title: 'T', durationSec: 100, reward: 1000, completed: true)),
    );
    await vm.load();
    expect(vm.done, isTrue);
    expect(vm.progress, 1);
    vm.setPlaying(true);
    expect(vm.playing, isFalse);
    expect(vm.onPosition(5), isNull);
    verifyNever(() => repo.complete(any(), watchedSec: any(named: 'watchedSec')));
  });
}
