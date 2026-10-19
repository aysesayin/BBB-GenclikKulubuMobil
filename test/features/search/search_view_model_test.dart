import 'dart:convert';
import 'dart:io';

import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/search/search_result.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/search_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/search/view_model/search_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSearchRepository extends Mock implements SearchRepository {}

const _items = [
  SearchResult(id: 'rwd-teleferik', type: SearchResultType.reward, title: 'Teleferik + sucuk ekmek'),
  SearchResult(id: 'opp-teleferik', type: SearchResultType.opportunity, title: 'Teleferik gidiş-dönüş %30'),
  SearchResult(id: 'evt-1', type: SearchResultType.event, title: 'Teleferikle Uludağ Gezisi'),
  SearchResult(id: 'plc-1', type: SearchResultType.place, title: 'Teferrüç İstasyonu', subtitle: 'Teleferik · 3,1 km'),
  SearchResult(id: 'plc-2', type: SearchResultType.place, title: 'Şehir Tiyatrosu'),
];

void main() {
  late _MockSearchRepository repo;

  setUp(() {
    repo = _MockSearchRepository();
    when(() => repo.search(any())).thenAnswer((_) async => const Success(_items));
    when(() => repo.recentSearches()).thenReturn(['Yüzme kursu']);
    when(() => repo.popularTags()).thenAnswer((_) async => const Success(['Teleferik', 'Konser']));
    when(() => repo.addRecent(any())).thenAnswer((i) async => [i.positionalArguments.first as String, 'Yüzme kursu']);
    when(() => repo.removeRecent(any())).thenAnswer((_) async => const []);
    when(() => repo.clearRecent()).thenAnswer((_) async {});
  });

  test('init son aramaları ve popüler etiketleri yükler', () async {
    final vm = SearchViewModel(repo);
    await vm.init();
    expect(vm.recent, ['Yüzme kursu']);
    expect(vm.popular, ['Teleferik', 'Konser']);
  });

  testWidgets('250 ms debounce: hızlı yazımda tek istek', (tester) async {
    final vm = SearchViewModel(repo);
    vm.onQueryChanged('T');
    await tester.pump(const Duration(milliseconds: 100));
    vm.onQueryChanged('Tel');
    await tester.pump(const Duration(milliseconds: 100));
    vm.onQueryChanged('Teleferik');
    await tester.pump(const Duration(milliseconds: 249));
    verifyNever(() => repo.search(any()));
    await tester.pump(const Duration(milliseconds: 2));
    await tester.pump();
    verify(() => repo.search('Teleferik')).called(1);
    expect(vm.results, isA<ViewSuccess<List<SearchResult>>>());
  });

  test('sonuçlar istemcide süzülür ve gruplanır', () async {
    final vm = SearchViewModel(repo);
    await vm.submit('teleferik');
    expect(vm.countFor(SearchTab.all), 4);
    expect(vm.countFor(SearchTab.opportunities), 2);
    expect(vm.countFor(SearchTab.events), 1);
    expect(vm.countFor(SearchTab.places), 1);
    expect(vm.groups.map((g) => g.tab), [SearchTab.opportunities, SearchTab.events, SearchTab.places]);

    vm.selectTab(SearchTab.places);
    expect(vm.groups.single.items.single.id, 'plc-1');
  });

  test('submit sorguyu son aramalara ekler', () async {
    final vm = SearchViewModel(repo);
    await vm.submit('Konser');
    verify(() => repo.addRecent('Konser')).called(1);
    expect(vm.recent.first, 'Konser');
  });

  testWidgets('temizle → boşta, bekleyen debounce iptal', (tester) async {
    final vm = SearchViewModel(repo);
    vm.onQueryChanged('Tele');
    vm.clear();
    await tester.pump(const Duration(seconds: 1));
    verifyNever(() => repo.search(any()));
    expect(vm.hasQuery, isFalse);
    expect(vm.results, isA<ViewIdle<List<SearchResult>>>());
  });

  test('eski yanıt yeni sorgunun üzerine yazmaz', () async {
    final vm = SearchViewModel(repo, debounce: Duration.zero);
    when(() => repo.search('a')).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      return const Success([SearchResult(id: 'x', type: SearchResultType.place, title: 'a eski')]);
    });
    when(() => repo.search('Şehir')).thenAnswer((_) async => const Success(_items));
    final first = vm.submit('a');
    await vm.submit('Şehir');
    await first;
    expect(vm.results.dataOrNull?.single.id, 'plc-2');
  });

  test('hata → ViewError', () async {
    when(() => repo.search(any())).thenAnswer((_) async => const Failure(NetworkException()));
    final vm = SearchViewModel(repo);
    await vm.submit('x');
    expect(vm.results, isA<ViewError<List<SearchResult>>>());
  });

  test('son arama silme ve hepsini temizleme', () async {
    final vm = SearchViewModel(repo);
    await vm.init();
    await vm.removeRecent('Yüzme kursu');
    expect(vm.recent, isEmpty);
    await vm.clearRecent();
    verify(() => repo.clearRecent()).called(1);
  });

  test('ödül de "Fırsatlar" sekmesine düşer', () {
    expect(SearchViewModel.tabOf(SearchResultType.reward), SearchTab.opportunities);
    expect(SearchViewModel.filter(_items, 'TELEFERİK').length, 4);
  });

  test('mock search.json modele çözülür', () {
    final json = jsonDecode(File('assets/mock/search.json').readAsStringSync()) as Map<String, dynamic>;
    final items = ((json['data'] as Map)['items'] as List).map((e) => SearchResult.fromJson(e as Map<String, dynamic>)).toList();
    expect(SearchViewModel.filter(items, 'Teleferik').length, greaterThanOrEqualTo(6));
  });
}
