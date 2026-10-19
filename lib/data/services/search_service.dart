import 'package:dio/dio.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../models/search/search_result.dart';

/// Tek arama: fırsat / etkinlik / yer / tesis.
class SearchService {
  SearchService(this._client);

  final DioClient _client;

  Future<ApiResult<List<SearchResult>>> search(String query, {List<String>? types, CancelToken? cancelToken}) => _client.get(
    ApiEndpoints.search,
    query: {'q': query, if (types != null && types.isNotEmpty) 'types': types.join(',')},
    parse: (d) => Json.list(d, SearchResult.fromJson),
    cancelToken: cancelToken,
  );

  Future<ApiResult<List<String>>> popular() => _client.get(
    ApiEndpoints.searchPopular,
    parse: (d) => [for (final e in (d is Map ? d['items'] : d) as List? ?? const []) e.toString()],
    cacheKey: 'search.popular',
  );
}
