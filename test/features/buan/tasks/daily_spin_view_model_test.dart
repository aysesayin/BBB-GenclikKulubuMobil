import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan_tasks/daily_spin.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/buan_tasks_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/tasks/spin/view_model/daily_spin_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements DailySpinRepository {}

void main() {
  late _Repo repo;
  late DailySpinViewModel vm;
  const slices = [SpinSlice(id: 'a', amount: 10), SpinSlice(id: 'b', amount: 50), SpinSlice(id: 'c', amount: 25)];

  setUp(() {
    repo = _Repo();
    vm = DailySpinViewModel(repo, clock: () => DateTime(2026, 10, 16, 12));
    when(() => repo.status()).thenAnswer((_) async => const Success(DailySpinStatus(available: true, slices: slices)));
  });

  test('yükleme sonrası çevrilebilir', () async {
    await vm.load();
    expect(vm.canSpin, isTrue);
    expect(vm.status!.slices, hasLength(3));
  });

  test('sonuç sunucudan gelir, animasyon bitince kilitlenir', () async {
    final next = DateTime(2026, 10, 17);
    when(() => repo.spin(any())).thenAnswer((_) async => Success(SpinResult(sliceIndex: 1, amount: 50, nextSpinAt: next)));
    await vm.load();
    vm.setMode(SpinMode.shake);
    await vm.spin();

    expect(vm.pendingResult!.sliceIndex, 1);
    expect(vm.spinning, isTrue, reason: 'animasyon sürerken buton pasif');
    expect(vm.mode, SpinMode.wheel, reason: 'salla ile tetiklense de çark gösterilir');
    expect(vm.canSpin, isFalse);

    vm.onSpinAnimationEnd();
    expect(vm.revealed!.amount, 50);
    expect(vm.spinning, isFalse);
    expect(vm.status!.available, isFalse);
    expect(vm.status!.nextSpinAt, next);
    expect(vm.status!.lastAmount, 50);
    verify(() => repo.spin('spin-${DateTime(2026, 10, 16, 12).microsecondsSinceEpoch}')).called(1);

    vm.dismissResult();
    expect(vm.revealed, isNull);
  });

  test('ikinci dokunuş yeni istek atmaz', () async {
    when(() => repo.spin(any())).thenAnswer((_) async => const Success(SpinResult(sliceIndex: 0, amount: 10)));
    await vm.load();
    await Future.wait([vm.spin(), vm.spin()]);
    verify(() => repo.spin(any())).called(1);
  });

  test('sunucu geçersiz dilim dönerse sınırlanır', () async {
    when(() => repo.spin(any())).thenAnswer((_) async => const Success(SpinResult(sliceIndex: 9, amount: 10)));
    await vm.load();
    await vm.spin();
    expect(vm.pendingResult!.sliceIndex, 2);
  });

  test('hata → buton tekrar aktif, hata yayınlanır', () async {
    when(() => repo.spin(any())).thenAnswer((_) async => const Failure(NetworkException()));
    await vm.load();
    await vm.spin();
    expect(vm.error, isA<NetworkException>());
    expect(vm.canSpin, isTrue);
    vm.clearError();
    expect(vm.error, isNull);
  });

  test('hak yoksa çevrilemez', () async {
    when(() => repo.status()).thenAnswer((_) async => const Success(DailySpinStatus(slices: slices)));
    await vm.load();
    await vm.spin();
    expect(vm.state, isA<ViewSuccess<DailySpinStatus>>());
    verifyNever(() => repo.spin(any()));
  });
}
