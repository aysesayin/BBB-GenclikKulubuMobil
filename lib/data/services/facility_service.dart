import '../../core/network/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../models/services/facility.dart';
import '../models/services/session.dart';
import '../models/services/sports.dart';

/// Hizmetler (havuz, spor okulu, tenis) katalog ve seans uç noktaları.
class FacilityService {
  FacilityService(this._client);

  final DioClient _client;

  Future<ApiResult<PoolCatalog>> pools() =>
      _client.get(ApiEndpoints.pools, parse: (d) => PoolCatalog.fromJson(Json.map(d)), cacheKey: 'svc.pools');

  Future<ApiResult<List<ServiceItem>>> items(String facilityId) => _client.get(
        ApiEndpoints.serviceItems(facilityId),
        parse: (d) => Json.list(d, ServiceItem.fromJson),
        cacheKey: 'svc.items.$facilityId',
      );

  Future<ApiResult<SessionWeek>> sessions(String itemId, {required DateTime from, required DateTime to}) => _client.get(
        ApiEndpoints.sessions(itemId),
        query: {'from': _date(from), 'to': _date(to)},
        parse: (d) => SessionWeek.fromJson(Json.map(d)),
      );

  Future<ApiResult<SportsCatalog>> sportsCatalog() => _client.get(
        ApiEndpoints.sportsBranches,
        parse: (d) => SportsCatalog.fromJson(Json.map(d)),
        cacheKey: 'svc.sports',
      );

  Future<ApiResult<List<TennisProduct>>> tennisProducts() => _client.get(
        ApiEndpoints.tennisProducts,
        parse: (d) => Json.list(d, TennisProduct.fromJson),
        cacheKey: 'svc.tennis',
      );

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
