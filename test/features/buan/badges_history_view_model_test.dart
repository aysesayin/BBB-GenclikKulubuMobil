import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan/buan_badge.dart';
import 'package:bbb_genclik_kulubu_app/data/models/buan/buan_transaction.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/badges/view_model/badges_view_model.dart';
import 'package:bbb_genclik_kulubu_app/features/buan/history/view_model/history_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'buan_fixtures.dart';

void main() {
  late MockBuanRepository repo;

  setUpAll(() => registerFallbackValue(BuanTxFilter.all));
  setUp(() => repo = MockBuanRepository());

  group('BadgesViewModel', () {
    test('kazanılanlar önce; sayaç ve ilerleme', () async {
      when(() => repo.badges()).thenAnswer((_) async => const Success(badges));
      final vm = BadgesViewModel(repo);
      await vm.load();
      expect(vm.badges.map((b) => b.id), ['b2', 'b3', 'b1']);
      expect(vm.earnedCount, 2);
      expect(vm.total, 3);
      expect(vm.progress, closeTo(.667, .001));
    });

    test('boş liste → boş durum', () async {
      when(() => repo.badges()).thenAnswer((_) async => const Success(<BuanBadge>[]));
      final vm = BadgesViewModel(repo);
      await vm.load();
      expect(vm.state, isA<ViewEmpty<List<BuanBadge>>>());
    });
  });

  group('HistoryViewModel', () {
    final d16 = DateTime(2026, 10, 16, 9), d15 = DateTime(2026, 10, 15, 19);
    final page1 = BuanTransactionPage(
      items: [tx('a', 750, d16), tx('b', -8000, d15), tx('c', 300, d15)],
      nextCursor: 'c2',
      summary: BuanMonthSummary(month: DateTime(2026, 10), earned: 6850, spent: 8000),
    );
    final page2 = BuanTransactionPage(items: [tx('c', 300, d15), tx('d', 100, DateTime(2026, 10, 14))]);

    void stub() {
      when(
        () => repo.transactions(
          filter: any(named: 'filter'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((inv) async {
        final cursor = inv.namedArguments[#cursor] as String?;
        return Success(cursor == null ? page1 : page2);
      });
    }

    test('ilk sayfa + ay özeti', () async {
      stub();
      final vm = HistoryViewModel(repo);
      await vm.load();
      expect((vm.state as ViewSuccess<List<BuanTransaction>>).data, hasLength(3));
      expect(vm.summary?.earned, 6850);
      expect(vm.hasMore, isTrue);
    });

    test('imleçle sonraki sayfa eklenir, tekrar eden kayıt atlanır', () async {
      stub();
      final vm = HistoryViewModel(repo);
      await vm.load();
      await vm.loadMore();
      verify(() => repo.transactions(filter: BuanTxFilter.all, cursor: 'c2')).called(1);
      final ids = (vm.state as ViewSuccess<List<BuanTransaction>>).data.map((t) => t.id);
      expect(ids, ['a', 'b', 'c', 'd']);
      expect(vm.hasMore, isFalse);
      await vm.loadMore();
      verifyNever(() => repo.transactions(filter: BuanTxFilter.all, cursor: 'c2'));
    });

    test('filtre sunucuya gider ve istemcide de uygulanır', () async {
      stub();
      final vm = HistoryViewModel(repo);
      await vm.load();
      await vm.setFilter(BuanTxFilter.spend);
      verify(() => repo.transactions(filter: BuanTxFilter.spend)).called(1);
      expect((vm.state as ViewSuccess<List<BuanTransaction>>).data.map((t) => t.id), ['b']);
      await vm.setFilter(BuanTxFilter.earn);
      expect((vm.state as ViewSuccess<List<BuanTransaction>>).data.map((t) => t.id), ['a', 'c']);
    });

    test('hata → hata durumu', () async {
      when(
        () => repo.transactions(
          filter: any(named: 'filter'),
          cursor: any(named: 'cursor'),
        ),
      ).thenAnswer((_) async => const Failure(NetworkException()));
      final vm = HistoryViewModel(repo);
      await vm.load();
      expect(vm.state, isA<ViewError<List<BuanTransaction>>>());
    });

    test('günlere göre gruplama', () {
      final groups = HistoryViewModel.groupByDay(page1.items);
      expect(groups.map((g) => g.day), [DateTime(2026, 10, 16), DateTime(2026, 10, 15)]);
      expect(groups[1].items.map((t) => t.id), ['b', 'c']);
    });
  });
}
