import 'package:bbb_genclik_kulubu_app/core/di/locator.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/data/models/events/event_detail.dart';
import 'package:bbb_genclik_kulubu_app/data/models/events/event_item.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/event_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/events/view/event_detail_view.dart';
import 'package:bbb_genclik_kulubu_app/features/events/view/event_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'discover_test_app.dart';

class _MockRepo extends Mock implements EventRepository {}

void main() {
  setUpAll(() => registerFallbackValue(DateTime(2000)));

  late _MockRepo repo;
  final today = DateTime.now();
  DateTime day(int plus, int h) => DateTime(today.year, today.month, today.day + plus, h);

  setUp(() {
    repo = _MockRepo();
    sl.registerSingleton<EventRepository>(repo);
    when(
      () => repo.feed(
        from: any(named: 'from'),
        to: any(named: 'to'),
        categoryId: any(named: 'categoryId'),
      ),
    ).thenAnswer(
      (_) async => Success(
        EventFeed(
          categories: const [
            EventCategory(id: 'doga', label: 'Doğa Yürüyüşü'),
            EventCategory(id: 'kariyer', label: 'Kariyer'),
          ],
          items: [
            EventItem(
              id: 'evt-uludag-yuruyus',
              title: 'Uludağ Doğa Yürüyüşü',
              categoryId: 'doga',
              categoryLabel: 'Doğa',
              startsAt: day(2, 8),
              placeName: 'Sarıalan buluşma noktası',
              capacity: 50,
              attendeeCount: 34,
              tags: const ['16–30 yaş'],
              checkInBuan: 300,
              icon: 'mountain',
              tone: 'tile2',
            ),
            EventItem(
              id: 'evt-arduino',
              title: 'Arduino ile ilk robotun',
              categoryId: 'kariyer',
              categoryLabel: 'Teknik',
              startsAt: day(6, 18),
              capacity: 20,
              attendeeCount: 20,
              icon: 'chip',
              tone: 'tile3',
            ),
            EventItem(
              id: 'evt-kamp',
              title: 'Gençlik Kampı · Göknükbelen',
              categoryId: 'doga',
              categoryLabel: 'Kamp',
              startsAt: day(8, 9),
              endsAt: day(10, 17),
              capacity: 60,
              attendeeCount: 57,
              icon: 'tent',
              tone: 'tile5',
            ),
          ],
        ),
      ),
    );
    when(() => repo.detail(any())).thenAnswer(
      (_) async => Success(
        EventDetail(
          id: 'evt-uludag-yuruyus',
          title: 'Uludağ Doğa Yürüyüşü',
          categoryId: 'doga',
          categoryLabel: 'Doğa ve Macera',
          startsAt: day(2, 8),
          endsAt: day(2, 14),
          applyDeadline: day(1, 23),
          placeName: 'Sarıalan, Uludağ',
          placeNote: 'Servis: Kent Meydanı 07:15',
          placeId: 'plc-x',
          ageMin: 16,
          ageMax: 30,
          ageNote: '16–17 yaş için veli izin belgesi',
          capacity: 50,
          attendeeCount: 34,
          attendees: const [
            EventAttendee(initials: 'MK'),
            EventAttendee(initials: 'ZA', tone: 'tile1'),
          ],
          checkInBuan: 300,
          quota: const EventQuota(title: '6 ayda 1 katılım.', message: 'Hakkın açık.'),
          program: '08:30 buluşma.',
          cover: 'mountain',
        ),
      ),
    );
  });

  tearDown(() => sl.reset());

  for (final (size, dark) in [(const Size(393, 852), false), (const Size(360, 800), true)]) {
    testWidgets('liste ${size.width.toInt()} ${dark ? 'koyu' : 'açık'} taşmadan çizilir', (tester) async {
      await pumpDiscoverScreen(tester, const EventListView(), size: size, dark: dark);
      expect(find.text('Etkinlikler'), findsOneWidget);
      expect(find.text('Uludağ Doğa Yürüyüşü'), findsOneWidget);
      expect(find.text('34/50'), findsOneWidget);
      expect(find.text('DOLU'), findsOneWidget);
      expect(find.text('Check-in’de +300'), findsOneWidget);
      expect(find.bySemanticsLabel('Sonraki hafta'), findsOneWidget);
      expect(find.bySemanticsLabel('Önceki hafta'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Sonraki hafta'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);

      await tester.ensureVisible(find.text('Kariyer'));
      await tester.pump();
      await tester.tap(find.text('Kariyer'));
      await tester.pump();
      expect(find.text('Uludağ Doğa Yürüyüşü'), findsNothing);
      expect(find.text('Arduino ile ilk robotun'), findsOneWidget);
    });

    testWidgets('liste Kolay Mod ${size.width.toInt()}: tek sütun, 72 px gün kutuları', (tester) async {
      await pumpDiscoverScreen(tester, const EventListView(), size: size, dark: dark, easyMode: true);
      expect(find.text('Uludağ Doğa Yürüyüşü'), findsOneWidget);
      final tile = tester.getSize(find.ancestor(of: find.text('${today.day}'), matching: find.byType(AnimatedContainer)).first);
      expect(tile.width, 72);
      expect(tester.takeException(), isNull);
    });

    testWidgets('detay ${size.width.toInt()} ${dark ? 'koyu' : 'açık'} taşmadan çizilir', (tester) async {
      await pumpDiscoverScreen(
        tester,
        const EventDetailView(id: 'evt-uludag-yuruyus'),
        size: size,
        dark: dark,
      );
      expect(find.text('Uludağ Doğa Yürüyüşü'), findsOneWidget);
      expect(find.text('Check-in’de +300'), findsOneWidget);
      expect(find.text('16–30 yaş'), findsOneWidget);
      expect(find.text('34 / 50'), findsOneWidget);
      expect(find.text('Başvur'), findsOneWidget);
    });
  }
}
