import '../../core/network/api_result.dart';
import '../models/places/place.dart';
import '../services/place_service.dart';

abstract interface class PlaceRepository {
  Future<ApiResult<PlaceDetail>> detail(String id);
  Future<ApiResult<List<PlaceSummary>>> nearby({required double lat, required double lng});
}

class PlaceRepositoryImpl implements PlaceRepository {
  PlaceRepositoryImpl(this._service);

  final PlaceService _service;

  @override
  Future<ApiResult<PlaceDetail>> detail(String id) => _service.detail(id);

  @override
  Future<ApiResult<List<PlaceSummary>>> nearby({required double lat, required double lng}) =>
      _service.nearby(lat: lat, lng: lng);
}
