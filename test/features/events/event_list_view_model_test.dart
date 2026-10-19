import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/events/event_item.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/event_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/events/view_model/event_list_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements EventRepository {}

EventItem _event(String id, String cat, DateTime start, {DateTime? end}) =>
    EventItem(id: id, title: id, categoryId: cat, categoryLabel: cat, startsAt: start, endsAt: end, capacity: 50, attendeeCount: 10);

void main() {
  setUpAll(() => registerFallbackValue(DateTime(2000)));

  final now = DateTime(2026, 10, 16, 9, 30);
  late _MockRepo repo;
  late EventListViewModel vm;

  final feed = EventFeed(
    categories: const [
      EventCategory(id: 'doga', label: 'Doğa'),
      EventCategory(id: 'kariyer', label: 'Kariyer'),
    ],
    items: [
      _event('kariyer', 'kariyer', DateTime(2026, 10, 21, 19)),
      _event('yuruyus', 'doga', DateTime(2026, 10, 18, 8, 30)),
      _event('kamp', 'doga', DateTime(2026, 10, 24, 9), end: DateTime(2026, 10, 26, 17)),
    ],
  );

  void stubFeed(ApiResult<EventFeed> r) => when(
    () => repo.feed(
      from: any(named: 'from'),
      to: any(named: 'to'),
      categoryId: any(named: 'categoryId'),
    ),
  ).thenAnswer((_) async => r);

  setUp(() {
    repo = _MockRepo();
    vm = EventListViewModel(repo, clock: () => now);
  });

  test('14 günlük pencereyi bugünden başlatır ve tek çağrıyla yükler', () async {
    stubFeed(Success(feed));
    await vm.load();

    expect(vm.days, hasLength(14));
    expect(vm.days.first, DateTime(2026, 10, 16));
    verify(() => repo.feed(from: DateTime(2026, 10, 16), to: DateTime(2026, 10, 29))).called(1);
    expect(vm.state, isA<ViewSuccess<EventFeed>>());
    expect(vm.categories.map((c) => c.id), ['doga', 'kariyer']);
  });

  test('etkinlikler başlangıç saatine göre sıralanır', () async {
    stubFeed(Success(feed));
    await vm.load();
    expect(vm.events.map((e) => e.id), ['yuruyus', 'kariyer', 'kamp']);
  });

  test('gün filtresi çok günlü etkinlikleri de kapsar, aynı güne dokunmak kaldırır', () async {
    stubFeed(Success(feed));
    await vm.load();

    vm.selectDay(DateTime(2026, 10, 25));
    expect(vm.events.map((e) => e.id), ['kamp']);
    expect(vm.isSelectedDay(DateTime(2026, 10, 25, 14)), isTrue);
    expect(vm.monthAnchor, DateTime(2026, 10, 25));

    vm.selectDay(DateTime(2026, 10, 25));
    expect(vm.selectedDay, isNull);
    expect(vm.events, hasLength(3));
  });

  test('kategori filtresi; null "Tümü", aynı çip tekrar → kaldırır', () async {
    stubFeed(Success(feed));
    await vm.load();

    vm.selectCategory('doga');
    expect(vm.events.map((e) => e.id), ['yuruyus', 'kamp']);
    vm.selectCategory('doga');
    expect(vm.categoryId, isNull);
    vm.selectCategory('kariyer');
    vm.selectCategory(null);
    expect(vm.events, hasLength(3));
  });

  test('gün + kategori birlikte; filtreleri temizle', () async {
    stubFeed(Success(feed));
    await vm.load();

    vm
      ..selectDay(DateTime(2026, 10, 18))
      ..selectCategory('kariyer');
    expect(vm.events, isEmpty);
    expect(vm.hasFilters, isTrue);

    vm.clearFilters();
    expect(vm.hasFilters, isFalse);
    expect(vm.events, hasLength(3));
  });

  test('gün şeridi noktaları kategori filtresinden bağımsızdır', () async {
    stubFeed(Success(feed));
    await vm.load();
    vm.selectCategory('kariyer');

    expect(vm.hasEventsOn(DateTime(2026, 10, 18)), isTrue);
    expect(vm.hasEventsOn(DateTime(2026, 10, 26)), isTrue);
    expect(vm.hasEventsOn(DateTime(2026, 10, 17)), isFalse);
  });

  test('yenileme sırasında liste boşalmaz', () async {
    stubFeed(Success(feed));
    await vm.load();
    final refreshing = vm.refresh();
    expect(vm.state, isA<ViewLoading<EventFeed>>());
    expect(vm.events, hasLength(3));
    await refreshing;
  });

  test('boş akış → ViewEmpty', () async {
    stubFeed(const Success(EventFeed()));
    await vm.load();
    expect(vm.state, isA<ViewEmpty<EventFeed>>());
    expect(vm.events, isEmpty);
  });

  test('hata → ViewError', () async {
    stubFeed(const Failure(NetworkException()));
    await vm.load();
    final s = vm.state;
    expect(s, isA<ViewError<EventFeed>>());
    expect((s as ViewError<EventFeed>).isOffline, isTrue);
  });
}
