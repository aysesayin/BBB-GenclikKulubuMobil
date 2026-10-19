import '../../core/network/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../models/auth/interest_option.dart';

/// Uzak veri kaynağı: ilgi alanı seçenekleri ve kullanıcının seçimi.
class InterestsService {
  InterestsService(this._client);

  final DioClient _client;

  Future<ApiResult<List<InterestOption>>> options() => _client.get(
        ApiEndpoints.interestOptions,
        parse: (d) => Json.list(d, InterestOption.fromJson),
        cacheKey: 'interestOptions',
      );

  Future<ApiResult<List<String>>> mine() => _client.get(
        ApiEndpoints.interests,
        parse: (d) => ((Json.map(d)['ids'] as List?) ?? const []).cast<String>(),
      );

  Future<ApiResult<void>> save(List<String> ids) =>
      _client.put(ApiEndpoints.interests, body: {'ids': ids}, parse: Json.ignore);
}
