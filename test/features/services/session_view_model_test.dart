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

  void stubWaitlist(ApiResult<WaitlistResult> r) =>
      when(() => repo.joinWaitlist(any(), sessionId: any(named: 'sessionId'))).thenAnswer((_) async => r);

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
    test('cinsiyet uyuşmazlığı hücreyi kilitler: seçilemez, neden döner', () async {
      final vm = build();
      await vm.load();
      final sat = vm.days[5];
      final male = vm.slotAt(sat.date, 1080)!; // Bay seansı, katılımcı kadın
      expect(vm.kindOf(male, sat), CellKind.ineligible);
      expect(vm.ineligibilityOf(male)?.kind, RuleIssueKind.gender);
      vm.select(male, sat);
      expect(vm.selectedSlot, isNull);
      expect(vm.canAdd, isFalse);
      // Çocuk (erkek) seçilince aynı hücre açılır.
      vm.selectParticipant('chd-deniz');
      expect(vm.kindOf(male, sat), CellKind.open);
    });

    test('profil yaş/cinsiyeti (viewerAge/viewerGender) "kendim" için katılımcı kaydını geçersiz kılar', () async {
      stubWeek(sessionWeek().copyWith(viewerAge: 19, viewerGender: Gender.male));
      final vm = build();
      await vm.load();
      final sat = vm.days[5];
      expect(vm.kindOf(vm.slotAt(sat.date, 1080)!, sat), CellKind.open); // Bay seansı artık uygun
      final fri = vm.days[4];
      expect(vm.kindOf(vm.slotAt(fri.date, 1080)!, fri), CellKind.ineligible); // Bayan seansı kilitli
      vm.selectParticipant('chd-deniz'); // çocukta profil değeri kullanılmaz
      expect(vm.kindOf(vm.slotAt(fri.date, 1080)!, fri), CellKind.ineligible);
      expect(vm.ineligibilityOf(vm.slotAt(fri.date, 1080)!)?.kind, RuleIssueKind.gender);
    });

    test('katılımcı değişince kilitlenen seçim temizlenir', () async {
      final vm = build();
      await vm.load();
      final fri = vm.days[4];
      vm.select(vm.slotAt(fri.date, 1080)!, fri); // Bayan seansı, kadın katılımcı
      expect(vm.selectedSlot, isNotNull);
      vm.selectParticipant('chd-deniz'); // erkek çocuk → uygun değil
      expect(vm.selectedSlot, isNull);
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
      vm.select(vm.slotAt(sat.date, 840)!, sat); // karma seans
      expect(vm.issues, isEmpty);
      vm.selectParticipant('chd-deniz');
      expect(vm.selectedSlot, isNotNull);
      expect(vm.issues.map((i) => i.kind), [RuleIssueKind.guardian]);
    });
  });

  group('bekleme listesi', () {
    test('dolu seans → POST waitlist, sıra hücrede tutulur', () async {
      stubWaitlist(const Success(WaitlistResult(position: 3)));
      final vm = build();
      await vm.load();
      final sat = vm.days[5];
      final full = vm.slotAt(sat.date, 600)!;
      expect(vm.kindOf(full, sat), CellKind.full);
      expect(vm.waitlistPositionOf(full.id), isNull);
      expect(await vm.joinWaitlist(full), 3);
      expect(vm.waitlistPositionOf(full.id), 3);
      expect(vm.joiningWaitlist, isFalse);
      verify(() => repo.joinWaitlist('itm-fethiye-gunluk', sessionId: 's-sat-10-full')).called(1);
    });

    test('açık ya da uygun olmayan seans bekleme listesine alınmaz', () async {
      stubWaitlist(const Success(WaitlistResult(position: 1)));
      final vm = build();
      await vm.load();
      expect(await vm.joinWaitlist(vm.slotAt(vm.days[4].date, 1080)!), isNull); // açık
      stubWeek(sessionWeek(slots: [slot('m-full', DateTime(2026, 10, 17, 18), gender: Gender.male, booked: 60)]));
      await vm.load();
      expect(await vm.joinWaitlist(vm.slotAt(vm.days[5].date, 1080)!), isNull); // dolu ama cinsiyet uymuyor
      verifyNever(() => repo.joinWaitlist(any(), sessionId: any(named: 'sessionId')));
    });

    test('sunucu hatası takeError ile döner', () async {
      stubWaitlist(const Failure(NetworkException()));
      final vm = build();
      await vm.load();
      final sat = vm.days[5];
      expect(await vm.joinWaitlist(vm.slotAt(sat.date, 600)!), isNull);
      expect(vm.takeError(), isA<NetworkException>());
    });
  });

  group('Kolay Mod gün gezinme', () {
    test('bugünden başlar, geriye gitmez, hafta sonunda sonraki haftaya geçer', () async {
      final vm = build();
      await vm.load();
      expect(vm.focusDay, DateTime(2026, 10, 16));
      expect(vm.canGoPrevDay, isFalse);
      expect(vm.slotsOn(vm.focusDay).map((s) => s.id), ['s-fri-18-f']);
      await vm.prevDay();
      expect(vm.focusDay, DateTime(2026, 10, 16));
      await vm.nextDay();
      await vm.nextDay();
      expect(vm.focusDay, DateTime(2026, 10, 18));
      await vm.nextDay();
      expect(vm.weekStart, DateTime(2026, 10, 19));
      expect(vm.focusDay, DateTime(2026, 10, 19));
      await vm.prevDay();
      expect(vm.weekStart, DateTime(2026, 10, 12));
      expect(vm.focusDay, DateTime(2026, 10, 18));
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
