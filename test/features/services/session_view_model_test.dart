import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/services/cart.dart';
import 'package:bbb_genclik_kulubu_app/data/models/services/facility.dart';
import 'package:bbb_genclik_kulubu_app/data/models/services/session.dart';
import 'package:bbb_genclik_kulubu_app/features/services/session/view_model/session_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'svc_fixtures.dart';

void main() {
  late MockFacilityRepository repo;
  late MockCartRepository cart;
  late FakeClock clock;

  SessionViewModel build() => SessionViewModel(repo, cart, itemId: 'itm-fethiye-gunluk', now: clock.call, pollInterval: null);

  void stubWeek(SessionWeek w) => when(
    () => repo.sessions(
      any(),
      from: any(named: 'from'),
      to: any(named: 'to'),
    ),
  ).thenAnswer((_) async => Success(w));

  void stubHold(ApiResult<CartHold> r) => when(
    () => cart.hold(
      itemId: any(named: 'itemId'),
      sessionId: any(named: 'sessionId'),
      participantId: any(named: 'participantId'),
      swimConfirmed: any(named: 'swimConfirmed'),
    ),
  ).thenAnswer((_) async => r);

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() {
    repo = MockFacilityRepository();
    cart = MockCartRepository();
    clock = FakeClock(kNow);
    stubWeek(sessionWeek());
  });

  group('ızgara', () {
    test('hafta pazartesiden başlar, 7 gün ve sıralı saat satırları', () async {
      final vm = build();
      await vm.load();
      expect(vm.weekStart, DateTime(2026, 10, 12));
      expect(vm.days, hasLength(7));
      expect(vm.rowMinutes, [8 * 60, 10 * 60, 14 * 60, 18 * 60]);
      verify(() => repo.sessions('itm-fethiye-gunluk', from: DateTime(2026, 10, 12), to: DateTime(2026, 10, 18))).called(1);
    });

    test('hücre türleri: tatil, iptal, dolu, geçmiş, açık', () async {
      final vm = build();
      await vm.load();
      final days = vm.days;
      expect(vm.kindOf(vm.slotAt(days[3].date, 600), days[3]), CellKind.holiday);
      expect(vm.kindOf(vm.slotAt(days[2].date, 840), days[2]), CellKind.cancelled);
      expect(vm.kindOf(vm.slotAt(days[5].date, 600), days[5]), CellKind.full);
      expect(vm.kindOf(vm.slotAt(days[0].date, 480), days[0]), CellKind.past);
      expect(vm.kindOf(vm.slotAt(days[4].date, 1080), days[4]), CellKind.open);
      expect(vm.kindOf(null, days[1]), CellKind.empty);
      expect(vm.isToday(days[4].date), isTrue);
    });

    test('dolu / geçmiş seans seçilemez', () async {
      final vm = build();
      await vm.load();
      final sat = vm.days[5];
      vm.select(vm.slotAt(sat.date, 600)!, sat);
      expect(vm.selectedSlot, isNull);
      final mon = vm.days[0];
      vm.select(vm.slotAt(mon.date, 480)!, mon);
      expect(vm.selectedSlot, isNull);
    });

    test('önceki hafta bugünden geriye gidemez; sonraki hafta yeni istek atar', () async {
      final vm = build();
      await vm.load();
      expect(vm.canGoPrev, isFalse);
      await vm.nextWeek();
      expect(vm.weekStart, DateTime(2026, 10, 19));
      expect(vm.canGoPrev, isTrue);
      await vm.prevWeek();
      expect(vm.weekStart, DateTime(2026, 10, 12));
    });
  });

  group('kurallar', () {
    test('cinsiyet uyuşmazlığı engeller', () async {
      final vm = build();
      await vm.load();
      final sat = vm.days[5];
      vm.select(vm.slotAt(sat.date, 1080)!, sat); // Bay seansı, katılımcı kadın
      expect(vm.issues.single.kind, RuleIssueKind.gender);
      expect(vm.canAdd, isFalse);
    });

    test('yüzme onayı olmadan eklenemez; onayla etkinleşir', () async {
      final vm = build();
      await vm.load();
      final fri = vm.days[4];
      vm.select(vm.slotAt(fri.date, 1080)!, fri);
      expect(vm.issues, isEmpty);
      expect(vm.canAdd, isFalse);
      vm.setSwimConfirmed(value: true);
      expect(vm.canAdd, isTrue);
    });

    test('çocuk katılımcıda veli uyarısı (bilgi), yaş altı engeller', () {
      const rules = ItemRules(ageRules: AgeRules(minAge: 6, guardianUntil: 15, permissionUntil: 17));
      final s = slot('x', DateTime(2026, 10, 16, 18));
      expect(evaluateRules(rules: rules, participant: kChild, slot: s).single, const RuleIssue(RuleIssueKind.guardian, min: 6, max: 15));
      expect(evaluateRules(rules: rules, participant: kChild.copyWith(age: 16), slot: s).single.kind, RuleIssueKind.permission);
      final young = evaluateRules(rules: rules, participant: kChild.copyWith(age: 5), slot: s).single;
      expect(young.kind, RuleIssueKind.minAge);
      expect(young.blocking, isTrue);
      expect(evaluateRules(rules: rules.copyWith(maxAge: 15), participant: kSelf, slot: s).single.kind, RuleIssueKind.maxAge);
      expect(evaluateRules(rules: rules, participant: kSelf, slot: s), isEmpty);
    });

    test('katılımcı değişince kurallar yeniden hesaplanır', () async {
      final vm = build();
      await vm.load();
      final sat = vm.days[5];
      vm.select(vm.slotAt(sat.date, 1080)!, sat);
      vm.selectParticipant('chd-deniz');
      expect(vm.issues.map((i) => i.kind), [RuleIssueKind.guardian]);
    });
  });

  group('sepete ekleme', () {
    Future<SessionViewModel> ready() async {
      final vm = build();
      await vm.load();
      final fri = vm.days[4];
      vm.select(vm.slotAt(fri.date, 1080)!, fri);
      vm.setSwimConfirmed(value: true);
      return vm;
    }

    test('başarılı rezerv true döner', () async {
      stubHold(Success(CartHold(cartItemId: 'crt-1', expiresAt: kNow.add(const Duration(minutes: 5)))));
      final vm = await ready();
      expect(await vm.addToCart(), isTrue);
      verify(
        () => cart.hold(itemId: 'itm-fethiye-gunluk', sessionId: 's-fri-18-f', participantId: 'usr-demo', swimConfirmed: true),
      ).called(1);
    });

    test('kontenjan doldu (409) → hata + sessiz yenileme, seçim temizlenir', () async {
      stubHold(const Failure(ConflictException()));
      final vm = await ready();
      stubWeek(sessionWeek(slots: [slot('s-fri-18-f', DateTime(2026, 10, 16, 18), gender: Gender.female, booked: 60)]));
      expect(await vm.addToCart(), isFalse);
      expect(vm.takeError(), isA<ConflictException>());
      expect(vm.takeError(), isNull);
      expect(vm.selectedSlot, isNull);
    });
  });
}
