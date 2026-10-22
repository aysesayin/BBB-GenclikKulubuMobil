import 'package:bbb_genclik_kulubu_app/core/di/locator.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/data/models/map/map_pin.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/map_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/map/view/map_view.dart';
import 'package:bbb_genclik_kulubu_app/features/map/widgets/map_markers.dart';
import 'package:bbb_genclik_kulubu_app/features/map/widgets/nearest_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../events/discover_test_app.dart';

class _MockRepo extends Mock implements MapRepository {}

void main() {
  setUpAll(() => registerFallbackValue(MapLayer.places));

  late _MockRepo repo;

  setUp(() {
    repo = _MockRepo();
    sl.registerSingleton<MapRepository>(repo);
    when(
      () => repo.pins(
        layer: any(named: 'layer'),
        categoryId: any(named: 'categoryId'),
        bounds: any(named: 'bounds'),
      ),
    ).thenAnswer(
      (_) async => const Success(
        MapPinsData(
          categories: [
            MapCategory(id: 'tiyatro', label: 'Tiyatro', color: 'hotFill'),
            MapCategory(id: 'kultur', label: 'Kültür', color: 'buanFill'),
          ],
          pins: [
            MapPin(
              id: 'a',
              layer: MapLayer.places,
              name: 'Bursa Şehir Tiyatrosu',
              lat: 40.1921,
              lng: 29.0566,
              categoryId: 'tiyatro',
              subtitle: 'Tiyatro · 1,2 km',
              status: 'Bugün 19:30',
              icon: 'theatre',
              targetId: 'plc-sehir-tiyatrosu',
            ),
            MapPin(id: 'b', layer: MapLayer.places, name: 'Kozahan', lat: 40.1838, lng: 29.0641, categoryId: 'kultur', icon: 'museum'),
            MapPin(id: 'c', layer: MapLayer.places, name: 'Ulu Cami', lat: 40.1842, lng: 29.0616, categoryId: 'kultur', icon: 'museum'),
          ],
        ),
      ),
    );
  });

  tearDown(() => sl.reset());

  for (final dark in [false, true]) {
    testWidgets('harita ${dark ? 'koyu' : 'açık'}: pin, küme ve önizleme', (tester) async {
      await pumpDiscoverScreen(tester, const MapView(), dark: dark);
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Yakınımdaki yerler'), findsOneWidget);
      expect(find.text('Etkinlikler'), findsOneWidget);
      // Kategori çipleri varsayılan gizli; segmente dokununca ikinci satır açılır.
      expect(find.text('Tiyatro'), findsNothing);
      await tester.tap(find.text('Yerler'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Tiyatro'), findsOneWidget);
      expect(find.text('En yakın yerler'), findsOneWidget);
      expect(find.byType(NearestStrip), findsOneWidget);
      expect(find.byType(TeardropPin).evaluate().length + find.byType(ClusterBubble).evaluate().length, greaterThan(0));

      await tester.tap(find.bySemanticsLabel('Bursa Şehir Tiyatrosu'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Detay'), findsOneWidget);
      expect(find.text('Yol tarifi al'), findsOneWidget);
    });
  }

  testWidgets('en yakın şeridinden dokunma önizlemeyi açar', (tester) async {
    await pumpDiscoverScreen(tester, const MapView());
    await tester.pump(const Duration(milliseconds: 600));
    // Yatay liste tembel çizer; ilk (en yakın) kart her zaman görünür.
    final card = find.descendant(of: find.byType(NearestStrip), matching: find.byType(InkWell)).first;
    expect(card, findsOneWidget);
    final label = tester.getSemantics(card).label;
    expect(label, endsWith('Haritada göstermek için dokun'));
    final name = label.split(', ').first;
    expect(['Bursa Şehir Tiyatrosu', 'Kozahan', 'Ulu Cami'], contains(name));
    await tester.tap(card);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Detay'), findsOneWidget);
    expect(find.text(name), findsWidgets);
  });

  testWidgets('Kolay Mod: çipler hiç görünmez, büyük liste düğmesi', (tester) async {
    await pumpDiscoverScreen(tester, const MapView(), easyMode: true);
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Yakınımdaki yerler listesi'), findsOneWidget);
    await tester.tap(find.text('Yerler'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Tiyatro'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
