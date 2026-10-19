import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/market/view_model/market_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'buan_fixtures.dart';

void main() {
  late MockBuanRepository repo;

  setUp(() {
    repo = MockBuanRepository(balance: 12450);
    when(() => repo.market()).thenAnswer((_) async => Success(market));
    when(() => repo.wallet()).thenAnswer((_) async => const Success(wallet));
  });

  test('yükler; büyük ödülü bulur', () async {
    final vm = MarketViewModel(repo);
    await vm.load();
    expect(vm.visibleItems, hasLength(3));
    expect(vm.featured?.id, 'rwd-kapadokya');
    expect(vm.categories, hasLength(2));
    verifyNever(() => repo.wallet());
  });

  test('bakiye bilinmiyorsa cüzdanı da okur', () async {
    repo = MockBuanRepository();
    when(() => repo.market()).thenAnswer((_) async => Success(market));
    when(() => repo.wallet()).thenAnswer((_) async {
      repo.balanceNotifier.value = 12450;
      return const Success(wallet);
    });
    final vm = MarketViewModel(repo);
    await vm.load();
    verify(() => repo.wallet()).called(1);
    expect(vm.balance, 12450);
  });

  test('kategori filtresi', () async {
    final vm = MarketViewModel(repo);
    await vm.load();
    vm.selectCategory('travel');
    expect(vm.visibleItems.map((r) => r.id), ['rwd-kapadokya']);
    vm.selectCategory(null);
    expect(vm.visibleItems, hasLength(3));
  });

  test('"Bakiyen yetiyor" yalnız alınabilenleri gösterir; temizle sıfırlar', () async {
    final vm = MarketViewModel(repo);
    await vm.load();
    vm.setAffordableOnly(true);
    expect(vm.visibleItems.map((r) => r.id), ['rwd-teleferik']);
    expect(vm.canAfford(market.items[1]), isFalse);
    vm.selectCategory('travel');
    expect(vm.visibleItems, isEmpty);
    vm.clearFilters();
    expect(vm.affordableOnly, isFalse);
    expect(vm.categoryId, isNull);
    expect(vm.visibleItems, hasLength(3));
  });

  test('bakiye düşünce uygunluk güncellenir', () async {
    final vm = MarketViewModel(repo);
    await vm.load();
    vm.setAffordableOnly(true);
    repo.balanceNotifier.value = 1000;
    expect(vm.visibleItems, isEmpty);
    vm.dispose();
  });
}
