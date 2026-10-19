import '../../core/network/api_result.dart';
import '../models/notifications/app_notification.dart';
import '../services/notification_service.dart';

abstract interface class NotificationRepository {
  Future<ApiResult<List<AppNotification>>> list({NotificationCategory? category});
  Future<ApiResult<void>> readAll();
}

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._service);

  final NotificationService _service;

  @override
  Future<ApiResult<List<AppNotification>>> list({NotificationCategory? category}) => _service.list(category: category);

  @override
  Future<ApiResult<void>> readAll() => _service.readAll();
}
