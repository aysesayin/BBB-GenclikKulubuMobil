import '../../core/network/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../models/app/app_config.dart';

/// Uzak veri kaynağı: sistem uç noktaları.
class AppService {
  AppService(this._client);

  final DioClient _client;

  Future<ApiResult<AppConfig>> config() =>
      _client.get(ApiEndpoints.appConfig, parse: (d) => AppConfig.fromJson(Json.map(d)), cacheKey: 'appConfig');

  /// Yasal metin (KVKK, Açık Rıza, Kayıt Şartları…) — panelden yönetilir.
  Future<ApiResult<String>> legalText(String key) =>
      _client.get(ApiEndpoints.legalText(key), parse: (d) => Json.map(d)['body'] as String, cacheKey: 'legal.$key');
}
