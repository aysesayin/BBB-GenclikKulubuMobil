import '../../core/network/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../models/notifications/app_notification.dart';

/// Bildirim merkezi.
class NotificationService {
  NotificationService(this._client);

  final DioClient _client;

  /// [category] null → tümü.
  Future<ApiResult<List<AppNotification>>> list({NotificationCategory? category}) => _client.get(
    ApiEndpoints.notifications,
    query: category == null ? null : {'cat': category.name},
    parse: (d) => Json.list(d, AppNotification.fromJson),
    cacheKey: 'notifications',
  );

  Future<ApiResult<void>> readAll() => _client.post(ApiEndpoints.notificationsReadAll, parse: Json.ignore);
}
