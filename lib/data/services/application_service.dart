import '../../core/network/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../models/services/application.dart';

/// Başvurularım: liste (durum filtresi) ve iptal.
class ApplicationService {
  ApplicationService(this._client);

  final DioClient _client;

  /// [status]: `active` | `past` | null (tümü).
  Future<ApiResult<List<Application>>> list({String? status}) => _client.get(
        ApiEndpoints.applications,
        query: status == null ? null : {'status': status},
        parse: (d) => Json.list(d, Application.fromJson),
        cacheKey: 'svc.applications',
      );

  Future<ApiResult<CancelResult>> cancel(String id) =>
      _client.post(ApiEndpoints.cancelApplication(id), parse: (d) => CancelResult.fromJson(Json.map(d)));
}
