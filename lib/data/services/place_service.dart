import '../../core/network/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../models/places/place.dart';

/// Uzak veri kaynağı: yer / tesis detayı ve yakındaki yerler (G3–G4).
class PlaceService {
  PlaceService(this._client);

  final DioClient _client;

  Future<ApiResult<PlaceDetail>> detail(String id) => _client.get(
        ApiEndpoints.placeDetail(id),
        parse: (d) => PlaceDetail.fromJson(Json.map(d)),
        cacheKey: 'place.$id',
      );

  Future<ApiResult<List<PlaceSummary>>> nearby({required double lat, required double lng}) => _client.get(
        ApiEndpoints.placesNearby,
        query: {'lat': lat.toStringAsFixed(5), 'lng': lng.toStringAsFixed(5)},
        parse: (d) => Json.list(d, PlaceSummary.fromJson),
      );
}
