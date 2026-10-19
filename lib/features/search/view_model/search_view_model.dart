import 'dart:async';

import '../../../core/base/base_view_model.dart';
import '../../../core/base/view_state.dart';
import '../../../core/network/api_result.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/search/search_result.dart';
import '../../../data/repositories/search_repository.dart';

/// Sonuç sekmeleri (Tümü · Fırsatlar · Etkinlikler · Yerler).
enum SearchTab { all, opportunities, events, places }

/// Başlıklı sonuç grubu ("FIRSATLAR" …).
class SearchGroup {
  const SearchGroup(this.tab, this.items);
  final SearchTab tab;
  final List<SearchResult> items;
}

/// B2 · Arama: 250 ms debounce, cihazda son aramalar, popüler etiketler, gruplu sonuçlar.
class SearchViewModel extends BaseViewModel {
  SearchViewModel(this._repo, {this.debounce = const Duration(milliseconds: 250)});

  final SearchRepository _repo;
  final Duration debounce;

  Timer? _timer;
  int _seq = 0;

  String _query = '';
  String get query => _query;
  bool get hasQuery => _query.trim().isNotEmpty;

  List<String> _recent = const [];
  List<String> get recent => _recent;

  List<String> _popular = const [];
  List<String> get popular => _popular;

  ViewState<List<SearchResult>> _results = const ViewIdle();
  ViewState<List<SearchResult>> get results => _results;

  SearchTab _tab = SearchTab.all;
  SearchTab get tab => _tab;

  Future<void> init() async {
    _recent = _repo.recentSearches();
    notify();
    if (await _repo.popularTags() case Success(:final data)) {
      _popular = data;
      notify();
    }
  }

  /// Her tuş vuruşunda çağrılır; istek [debounce] sonra atılır.
  void onQueryChanged(String value) {
    _timer?.cancel();
    _query = value;
    _tab = SearchTab.all;
    if (!hasQuery) {
      _seq++;
      _results = const ViewIdle();
      notify();
      return;
    }
    notify();
    _timer = Timer(debounce, () => _run(value));
  }

  /// Klavyeden "ara", etiket ya da son aramaya dokunma: hemen arar ve kaydeder.
  Future<void> submit(String value) async {
    _timer?.cancel();
    _query = value;
    _tab = SearchTab.all;
    if (!hasQuery) return onQueryChanged(value);
    await rememberQuery();
    await _run(value);
  }

  void clear() => onQueryChanged('');

  /// Bir sonuç açıldığında sorguyu son aramalara ekler.
  Future<void> rememberQuery() async {
    if (!hasQuery) return;
    _recent = await _repo.addRecent(_query);
    notify();
  }

  Future<void> removeRecent(String value) async {
    _recent = await _repo.removeRecent(value);
    notify();
  }

  Future<void> clearRecent() async {
    await _repo.clearRecent();
    _recent = const [];
    notify();
  }

  void selectTab(SearchTab value) {
    if (_tab == value) return;
    _tab = value;
    notify();
  }

  Future<void> _run(String value) async {
    final seq = ++_seq;
    _results = ViewLoading(previous: _results.dataOrNull);
    notify();
    final r = await _repo.search(value.trim());
    if (isDisposed || seq != _seq) return;
    _results = switch (r) {
      Success(:final data) => ViewSuccess(filter(data, value)),
      Failure(:final error) => ViewError(error),
    };
    notify();
  }

  List<SearchResult> get _all => _results.dataOrNull ?? const [];

  int countFor(SearchTab t) => t == SearchTab.all ? _all.length : _all.where((e) => tabOf(e.type) == t).length;

  /// Seçili sekmeye göre boş olmayan gruplar (Fırsatlar → Etkinlikler → Yerler).
  List<SearchGroup> get groups => [
    for (final t in const [SearchTab.opportunities, SearchTab.events, SearchTab.places])
      if (_tab == SearchTab.all || _tab == t) SearchGroup(t, _all.where((e) => tabOf(e.type) == t).toList()),
  ].where((g) => g.items.isNotEmpty).toList();

  static SearchTab tabOf(SearchResultType t) => switch (t) {
    SearchResultType.opportunity || SearchResultType.reward => SearchTab.opportunities,
    SearchResultType.event => SearchTab.events,
    SearchResultType.place => SearchTab.places,
  };

  /// Sunucu zaten süzer; mock tüm listeyi döndüğü için istemcide de süzülür.
  // TODO(varsayım): Gerçek API'de bulanık eşleşmeleri gizlememesi için istemci süzgeci yalnız mock modunda gerekebilir.
  static List<SearchResult> filter(List<SearchResult> items, String query) {
    final q = trLower(query.trim());
    if (q.isEmpty) return items;
    return items.where((e) => trLower('${e.title} ${e.subtitle}').contains(q)).toList();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
