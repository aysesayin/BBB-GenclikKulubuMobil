import '../../core/network/api_result.dart';
import '../../core/storage/cache_store.dart';
import '../models/search/search_result.dart';
import '../services/search_service.dart';

abstract interface class SearchRepository {
  Future<ApiResult<List<SearchResult>>> search(String query);
  Future<ApiResult<List<String>>> popularTags();

  /// Cihazda tutulan son aramalar (en yeni başta).
  List<String> recentSearches();
  Future<List<String>> addRecent(String query);
  Future<List<String>> removeRecent(String query);
  Future<void> clearRecent();
}

class SearchRepositoryImpl implements SearchRepository {
  SearchRepositoryImpl(this._service, this._cache);

  final SearchService _service;
  final CacheStore _cache;

  /// `user.` öneki → oturum kapatılınca silinir (KVKK).
  static const _kRecent = 'user.search.recent';

  // TODO(varsayım): Son arama sayısı üst sınırı 8.
  static const maxRecent = 8;

  @override
  Future<ApiResult<List<SearchResult>>> search(String query) => _service.search(query);

  @override
  Future<ApiResult<List<String>>> popularTags() => _service.popular();

  @override
  List<String> recentSearches() => _cache.readList(_kRecent);

  @override
  Future<List<String>> addRecent(String query) async {
    final q = query.trim();
    if (q.isEmpty) return recentSearches();
    final next = [q, ...recentSearches().where((e) => e.toLowerCase() != q.toLowerCase())].take(maxRecent).toList();
    await _cache.writeList(_kRecent, next);
    return next;
  }

  @override
  Future<List<String>> removeRecent(String query) async {
    final next = recentSearches().where((e) => e != query).toList();
    await _cache.writeList(_kRecent, next);
    return next;
  }

  @override
  Future<void> clearRecent() => _cache.remove(_kRecent);
}
