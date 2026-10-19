import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/services/sports.dart';
import 'package:bbb_genclik_kulubu_app/features/services/sports_school/view_model/sports_school_view_model.dart';
import 'package:bbb_genclik_kulubu_app/features/services/tennis/view_model/tennis_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'svc_fixtures.dart';

void main() {
  late MockFacilityRepository repo;

  const catalog = SportsCatalog(
    terms: [
      SportTerm(id: 'guz', label: 'Güz'),
      SportTerm(id: 'kis', label: 'Kış'),
    ],
    ageGroups: [
      AgeGroup(id: 'a6', label: '6–9'),
      AgeGroup(id: 'a10', label: '10–14'),
    ],
    branches: [
      SportBranch(
        id: 'yuzme',
        name: 'Yüzme',
        offers: [
          BranchOffer(termId: 'guz', ageGroupId: 'a6', itemId: 'itm-y-1', left: 12),
          BranchOffer(termId: 'kis', ageGroupId: 'a10', itemId: 'itm-y-2', left: 0),
        ],
      ),
      SportBranch(
        id: 'judo',
        name: 'Judo',
        offers: [BranchOffer(termId: 'guz', ageGroupId: 'a6', itemId: 'itm-j-1', left: 2)],
      ),
    ],
  );

  setUp(() {
    repo = MockFacilityRepository();
    when(() => repo.sportsCatalog()).thenAnswer((_) async => const Success(catalog));
  });

  group('SportsSchoolViewModel', () {
    test('ilk dönem ve yaş grubu seçilir; branş grupları filtrelenir', () async {
      final vm = SportsSchoolViewModel(repo);
      await vm.load();
      expect(vm.termId, 'guz');
      expect(vm.ageGroupId, 'a6');
      final tiles = vm.branches;
      expect(tiles.map((t) => t.offer?.itemId), ['itm-y-1', 'itm-j-1']);
      expect(tiles.map((t) => t.level), [QuotaLevel.plenty, QuotaLevel.last]);
    });

    test('filtre değişince grup yoksa none, kontenjan 0 ise full', () async {
      final vm = SportsSchoolViewModel(repo);
      await vm.load();
      vm.selectTerm('kis');
      vm.selectAgeGroup('a10');
      expect(vm.branches.map((t) => t.level), [QuotaLevel.full, QuotaLevel.none]);
    });

    test('sekme değişimi', () async {
      final vm = SportsSchoolViewModel(repo);
      await vm.load();
      vm.setTab(1);
      expect(vm.tab, 1);
    });

    test('quotaLevelOf eşikleri', () {
      expect(quotaLevelOf(null), QuotaLevel.none);
      expect(quotaLevelOf(0), QuotaLevel.full);
      expect(quotaLevelOf(3), QuotaLevel.last);
      expect(quotaLevelOf(4), QuotaLevel.plenty);
    });

    test('hata → ViewError', () async {
      when(() => repo.sportsCatalog()).thenAnswer((_) async => const Failure(NetworkException()));
      final vm = SportsSchoolViewModel(repo);
      await vm.load();
      expect(vm.state, isA<ViewError<SportsCatalog>>());
      expect(vm.branches, isEmpty);
    });
  });

  group('TennisViewModel', () {
    const products = [
      TennisProduct(id: 't1', itemId: 'itm-t1', name: 'Özel ders'),
      TennisProduct(id: 't2', itemId: 'itm-t2', name: 'Takım alt yapı', ageGroupIds: ['a6', 'a10']),
      TennisProduct(id: 't3', itemId: 'itm-t3', name: 'Yetişkin kursu', ageGroupIds: ['yetiskin']),
    ];

    test('yaş grubuna göre görünür ürünler', () async {
      when(() => repo.tennisProducts()).thenAnswer((_) async => const Success(products));
      final vm = TennisViewModel(repo);
      await vm.load();
      expect(vm.visible('a6').map((p) => p.id), ['t1', 't2']);
      expect(vm.visible('yetiskin').map((p) => p.id), ['t1', 't3']);
      expect(vm.visible(null), hasLength(3));
    });

    test('boş liste → ViewEmpty', () async {
      when(() => repo.tennisProducts()).thenAnswer((_) async => const Success(<TennisProduct>[]));
      final vm = TennisViewModel(repo);
      await vm.load();
      expect(vm.state, isA<ViewEmpty<List<TennisProduct>>>());
    });
  });
}
