import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/profile/coupon.dart';
import 'package:bbb_genclik_kulubu_app/data/services/coupon_service.dart';
import 'package:bbb_genclik_kulubu_app/features/profile/coupons/view_model/coupons_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers.dart';

void main() {
  late MockCouponRepository repo;
  late CouponsViewModel vm;

  const wallet = CouponWallet(
    balance: 30,
    items: [Coupon(id: 'cpn-1', title: 'Raporla telafi kuponu', value: 30)],
  );
  final moves = [
    CouponMovement(id: 'm1', title: 'Telafi', date: DateTime(2026, 8, 29), value: 30),
    CouponMovement(id: 'm2', title: 'Kamp', date: DateTime(2026, 9, 20), kind: CouponKind.percent, value: -15),
  ];

  setUp(() {
    repo = MockCouponRepository();
    when(() => repo.wallet()).thenAnswer((_) async => const Success(wallet));
    when(() => repo.movements()).thenAnswer((_) async => Success(moves));
    vm = CouponsViewModel(repo);
  });

  CouponsData data() => (vm.state as ViewSuccess<CouponsData>).data;

  test('bakiye + hareketler (yeniden eskiye) yüklenir', () async {
    await vm.load();
    expect(data().wallet.balance, 30);
    expect(data().movements.first.id, 'm2');
  });

  test('hareketler alınamazsa ekran yine açılır', () async {
    when(() => repo.movements()).thenAnswer((_) async => const Failure(NotFoundException()));
    await vm.load();
    expect(data().movements, isEmpty);
  });

  test('cüzdan alınamazsa hata durumu', () async {
    when(() => repo.wallet()).thenAnswer((_) async => const Failure(NetworkException()));
    await vm.load();
    expect(vm.state, isA<ViewError<CouponsData>>());
  });

  test('boş kod istek atmaz; kod normalize edilir', () async {
    expect(await vm.redeem('   '), isNull);
    expect(vm.issue, CouponIssue.emptyCode);
    when(() => repo.redeem(any())).thenAnswer((_) async => const Success(Coupon(id: 'cpn-2', title: 'GENÇ15')));
    await vm.load();
    final c = await vm.redeem('genç 15');
    expect(c?.id, 'cpn-2');
    verify(() => repo.redeem('GENÇ15')).called(1);
    verify(() => repo.wallet()).called(2);
  });

  test('geçersiz / zaten ekli kod', () async {
    when(() => repo.redeem(any())).thenAnswer((_) async => const Failure(NotFoundException()));
    await vm.redeem('YOK');
    expect(vm.issue, CouponIssue.invalid);
    when(() => repo.redeem(any())).thenAnswer((_) async => const Failure(ConflictException()));
    await vm.redeem('VAR');
    expect(vm.issue, CouponIssue.alreadyAdded);
    vm.clearIssue();
    expect(vm.issue, isNull);
  });

  test('CouponService.parseWallet liste yanıtında bakiyeyi hesaplar', () {
    final w = CouponService.parseWallet([
      {'id': 'a', 'title': 'A', 'kind': 'amount', 'value': 30},
      {'id': 'b', 'title': 'B', 'kind': 'percent', 'value': 15},
      {'id': 'c', 'title': 'C', 'kind': 'amount', 'value': 20, 'used': true},
    ]);
    expect(w.balance, 30);
    expect(w.items, hasLength(3));
  });
}
