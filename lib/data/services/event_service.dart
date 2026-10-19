import 'package:intl/intl.dart';

import '../../core/network/api_endpoints.dart';
import '../../core/network/api_result.dart';
import '../../core/network/dio_client.dart';
import '../models/events/event_detail.dart';
import '../models/events/event_item.dart';

/// Uzak veri kaynağı: etkinlikler (G1–G2).
class EventService {
  EventService(this._client);

  final DioClient _client;
  static final _day = DateFormat('yyyy-MM-dd');

  Future<ApiResult<EventFeed>> feed({required DateTime from, required DateTime to, String? categoryId}) => _client.get(
        ApiEndpoints.events,
        query: {'from': _day.format(from), 'to': _day.format(to), 'cat': ?categoryId},
        parse: (d) => EventFeed.fromJson(Json.map(d)),
        cacheKey: 'events',
      );

  Future<ApiResult<EventDetail>> detail(String id) => _client.get(
        ApiEndpoints.eventDetail(id),
        parse: (d) => EventDetail.fromJson(Json.map(d)),
        cacheKey: 'event.$id',
      );

  /// Kota / yaş / kontenjan kontrolü sunucuda yapılır (409 → ConflictException, 403 → ForbiddenException).
  Future<ApiResult<EventApplyResult>> apply(String id, {required String idempotencyKey}) => _client.post(
        ApiEndpoints.applyEvent(id),
        headers: {'Idempotency-Key': idempotencyKey},
        parse: (d) => d is Map ? EventApplyResult.fromJson(Json.map(d)) : const EventApplyResult(),
      );
}
