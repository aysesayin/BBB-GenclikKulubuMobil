import '../../core/network/api_result.dart';
import '../models/events/event_detail.dart';
import '../models/events/event_item.dart';
import '../services/event_service.dart';

abstract interface class EventRepository {
  /// [from]–[to] aralığındaki etkinlikler + kategori listesi.
  Future<ApiResult<EventFeed>> feed({required DateTime from, required DateTime to, String? categoryId});
  Future<ApiResult<EventDetail>> detail(String id);
  Future<ApiResult<EventApplyResult>> apply(String id, {required String idempotencyKey});
}

class EventRepositoryImpl implements EventRepository {
  EventRepositoryImpl(this._service);

  final EventService _service;

  @override
  Future<ApiResult<EventFeed>> feed({required DateTime from, required DateTime to, String? categoryId}) =>
      _service.feed(from: from, to: to, categoryId: categoryId);

  @override
  Future<ApiResult<EventDetail>> detail(String id) => _service.detail(id);

  @override
  Future<ApiResult<EventApplyResult>> apply(String id, {required String idempotencyKey}) =>
      _service.apply(id, idempotencyKey: idempotencyKey);
}
