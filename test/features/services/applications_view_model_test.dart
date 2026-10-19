import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/services/application.dart';
import 'package:bbb_genclik_kulubu_app/features/services/applications/view_model/applications_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'svc_fixtures.dart';

void main() {
  late MockApplicationRepository repo;
  late FakeClock clock;

  final apps = [
    const Application(
      id: 'a1',
      title: 'Fethiye',
      status: ApplicationStatus.approved,
      paid: true,
      ticket: ApplicationTicket(qrToken: 'q', code: '5271'),
    ),
    const Application(
      id: 'a2',
      title: 'Uludağ',
      status: ApplicationStatus.accepted,
      ticket: ApplicationTicket(qrToken: 'q2', code: '8834'),
    ),
    Application(
      id: 'a3',
      title: 'Kurs',
      status: ApplicationStatus.pendingPayment,
      paymentDueAt: kNow.add(const Duration(hours: 22, minutes: 10)),
    ),
    const Application(id: 'a4', title: 'Kariyer', status: ApplicationStatus.attended, earnedBuan: 300, canCancel: false),
    const Application(id: 'a5', title: 'Gürsu', status: ApplicationStatus.cancelled, couponAmount: 30, canCancel: false),
  ];

  ApplicationsViewModel build() => ApplicationsViewModel(repo, now: clock.call);

  setUp(() {
    repo = MockApplicationRepository();
    clock = FakeClock(kNow);
    when(() => repo.list(status: any(named: 'status'))).thenAnswer((_) async => Success(apps));
  });

  test('aktif sekme: aktif başvurular, sayaç ve ilk bilet açık', () async {
    final vm = build();
    await vm.load();
    expect(vm.visible.map((a) => a.id), ['a1', 'a2', 'a3']);
    expect(vm.activeCount, 3);
    expect(vm.openTicketId, 'a1');
    verify(() => repo.list(status: 'active')).called(1);
  });

  test('geçmiş sekmesi durum filtresiyle yüklenir; aktif sayacı korunur', () async {
    final vm = build();
    await vm.load();
    await vm.setTab(ApplicationsTab.past);
    expect(vm.visible.map((a) => a.id), ['a4', 'a5']);
    expect(vm.activeCount, 3);
    verify(() => repo.list(status: 'past')).called(1);
  });

  test('bilet aç / kapa', () async {
    final vm = build();
    await vm.load();
    vm.toggleTicket('a1');
    expect(vm.openTicketId, isNull);
    vm.toggleTicket('a2');
    expect(vm.openTicketId, 'a2');
  });

  test('ödeme son tarihine kalan saat yukarı yuvarlanır', () async {
    final vm = build();
    expect(vm.hoursLeft(apps[2]), 23);
    clock.advance(const Duration(days: 1));
    expect(vm.hoursLeft(apps[2]), 0);
    expect(vm.hoursLeft(apps[0]), isNull);
  });

  test('iptal başarılı → durum güncellenir, aktiften düşer', () async {
    when(() => repo.cancel('a1')).thenAnswer((_) async => const Success(CancelResult(couponAmount: 100)));
    final vm = build();
    await vm.load();
    expect(await vm.cancel('a1'), isNull);
    expect(vm.visible.map((a) => a.id), ['a2', 'a3']);
    expect(vm.activeCount, 2);
    expect(vm.openTicketId, isNull);
    final cancelled = vm.state.dataOrNull!.firstWhere((a) => a.id == 'a1');
    expect(cancelled.status, ApplicationStatus.cancelled);
    expect(cancelled.couponAmount, 100);
    expect(cancelled.canCancel, isFalse);
  });

  test('iptal hatası döner, liste değişmez', () async {
    when(() => repo.cancel('a2')).thenAnswer((_) async => const Failure(ForbiddenException()));
    final vm = build();
    await vm.load();
    expect(await vm.cancel('a2'), isA<ForbiddenException>());
    expect(vm.visible, hasLength(3));
    expect(vm.isBusy('a2'), isFalse);
  });

  test('aktif başvuru yoksa ViewEmpty', () async {
    when(() => repo.list(status: any(named: 'status'))).thenAnswer((_) async => Success([apps[3]]));
    final vm = build();
    await vm.load();
    expect(vm.state, isA<ViewEmpty<List<Application>>>());
    expect(vm.activeCount, 0);
  });
}
