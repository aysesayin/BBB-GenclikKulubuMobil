import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/events/event_detail.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/event_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/events/view_model/event_detail_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements EventRepository {}

EventDetail _detail({
  int count = 34,
  int capacity = 50,
  bool waitlist = false,
  DateTime? deadline,
  EventQuota? quota,
  String status = 'none',
}) => EventDetail(
  id: 'evt-uludag-yuruyus',
  title: 'Uludağ Doğa Yürüyüşü',
  categoryId: 'doga',
  categoryLabel: 'Doğa ve Macera',
  startsAt: DateTime(2026, 10, 18, 8, 30),
  capacity: capacity,
  attendeeCount: count,
  waitlistOpen: waitlist,
  applyDeadline: deadline,
  quota: quota,
  applicationStatus: status,
);

void main() {
  final now = DateTime(2026, 10, 16, 12);
  late _MockRepo repo;
  late EventDetailViewModel vm;

  setUp(() {
    repo = _MockRepo();
    vm = EventDetailViewModel(repo, 'evt-uludag-yuruyus', clock: () => now);
  });

  Future<void> loadWith(EventDetail d) async {
    when(() => repo.detail('evt-uludag-yuruyus')).thenAnswer((_) async => Success(d));
    await vm.load();
  }

  void stubApply(ApiResult<EventApplyResult> r) =>
      when(() => repo.apply('evt-uludag-yuruyus', idempotencyKey: any(named: 'idempotencyKey'))).thenAnswer((_) async => r);

  test('başvuru başarılı → applied, katılımcı +1, sunucu mesajı', () async {
    await loadWith(_detail());
    expect(vm.cta, EventCta.apply);
    stubApply(const Success(EventApplyResult(message: 'Başvurun alındı')));

    final outcome = await vm.apply();

    expect(outcome!.kind, EventApplyKind.applied);
    expect(outcome.message, 'Başvurun alındı');
    expect(vm.cta, EventCta.applied);
    expect(vm.state.dataOrNull!.attendeeCount, 35);
    expect(vm.applying, isFalse);
  });

  test('sunucu sayıyı verirse o kullanılır', () async {
    await loadWith(_detail());
    stubApply(const Success(EventApplyResult(attendeeCount: 40)));
    await vm.apply();
    expect(vm.state.dataOrNull!.attendeeCount, 40);
  });

  test('dolu + bekleme listesi → waitlist, sonuç waitlisted (sayı değişmez)', () async {
    await loadWith(_detail(count: 50, waitlist: true));
    expect(vm.cta, EventCta.waitlist);
    stubApply(const Success(EventApplyResult(status: 'waitlisted')));

    final outcome = await vm.apply();

    expect(outcome!.kind, EventApplyKind.waitlisted);
    expect(vm.cta, EventCta.waitlisted);
    expect(vm.state.dataOrNull!.attendeeCount, 50);
  });

  test('kota çakışması (409) → failed + ConflictException mesajı, durum değişmez', () async {
    await loadWith(_detail());
    stubApply(const Failure(ConflictException(serverMessage: '6 ayda 1 katılım hakkın doldu')));

    final outcome = await vm.apply();

    expect(outcome!.kind, EventApplyKind.failed);
    expect(outcome.error, isA<ConflictException>());
    expect(outcome.error!.serverMessage, '6 ayda 1 katılım hakkın doldu');
    expect(vm.cta, EventCta.apply);
    expect(vm.applying, isFalse);
  });

  test('tekrar denemede aynı Idempotency-Key gönderilir', () async {
    await loadWith(_detail());
    stubApply(const Failure(NetworkException()));
    await vm.apply();
    await vm.apply();

    final keys = verify(() => repo.apply('evt-uludag-yuruyus', idempotencyKey: captureAny(named: 'idempotencyKey'))).captured;
    expect(keys, hasLength(2));
    expect(keys.first, keys.last);
  });

  test('CTA durumları: dolu, kapandı, kota, zaten başvurulmuş', () async {
    await loadWith(_detail(count: 50));
    expect(vm.cta, EventCta.full);

    await loadWith(_detail(deadline: DateTime(2026, 10, 15)));
    expect(vm.cta, EventCta.closed);

    await loadWith(_detail(deadline: DateTime(2026, 10, 16)));
    expect(vm.cta, EventCta.apply, reason: 'yalnız tarih → gün sonuna kadar açık');

    await loadWith(_detail(quota: const EventQuota(title: '6 ayda 1', eligible: false)));
    expect(vm.cta, EventCta.quotaBlocked);

    await loadWith(_detail(status: 'applied'));
    expect(vm.cta, EventCta.applied);
  });

  test('uygun değilse apply repo çağırmaz', () async {
    await loadWith(_detail(count: 50));
    expect(await vm.apply(), isNull);
    verifyNever(() => repo.apply(any(), idempotencyKey: any(named: 'idempotencyKey')));
  });
}
