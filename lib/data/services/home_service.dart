import '../../core/network/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../models/home/home_feed.dart';

/// Keşfet: tüm bloklar tek çağrıda (`GET /home`). Çevrimdışı için önbelleğe yazılır.
class HomeService {
  HomeService(this._client);

  final DioClient _client;

  static const cacheKey = 'home';

  Future<ApiResult<HomeFeed>> home() => _client.get(ApiEndpoints.home, parse: (d) => HomeFeed.fromJson(Json.map(d)), cacheKey: cacheKey);
}
