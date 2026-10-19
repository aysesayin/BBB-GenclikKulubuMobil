import 'package:bbb_genclik_kulubu_app/core/di/locator.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/data/models/places/place.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/place_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/places/view/place_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../events/discover_test_app.dart';

class _MockRepo extends Mock implements PlaceRepository {}

void main() {
  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    sl.registerSingleton<PlaceRepository>(repo);
    when(() => repo.detail(any())).thenAnswer(
      (_) async => const Success(
        PlaceDetail(
          id: 'plc-sehir-tiyatrosu',
          name: 'Bursa Şehir Tiyatrosu',
          categoryLabel: 'Tiyatro',
          district: 'Osmangazi',
          openNow: true,
          statusLabel: 'Açık · Gişe 21:00’e kadar',
          description: 'Sezon boyunca oyunlar.',
          lat: 40.19,
          lng: 29.05,
          gallery: [
            PlaceGalleryImage(tone: 'pink'),
            PlaceGalleryImage(tone: 'teal'),
            PlaceGalleryImage(tone: 'sun'),
          ],
          hours: [
            PlaceHours(days: 'Salı – Pazar', hours: '10:00 – 21:00'),
            PlaceHours(days: 'Pazartesi', closed: true),
          ],
          amenities: ['Engelli erişimi', 'Kafeterya', 'Vestiyer', 'Otopark'],
          actions: [
            PlaceAction(type: PlaceActionType.checkin, title: 'Oyun girişinde check-in yap', buan: 300),
            PlaceAction(type: PlaceActionType.opportunity, title: 'Öğrenci biletinde indirim', targetId: 'opp-1'),
          ],
        ),
      ),
    );
  });

  tearDown(() => sl.reset());

  for (final (size, dark) in [(const Size(393, 852), false), (const Size(360, 800), true)]) {
    testWidgets('yer detayı ${size.width.toInt()} ${dark ? 'koyu' : 'açık'} taşmadan çizilir', (tester) async {
      await pumpDiscoverScreen(
        tester,
        const PlaceDetailView(id: 'plc-sehir-tiyatrosu'),
        size: size,
        dark: dark,
      );
      expect(find.text('Bursa Şehir Tiyatrosu'), findsOneWidget);
      expect(find.text('Tiyatro · Osmangazi'), findsOneWidget);
      expect(find.text('Kapalı'), findsOneWidget);
      expect(find.text('+300'), findsOneWidget);
      expect(find.text('Yol tarifi al'), findsOneWidget);
      expect(find.text('Check-in yap'), findsOneWidget);
    });
  }
}
