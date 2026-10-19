import '../../core/network/api_result.dart';
import '../models/map/map_pin.dart';
import '../services/map_service.dart';

abstract interface class MapRepository {
  Future<ApiResult<MapPinsData>> pins({required MapLayer layer, String? categoryId, MapBounds? bounds});
}

class MapRepositoryImpl implements MapRepository {
  MapRepositoryImpl(this._service);

  final MapService _service;

  @override
  Future<ApiResult<MapPinsData>> pins({required MapLayer layer, String? categoryId, MapBounds? bounds}) =>
      _service.pins(layer: layer, categoryId: categoryId, bounds: bounds);
}
