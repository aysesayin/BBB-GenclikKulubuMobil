import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/services/facility.dart';
import 'package:bbb_genclik_kulubu_app/features/services/pool/view_model/pools_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'svc_fixtures.dart';

void main() {
  late MockFacilityRepository repo;

  const catalog = PoolCatalog(
    items: [
      Pool(id: 'fac-fethiye', name: 'Fethiye'),
      Pool(id: 'fac-mihrapli', name: 'Mihraplı'),
    ],
  );
  const fethiye = [ServiceItem(id: 'itm-fethiye-gunluk', title: 'Günlük Giriş', price: 100)];
  const mihrapli = [ServiceItem(id: 'itm-mihrapli-kurs', title: 'Yüzme Kursu', price: 900, priceUnit: PriceUnit.term)];

  setUp(() {
    repo = MockFacilityRepository();
    when(() => repo.pools()).thenAnswer((_) async => const Success(catalog));
    when(() => repo.items('fac-fethiye')).thenAnswer((_) async => const Success(fethiye));
    when(() => repo.items('fac-mihrapli')).thenAnswer((_) async => const Success(mihrapli));
  });

  test('yüklenince ilk havuz seçilir ve hizmetleri gelir', () async {
    final vm = PoolsViewModel(repo);
    await vm.load();
    expect(vm.state, isA<ViewSuccess<PoolCatalog>>());
    expect(vm.selectedPool?.name, 'Fethiye');
    expect(vm.items.dataOrNull, fethiye);
  });

  test('havuz değişince o havuzun hizmetleri yüklenir', () async {
    final vm = PoolsViewModel(repo);
    await vm.load();
    await vm.select('fac-mihrapli');
    expect(vm.selectedId, 'fac-mihrapli');
    expect(vm.items.dataOrNull, mihrapli);
    verify(() => repo.items('fac-mihrapli')).called(1);
  });

  test('aynı havuz tekrar seçilirse istek atılmaz', () async {
    final vm = PoolsViewModel(repo);
    await vm.load();
    await vm.select('fac-fethiye');
    verify(() => repo.items('fac-fethiye')).called(1);
  });

  test('boş hizmet listesi → ViewEmpty', () async {
    when(() => repo.items('fac-fethiye')).thenAnswer((_) async => const Success(<ServiceItem>[]));
    final vm = PoolsViewModel(repo);
    await vm.load();
    expect(vm.items, isA<ViewEmpty<List<ServiceItem>>>());
  });

  test('havuz listesi hatası → ViewError, hizmet isteği yok', () async {
    when(() => repo.pools()).thenAnswer((_) async => const Failure(NetworkException()));
    final vm = PoolsViewModel(repo);
    await vm.load();
    expect(vm.state, isA<ViewError<PoolCatalog>>());
    verifyNever(() => repo.items(any()));
  });
}
