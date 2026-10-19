import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/opportunities/opportunity.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/opportunity_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/opportunities/view_model/opportunity_list_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'opp_fixtures.dart';

void main() {
  setUpAll(() => registerFallbackValue(OpportunityFilter.nearby));

  late MockOpportunityRepository repo;

  void stubList(List<Opportunity> items, {int page = 1, int total = 4, int pageSize = 20}) {
    when(
      () => repo.list(
        category: any(named: 'category'),
        filter: any(named: 'filter'),
        page: page,
      ),
    ).thenAnswer(
      (_) async => Success(
        items,
        meta: PageMeta(page: page, pageSize: pageSize, total: total),
      ),
    );
  }

  setUp(() {
    (repo, _) = mockRepo();
    when(() => repo.categories()).thenAnswer((_) async => const Success([OpportunityCategory(id: 'cat-ulasim', label: 'Ulaşım')]));
    when(() => repo.mine()).thenAnswer((_) async => Success(walletItems));
    stubList(demoList);
  });

  OpportunityListViewModel build({bool member = true}) => OpportunityListViewModel(repo, isMember: member, clock: () => testNow);

  test('yükleme: liste, kategoriler ve cüzdan sayacı gelir', () async {
    final vm = build();
    await vm.load();
    await Future<void>.delayed(Duration.zero);
    expect(vm.state, isA<ViewSuccess<List<Opportunity>>>());
    expect(vm.visible, hasLength(4));
    expect(vm.categories.single.id, 'cat-ulasim');
    expect(vm.walletCount, 2);
    expect(vm.count, 4);
  });

  test('misafirde cüzdan çağrılmaz', () async {
    final vm = build(member: false);
    await vm.load();
    verifyNever(() => repo.mine());
    expect(vm.walletCount, isNull);
  });

  test('filtreler istemcide de uygulanır', () async {
    final vm = build();
    await vm.load();

    vm.toggleFilter(OpportunityFilter.favorites);
    await Future<void>.delayed(Duration.zero);
    expect(vm.visible.map((o) => o.id), ['opp-burulas']);

    vm.toggleFilter(OpportunityFilter.ending);
    await Future<void>.delayed(Duration.zero);
    expect(vm.visible.map((o) => o.id), ['opp-extrempark', 'opp-kafe']);

    vm.toggleFilter(OpportunityFilter.nearby);
    await Future<void>.delayed(Duration.zero);
    expect(vm.visible.map((o) => o.id), ['opp-kafe', 'opp-kitapduragi', 'opp-extrempark']);

    vm.toggleFilter(OpportunityFilter.nearby); // aynı filtre → kaldır
    await Future<void>.delayed(Duration.zero);
    expect(vm.filter, isNull);

    vm.selectCategory('cat-kitap');
    await Future<void>.delayed(Duration.zero);
    expect(vm.visible.single.id, 'opp-kitapduragi');
    verify(() => repo.list(category: 'cat-kitap', filter: null, page: 1)).called(1);
  });

  test('favoriler boşsa isEmpty', () async {
    stubList([opp('a'), opp('b')], total: 2);
    final vm = build();
    await vm.load();
    vm.toggleFilter(OpportunityFilter.favorites);
    await Future<void>.delayed(Duration.zero);
    expect(vm.isEmpty, isTrue);
  });

  test('favori iyimser güncellenir, hata olursa geri alınır', () async {
    final vm = build();
    await vm.load();
    when(() => repo.setFavorite('opp-kafe', value: true)).thenAnswer((_) async => const Success(null));
    expect(await vm.toggleFavorite('opp-kafe'), isNull);
    expect(vm.items.firstWhere((o) => o.id == 'opp-kafe').isFavorite, isTrue);

    when(() => repo.setFavorite('opp-kitapduragi', value: true)).thenAnswer((_) async => const Failure(NetworkException()));
    final future = vm.toggleFavorite('opp-kitapduragi');
    expect(vm.items.firstWhere((o) => o.id == 'opp-kitapduragi').isFavorite, isTrue, reason: 'önce iyimser');
    expect(await future, isA<NetworkException>());
    expect(vm.items.firstWhere((o) => o.id == 'opp-kitapduragi').isFavorite, isFalse);
  });

  test('detaydaki favori olayı listeye yansır', () async {
    final (r, events) = mockRepo();
    repo = r;
    when(() => repo.categories()).thenAnswer((_) async => const Success(<OpportunityCategory>[]));
    when(() => repo.mine()).thenAnswer((_) async => Success(walletItems));
    stubList(demoList);
    final vm = build();
    await vm.load();
    events.add(const FavoriteChanged('opp-kafe', isFavorite: true));
    await Future<void>.delayed(Duration.zero);
    expect(vm.items.firstWhere((o) => o.id == 'opp-kafe').isFavorite, isTrue);
  });

  test('sonsuz kaydırma: sonraki sayfa eklenir, tekrarlar ayıklanır', () async {
    stubList(demoList.take(2).toList(), total: 4, pageSize: 2);
    stubList([demoList[1], ...demoList.skip(2)], page: 2, total: 4, pageSize: 2);
    final vm = build();
    await vm.load();
    expect(vm.hasMore, isTrue);
    expect(vm.count, 4, reason: 'sunucu toplamı');
    await vm.loadMore();
    expect(vm.items.map((o) => o.id), ['opp-burulas', 'opp-extrempark', 'opp-kitapduragi', 'opp-kafe']);
    expect(vm.hasMore, isFalse);
    await vm.loadMore();
    verify(
      () => repo.list(
        category: any(named: 'category'),
        filter: any(named: 'filter'),
        page: 2,
      ),
    ).called(1);
  });

  test('hata + önbellek → çevrimdışı içerik', () async {
    when(
      () => repo.list(
        category: any(named: 'category'),
        filter: any(named: 'filter'),
        page: 1,
      ),
    ).thenAnswer((_) async => Failure(const NetworkException(), cached: demoList));
    final vm = build();
    await vm.load();
    expect(vm.state, isA<ViewError<List<Opportunity>>>());
    expect(vm.visible, hasLength(4));
  });
}
