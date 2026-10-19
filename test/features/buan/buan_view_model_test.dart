import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/core/router/routes.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan/buan_task.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/view_model/buan_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'buan_fixtures.dart';

void main() {
  late MockBuanRepository repo;

  setUp(() {
    repo = MockBuanRepository(balance: 12450);
    when(() => repo.wallet()).thenAnswer((_) async => const Success(wallet));
    when(() => repo.level()).thenAnswer((_) async => const Success(level));
    when(() => repo.streak()).thenAnswer((_) async => Success(streak));
    when(() => repo.tasks()).thenAnswer(
      (_) async => Success([
        BuanTaskGroup(id: 'daily', title: 'Günlük', tasks: [task(BuanTaskType.steps)]),
        const BuanTaskGroup(id: 'empty', title: 'Boş'),
      ]),
    );
  });

  test('dört kaynağı birleştirir, boş bölümleri atar', () async {
    final vm = BuanViewModel(repo);
    await vm.load();
    final data = (vm.state as ViewSuccess<BuanHomeData>).data;
    expect(data.wallet.balance, 12450);
    expect(data.level.name, 'Kâşif');
    expect(data.streak.days, 7);
    expect(data.groups.map((g) => g.id), ['daily']);
    vm.dispose();
  });

  test('herhangi bir kaynak hata verirse hata durumu', () async {
    when(() => repo.streak()).thenAnswer((_) async => const Failure(NetworkException()));
    final vm = BuanViewModel(repo);
    await vm.load();
    expect(vm.state, isA<ViewError<BuanHomeData>>());
    expect((vm.state as ViewError).isOffline, isTrue);
    vm.dispose();
  });

  test('paylaşılan bakiye değişince dinleyicileri uyarır', () async {
    final vm = BuanViewModel(repo);
    await vm.load();
    var notified = 0;
    vm.addListener(() => notified++);
    repo.balanceNotifier.value = 4450;
    expect(notified, 1);
    expect(vm.balance, 4450);
    vm.dispose();
  });

  group('routeFor', () {
    test('türüne göre ekran', () {
      expect(BuanViewModel.routeFor(task(BuanTaskType.watch)), Routes.watchEarn);
      expect(BuanViewModel.routeFor(task(BuanTaskType.steps)), Routes.steps);
      expect(BuanViewModel.routeFor(task(BuanTaskType.quiz)), Routes.quiz);
      expect(BuanViewModel.routeFor(task(BuanTaskType.invite)), Routes.invite);
      expect(BuanViewModel.routeFor(task(BuanTaskType.photo)), Routes.photoReport);
      expect(BuanViewModel.routeFor(task(BuanTaskType.spin)), Routes.dailySpin);
      expect(BuanViewModel.routeFor(task(BuanTaskType.qr)), Routes.qrScan);
    });

    test('akışı olmayan türler sheet açar (null)', () {
      for (final t in [BuanTaskType.follow, BuanTaskType.volunteer, BuanTaskType.biko, BuanTaskType.idea, BuanTaskType.useOpportunity]) {
        expect(BuanViewModel.routeFor(task(t)), isNull, reason: t.name);
      }
    });

    test('kilitli ve tamamlanmış görev ekrana gitmez', () {
      expect(BuanViewModel.routeFor(task(BuanTaskType.watch, status: BuanTaskStatus.locked)), isNull);
      expect(BuanViewModel.routeFor(task(BuanTaskType.watch, status: BuanTaskStatus.done)), isNull);
      expect(BuanViewModel.routeFor(task(BuanTaskType.invite, status: BuanTaskStatus.pending)), Routes.invite);
    });
  });
}
