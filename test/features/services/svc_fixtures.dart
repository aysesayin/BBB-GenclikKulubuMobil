import 'package:bbb_genclik_kulubu_app/data/models/services/benefits.dart';
import 'package:bbb_genclik_kulubu_app/data/models/services/cart.dart';
import 'package:bbb_genclik_kulubu_app/data/models/services/session.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/application_repository.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/cart_repository.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/facility_repository.dart';
import 'package:bbb_genclik_kulubu_app/data/services/cart_payment_launcher.dart';
import 'package:mocktail/mocktail.dart';

class MockFacilityRepository extends Mock implements FacilityRepository {}

class MockCartRepository extends Mock implements CartRepository {}

class MockApplicationRepository extends Mock implements ApplicationRepository {}

class MockPaymentLauncher extends Mock implements PaymentLauncher {}

/// Elle ilerletilen saat.
class FakeClock {
  FakeClock(this.value);

  DateTime value;

  DateTime call() => value;

  void advance(Duration d) => value = value.add(d);
}

/// 16 Ekim 2026 Cuma 12:00 — "bugün".
final kNow = DateTime(2026, 10, 16, 12);

const kSelf = Participant(id: 'usr-demo', name: 'Ayşe Su', age: 19, gender: Gender.female);
const kChild = Participant(id: 'chd-deniz', name: 'Deniz', age: 9, gender: Gender.male, relation: Relation.child);

SessionWeek sessionWeek({bool swim = true, List<SessionDay>? days, List<SessionSlot>? slots}) => SessionWeek(
  itemId: 'itm-fethiye-gunluk',
  title: 'Günlük Giriş',
  facilityName: 'Fethiye Havuzu',
  rules: ItemRules(requiresSwimConfirmation: swim),
  participants: const [kSelf, kChild],
  days:
      days ??
      [for (var i = 0; i < 7; i++) SessionDay(date: DateTime(2026, 10, 12 + i), status: i == 3 ? DayStatus.holiday : DayStatus.open)],
  slots:
      slots ??
      [
        slot('s-fri-18-f', DateTime(2026, 10, 16, 18), gender: Gender.female),
        slot('s-fri-18-m', DateTime(2026, 10, 17, 18), gender: Gender.male),
        slot('s-wed-14-c', DateTime(2026, 10, 14, 14), status: SlotStatus.cancelled),
        slot('s-thu-10', DateTime(2026, 10, 15, 10)),
        slot('s-sat-10-full', DateTime(2026, 10, 17, 10), booked: 60),
        slot('s-mon-08', DateTime(2026, 10, 12, 8)),
      ],
);

SessionSlot slot(String id, DateTime start, {Gender gender = Gender.mixed, int booked = 20, SlotStatus status = SlotStatus.open}) =>
    SessionSlot(
      id: id,
      start: start,
      end: start.add(const Duration(hours: 1)),
      label: 'Günlük',
      gender: gender,
      price: 100,
      capacity: 60,
      booked: booked,
      status: status,
    );

const kCartItem = CartItem(
  id: 'crt-1',
  title: 'Bayan Günlük Giriş',
  itemId: 'itm-fethiye-gunluk',
  facilityName: 'Fethiye Havuzu',
  participantName: 'Ayşe Su',
  forSelf: true,
  price: 100,
);

const kStudent = EligibleDiscount(id: 'dsc-ogrenci', name: 'Öğrenci indirimi', rate: 50, status: DiscountStatus.approved);
const kSibling = EligibleDiscount(id: 'dsc-kardes', name: 'Kardeş indirimi', rate: 20, status: DiscountStatus.pending);
const kWallet = CouponWallet(
  balance: 30,
  items: [Coupon(id: 'c1', title: 'Telafi kuponu', value: 30)],
);

CartSnapshot cartSnapshot(DateTime deadline, {List<CartItem> items = const [kCartItem]}) => CartSnapshot(
  cart: Cart(items: items),
  deadline: deadline,
);
