import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan/buan_reward.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/market/view_model/reward_detail_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'buan_fixtures.dart';

void main() {
  late MockBuanRepository repo;
  late int keySeq;

  RewardDetailViewModel build() => RewardDetailViewModel(repo, 'rwd-teleferik', keyFactory: () => 'key-${++keySeq}');

  setUpAll(() => registerFallbackValue(reward()));

  setUp(() {
    keySeq = 0;
    repo = MockBuanRepository(balance: 12450);
    when(() => repo.reward('rwd-teleferik')).thenAnswer((_) async => Success(reward()));
  });

  void stubRedeem(List<ApiResult<BuanRedeemResult>> results) {
    when(() => repo.redeem(any(), idempotencyKey: any(named: 'idempotencyKey'))).thenAnswer((_) async {
      final r = results.removeAt(0);
      if (r is Success<BuanRedeemResult>) repo.balanceNotifier.value = 4450;
      return r;
    });
  }

  test('fiyat, bakiye ve takastan sonra önizlemesi', () async {
    final vm = build();
    await vm.load();
    expect(vm.balance, 12450);
    expect(vm.balanceAfter, 4450);
    expect(vm.canAfford, isTrue);
    expect(vm.canRedeem, isTrue);
  });

  test('bakiye yetmiyorsa takas kapalı ve eksik tutar hesaplanır', () async {
    repo.balanceNotifier.value = 5000;
    final vm = build();
    await vm.load();
    expect(vm.canRedeem, isFalse);
    expect(vm.missing, 3000);
    expect(await vm.redeem(), isFalse);
    verifyNever(() => repo.redeem(any(), idempotencyKey: any(named: 'idempotencyKey')));
  });

  test('stok bitmişse takas kapalı', () async {
    when(() => repo.reward('rwd-teleferik')).thenAnswer((_) async => Success(reward(stock: 0)));
    final vm = build();
    await vm.load();
    expect(vm.soldOut, isTrue);
    expect(vm.canRedeem, isFalse);
  });

  test('başarılı takas: sonuç, eski/yeni bakiye', () async {
    stubRedeem([const Success(BuanRedeemResult(code: 'TLF-48QK'))]);
    final vm = build();
    await vm.load();
    vm.beginRedeem();
    expect(await vm.redeem(), isTrue);
    expect(vm.result?.code, 'TLF-48QK');
    expect(vm.balanceBefore, 12450);
    expect(vm.balance, 4450);
    expect(vm.redeeming, isFalse);
    verify(() => repo.redeem(any(), idempotencyKey: 'key-1')).called(1);
  });

  test('ağ hatası sonrası tekrar deneme AYNI idempotency anahtarını kullanır', () async {
    stubRedeem([const Failure(NetworkException()), const Success(BuanRedeemResult(code: 'X'))]);
    final vm = build();
    await vm.load();
    vm.beginRedeem();
    expect(await vm.redeem(), isFalse);
    expect(vm.redeemError, isA<NetworkException>());
    expect(await vm.redeem(), isTrue);
    verify(() => repo.redeem(any(), idempotencyKey: 'key-1')).called(2);
    expect(vm.redeemError, isNull);
  });

  test('sheet kapatılıp yeniden açılınca yeni anahtar üretilir', () async {
    stubRedeem([const Failure(ConflictException()), const Success(BuanRedeemResult(code: 'X'))]);
    final vm = build();
    await vm.load();
    vm.beginRedeem();
    await vm.redeem();
    vm.cancelRedeem();
    expect(vm.idempotencyKey, isNull);
    vm.beginRedeem();
    await vm.redeem();
    verify(() => repo.redeem(any(), idempotencyKey: 'key-1')).called(1);
    verify(() => repo.redeem(any(), idempotencyKey: 'key-2')).called(1);
  });

  test('varsayılan anahtar UUID v4 biçiminde', () async {
    stubRedeem([const Success(BuanRedeemResult(code: 'X'))]);
    final vm = RewardDetailViewModel(repo, 'rwd-teleferik');
    await vm.load();
    vm.beginRedeem();
    final key = vm.idempotencyKey!;
    expect(RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$').hasMatch(key), isTrue, reason: key);
  });
}
