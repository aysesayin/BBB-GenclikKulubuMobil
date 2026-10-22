import '../../core/network/api_result.dart';
import '../models/services/facility.dart';
import '../models/services/session.dart';
import '../models/services/sports.dart';
import '../services/facility_service.dart';

/// Havuz / spor okulu / tenis kataloğu ve haftalık seanslar.
abstract interface class FacilityRepository {
  Future<ApiResult<PoolCatalog>> pools();
  Future<ApiResult<List<ServiceItem>>> items(String facilityId);
  Future<ApiResult<SessionWeek>> sessions(String itemId, {required DateTime from, required DateTime to});
  Future<ApiResult<WaitlistResult>> joinWaitlist(String itemId, {required String sessionId});
  Future<ApiResult<SportsCatalog>> sportsCatalog();
  Future<ApiResult<List<TennisProduct>>> tennisProducts();
}

class FacilityRepositoryImpl implements FacilityRepository {
  FacilityRepositoryImpl(this._service);

  final FacilityService _service;

  @override
  Future<ApiResult<PoolCatalog>> pools() => _service.pools();

  @override
  Future<ApiResult<List<ServiceItem>>> items(String facilityId) => _service.items(facilityId);

  @override
  Future<ApiResult<SessionWeek>> sessions(String itemId, {required DateTime from, required DateTime to}) =>
      _service.sessions(itemId, from: from, to: to);

  @override
  Future<ApiResult<WaitlistResult>> joinWaitlist(String itemId, {required String sessionId}) =>
      _service.joinWaitlist(itemId, sessionId: sessionId);

  @override
  Future<ApiResult<SportsCatalog>> sportsCatalog() => _service.sportsCatalog();

  @override
  Future<ApiResult<List<TennisProduct>>> tennisProducts() => _service.tennisProducts();
}
