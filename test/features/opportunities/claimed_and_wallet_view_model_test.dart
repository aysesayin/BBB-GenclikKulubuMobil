import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/opportunities/claim.dart';
import 'package:bbb_genclik_kulubu_app/data/models/opportunities/opportunity.dart';
import 'package:bbb_genclik_kulubu_app/features/opportunities/view_model/claimed_view_model.dart';
import 'package:bbb_genclik_kulubu_app/features/opportunities/view_model/my_opportunities_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'opp_fixtures.dart';

void main() {
  late MockOpportunityRepository repo;
  setUp(() => (repo, _) = mockRepo());

  group('ClaimedViewModel', () {
    test('extra ile gelen sonuç hemen gösterilir, kutlama açık', () async {
      final vm = ClaimedViewModel(repo, 'opp-extrempark', initial: claimOf('opp-extrempark'));
      expect(vm.state, isA<ViewSuccess<ClaimResult>>());
      expect(vm.celebrate, isTrue);
      await vm.load();
      verifyNever(() => repo.mine());
    });

    test('cüzdandan açılış: kutlama yok', () {
      final vm = ClaimedViewModel(repo, 'opp-extrempark', initial: claimOf('opp-extrempark'), fresh: false);
      expect(vm.celebrate, isFalse);
    });

    test('extra yoksa cüzdandan aktif kod çekilir', () async {
      when(() => repo.mine()).thenAnswer((_) async => Success(walletItems));
      final vm = ClaimedViewModel(repo, 'opp-extrempark');
      await vm.load();
      expect(vm.state.dataOrNull?.pinParts, ['K7', 'Q2', 'M8']);
      expect(vm.celebrate, isFalse);
    });

    test('aktif kod yoksa NotFound', () async {
      when(() => repo.mine()).thenAnswer((_) async => Success(walletItems));
      final vm = ClaimedViewModel(repo, 'opp-yok');
      await vm.load();
      expect((vm.state as ViewError).error, isA<NotFoundException>());
    });

    test('kopyalandı durumu', () {
      final vm = ClaimedViewModel(repo, 'x', initial: claimOf('x', type: ClaimType.code));
      vm.markCopied();
      expect(vm.copied, isTrue);
    });

    test('PIN parçalama: 4 hane tek tek', () {
      final c = claimOf('x', type: ClaimType.qr).copyWith(pin: '4729');
      expect(c.pinParts, ['4', '7', '2', '9']);
    });
  });

  group('MyOpportunitiesViewModel', () {
    test('segment sayaçları ve sekme değişimi', () async {
      when(() => repo.mine()).thenAnswer((_) async => Success(walletItems));
      final vm = MyOpportunitiesViewModel(repo);
      await vm.load();
      expect(vm.countOf(WalletStatus.active), 2);
      expect(vm.countOf(WalletStatus.used), 1);
      expect(vm.items.map((w) => w.id), ['w1', 'w2']);
      vm.selectTab(2);
      expect(vm.status, WalletStatus.expired);
      expect(vm.items.single.id, 'w4');
      vm.selectTab(9);
      expect(vm.tab, 2);
    });

    test('ağ hatası', () async {
      when(() => repo.mine()).thenAnswer((_) async => const Failure(NetworkException()));
      final vm = MyOpportunitiesViewModel(repo);
      await vm.load();
      expect(vm.state, isA<ViewError<List<WalletItem>>>());
      expect(vm.items, isEmpty);
    });
  });
}
