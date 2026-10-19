import '../../core/network/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../models/opportunities/claim.dart';
import '../models/opportunities/opportunity.dart';

/// Uzak veri kaynağı: fırsatlar (C1–C4).
class OpportunityService {
  OpportunityService(this._client);

  final DioClient _client;

  /// `GET /opportunities?cat=&filter=&page=&pageSize=` — sayfalama `meta` ile.
  Future<ApiResult<List<Opportunity>>> list({String? category, OpportunityFilter? filter, int page = 1, int pageSize = 20}) => _client.get(
    ApiEndpoints.opportunities,
    query: {'page': page, 'pageSize': pageSize, 'cat': ?category, if (filter != null) 'filter': filter.query},
    parse: (d) => Json.list(d, Opportunity.fromJson),
    // Yalnız ilk sayfa çevrimdışı için saklanır.
    cacheKey: page == 1 ? 'opportunities' : null,
  );

  Future<ApiResult<List<OpportunityCategory>>> categories() => _client.get(
    ApiEndpoints.opportunityCategories,
    parse: (d) => Json.list(d, OpportunityCategory.fromJson),
    cacheKey: 'opportunities.categories',
  );

  Future<ApiResult<OpportunityDetail>> detail(String id) =>
      _client.get(ApiEndpoints.opportunityDetail(id), parse: (d) => OpportunityDetail.fromJson(Json.map(d)), cacheKey: 'opportunity.$id');

  // TODO(varsayım): favori ekleme/çıkarma tek uçta `{isFavorite: bool}` gövdesiyle yapılır.
  Future<ApiResult<void>> setFavorite(String id, {required bool value}) =>
      _client.post(ApiEndpoints.favoriteOpportunity(id), body: {'isFavorite': value}, parse: Json.ignore);

  Future<ApiResult<ClaimResult>> claim(String id, {required String idempotencyKey}) => _client.post(
    ApiEndpoints.claimOpportunity(id),
    headers: {'Idempotency-Key': idempotencyKey},
    parse: (d) => ClaimResult.fromJson(Json.map(d)),
  );

  /// Cüzdan: tüm durumlar tek çağrıda (sayaçlar için); çevrimdışı da açılsın diye önbellekli.
  Future<ApiResult<List<WalletItem>>> mine() =>
      _client.get(ApiEndpoints.myOpportunities, parse: (d) => Json.list(d, WalletItem.fromJson), cacheKey: 'opportunities.mine');
}
