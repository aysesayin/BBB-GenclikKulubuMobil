import '../../core/network/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../models/map/map_pin.dart';

/// Uzak veri kaynağı: katmanlı harita pinleri (G3).
class MapService {
  MapService(this._client);

  final DioClient _client;

  Future<ApiResult<MapPinsData>> pins({required MapLayer layer, String? categoryId, MapBounds? bounds}) => _client.get(
        ApiEndpoints.mapPins,
        query: {'layer': layer.apiValue, 'cat': ?categoryId, 'bbox': ?bounds?.query},
        parse: (d) => MapPinsData.fromJson(Json.map(d)),
      );
}
