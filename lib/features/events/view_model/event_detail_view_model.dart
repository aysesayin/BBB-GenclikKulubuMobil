import '../../../core/base/base_view_model.dart';
import '../../../core/base/view_state.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/app_exception.dart';
import '../../../data/models/events/event_detail.dart';
import '../../../data/repositories/event_repository.dart';

/// Alt CTA'nın durumu.
enum EventCta { apply, applied, waitlist, waitlisted, full, closed, quotaBlocked }

enum EventApplyKind { applied, waitlisted, failed }

class EventApplyOutcome {
  const EventApplyOutcome(this.kind, {this.message, this.error});

  final EventApplyKind kind;

  /// Sunucu mesajı ("Başvurun alındı…").
  final String? message;
  final AppException? error;
}

/// G2 · Etkinlik detayı + başvuru. Kota/yaş/kontenjan kontrolü sunucudadır;
/// 409 (ConflictException) / 403 mesajı aynen kullanıcıya gösterilir.
class EventDetailViewModel extends LoadableViewModel<EventDetail> {
  EventDetailViewModel(this._repo, this.eventId, {DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final EventRepository _repo;
  final String eventId;
  final DateTime Function() _clock;

  /// Aynı başvuru niyeti için sabit anahtar (ağ hatasında tekrar denense de tek kayıt).
  late final String _idempotencyKey = 'apply-$eventId-${_clock().microsecondsSinceEpoch}';

  bool _applying = false;
  bool get applying => _applying;

  EventCta get cta {
    final d = state.dataOrNull;
    if (d == null) return EventCta.apply;
    if (d.hasApplied) return EventCta.applied;
    if (d.isWaitlisted) return EventCta.waitlisted;
    if (d.isClosed(_clock())) return EventCta.closed;
    if (d.quota case final q? when !q.eligible) return EventCta.quotaBlocked;
    if (d.isFull) return d.waitlistOpen ? EventCta.waitlist : EventCta.full;
    return EventCta.apply;
  }

  bool get canApply => !_applying && (cta == EventCta.apply || cta == EventCta.waitlist);

  @override
  Future<ApiResult<EventDetail>> fetch() => _repo.detail(eventId);

  /// Başvurur; ekranda gösterilecek sonucu döner (uygun değilse null).
  Future<EventApplyOutcome?> apply() async {
    final current = state.dataOrNull;
    if (current == null || !canApply) return null;
    _applying = true;
    notify();
    final result = await _repo.apply(eventId, idempotencyKey: _idempotencyKey);
    _applying = false;
    if (isDisposed) return null;
    switch (result) {
      case Success(:final data):
        final waitlisted = data.status == 'waitlisted';
        state = ViewSuccess(current.copyWith(
          applicationStatus: waitlisted ? 'waitlisted' : 'applied',
          attendeeCount: data.attendeeCount ?? (waitlisted ? current.attendeeCount : current.attendeeCount + 1),
        ));
        return EventApplyOutcome(waitlisted ? EventApplyKind.waitlisted : EventApplyKind.applied, message: data.message);
      case Failure(:final error):
        notify();
        return EventApplyOutcome(EventApplyKind.failed, error: error);
    }
  }
}
