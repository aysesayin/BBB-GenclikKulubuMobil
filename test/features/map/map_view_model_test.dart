import 'dart:async';

import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/map/map_pin.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/map_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/map/location/location_provider.dart';
import 'package:bbb_genclik_kulubu_app/features/map/view_model/map_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements MapRepository {}

class _MockLocation extends Mock implements LocationProvider {}

MapPin _pin(String id, MapLayer layer, String cat) => MapPin(id: id, layer: layer, name: id, lat: 40.19, lng: 29.06, categoryId: cat);

final _data = MapPinsData(
  categories: const [
    MapCategory(id: 'tiyatro', label: 'Tiyatro', color: 'hotFill'),
    MapCategory(id: 'spor', label: 'Spor'),
  ],
  pins: [
    _pin('tiyatro', MapLayer.places, 'tiyatro'),
    _pin('fethiye', MapLayer.places, 'spor'),
    _pin('zumba', MapLayer.events, 'spor'),
    _pin('kafe', MapLayer.opportunities, 'sosyal'),
  ],
);

void main() {
  setUpAll(() {
    registerFallbackValue(MapLayer.places);
    registerFallbackValue(const MapBounds(south: 0, west: 0, north: 0, east: 0));
  });

  late _MockRepo repo;
  late _MockLocation location;
  late MapViewModel vm;

  void stubPins(ApiResult<MapPinsData> r) => when(
    () => repo.pins(
      layer: any(named: 'layer'),
      categoryId: any(named: 'categoryId'),
      bounds: any(named: 'bounds'),
    ),
  ).thenAnswer((_) async => r);

  setUp(() {
    repo = _MockRepo();
    location = _MockLocation();
    vm = MapViewModel(repo, location);
  });

  test('yükleme: kategoriler saklanır, pinler katmana göre süzülür', () async {
    stubPins(Success(_data));
    await vm.load();

    expect(vm.state, isA<ViewSuccess<MapPinsData>>());
    expect(vm.categories, hasLength(2));
    expect(vm.visiblePins.map((p) => p.id), ['tiyatro', 'fethiye']);
    expect(vm.categoryOf(vm.visiblePins.first)?.color, 'hotFill');
  });

  test('katman değişimi seçimi sıfırlar ve layer parametresiyle yeniden ister', () async {
    stubPins(Success(_data));
    await vm.load();
    vm.selectPin('tiyatro');
    expect(vm.selectedPin?.id, 'tiyatro');

    vm.setLayer(MapLayer.events);
    await untilCalled(() => repo.pins(layer: MapLayer.events, categoryId: null, bounds: null));
    await pumpEventQueue();

    expect(vm.selectedPin, isNull);
    expect(vm.visiblePins.map((p) => p.id), ['zumba']);
  });

  test('kategori çipi filtreler, tekrar dokunmak kaldırır; gizlenen seçim temizlenir', () async {
    stubPins(Success(_data));
    await vm.load();
    vm.selectPin('tiyatro');

    vm.toggleCategory('spor');
    await pumpEventQueue();
    expect(vm.categoryId, 'spor');
    expect(vm.visiblePins.map((p) => p.id), ['fethiye']);
    expect(vm.selectedPin, isNull);
    verify(() => repo.pins(layer: MapLayer.places, categoryId: 'spor', bounds: null)).called(1);

    vm.toggleCategory('spor');
    await pumpEventQueue();
    expect(vm.categoryId, isNull);
    expect(vm.visiblePins, hasLength(2));
  });

  test('başlangıç katmanı / kategorisi rota sorgusundan', () async {
    vm = MapViewModel(repo, location, initialLayer: MapLayer.opportunities, initialCategory: 'sosyal');
    stubPins(Success(_data));
    await vm.load();
    expect(vm.visiblePins.map((p) => p.id), ['kafe']);
    verify(() => repo.pins(layer: MapLayer.opportunities, categoryId: 'sosyal', bounds: null)).called(1);
  });

  test('görünür alan değişmezse yeniden istemez', () async {
    stubPins(Success(_data));
    const b = MapBounds(south: 40.1, west: 29.0, north: 40.3, east: 29.2);
    vm.updateBounds(b);
    await pumpEventQueue();
    vm.updateBounds(b);
    await pumpEventQueue();
    verify(() => repo.pins(layer: MapLayer.places, categoryId: null, bounds: b)).called(1);
    expect(b.query, '29.00000,40.10000,29.20000,40.30000');
  });

  test('eski yanıt yeni yanıtın üstüne yazılmaz', () async {
    final slow = Completer<ApiResult<MapPinsData>>();
    when(() => repo.pins(layer: MapLayer.places, categoryId: null, bounds: null)).thenAnswer((_) => slow.future);
    when(() => repo.pins(layer: MapLayer.events, categoryId: null, bounds: null)).thenAnswer((_) async => Success(_data));

    unawaited(vm.load());
    vm.setLayer(MapLayer.events);
    await pumpEventQueue();
    slow.complete(const Success(MapPinsData()));
    await pumpEventQueue();

    expect(vm.state.dataOrNull?.pins, hasLength(4));
  });

  test('yeniden yüklenirken pinler görünür kalır', () async {
    stubPins(Success(_data));
    await vm.load();
    final pending = Completer<ApiResult<MapPinsData>>();
    when(
      () => repo.pins(
        layer: any(named: 'layer'),
        categoryId: any(named: 'categoryId'),
        bounds: any(named: 'bounds'),
      ),
    ).thenAnswer((_) => pending.future);

    vm.updateBounds(const MapBounds(south: 40, west: 29, north: 40.3, east: 29.2));
    expect(vm.state, isA<ViewLoading<MapPinsData>>());
    expect(vm.visiblePins, hasLength(2));
    pending.complete(Success(_data));
  });

  test('hata: önbellek yoksa ViewError, önceki veri korunur', () async {
    stubPins(Success(_data));
    await vm.load();
    stubPins(const Failure(NetworkException()));
    await vm.load();

    final s = vm.state as ViewError<MapPinsData>;
    expect(s.cached?.pins, hasLength(4));
    expect(vm.visiblePins, hasLength(2));
  });

  test('kategori çipleri segmente ilk dokunuşta ya da rota kategorisiyle açılır', () async {
    stubPins(Success(_data));
    await vm.load();
    expect(vm.showCategories, isFalse);
    vm.setLayer(MapLayer.places); // aynı katman: yeniden istemez ama çipleri açar
    expect(vm.showCategories, isTrue);
    verify(() => repo.pins(layer: MapLayer.places, categoryId: null, bounds: null)).called(1);

    final routed = MapViewModel(repo, location, initialCategory: 'spor');
    expect(routed.showCategories, isTrue);
  });

  test('en yakın yerler: yalnız yer katmanı, konuma göre sıralı, en çok 3', () async {
    final far = MapPinsData(
      categories: _data.categories,
      pins: [
        ..._data.pins,
        const MapPin(id: 'gemlik', layer: MapLayer.places, name: 'Gemlik', lat: 40.4318, lng: 29.1563),
        const MapPin(id: 'millet', layer: MapLayer.places, name: 'Millet', lat: 40.2238, lng: 29.0052),
      ],
    );
    stubPins(Success(far));
    await vm.load();
    final nearest = vm.nearestPlaces();
    expect(nearest, hasLength(3));
    expect(nearest.map((p) => p.layer).toSet(), {MapLayer.places});
    expect(nearest.map((p) => p.id), ['tiyatro', 'fethiye', 'millet']); // Bursa merkezine göre
    expect(vm.distanceTo(nearest.first), lessThan(vm.distanceTo(nearest.last)));

    when(() => location.current()).thenAnswer((_) async => const LocationResult(LocationStatus.ok, LatLng(40.43, 29.15)));
    await vm.locate();
    expect(vm.nearestPlaces().first.id, 'gemlik');
  });

  test('şeritten odaklama pini seçer; başka katmandaysa katmanı değiştirir', () async {
    stubPins(Success(_data));
    await vm.load();
    vm.focusPin(_data.pins[1]);
    expect(vm.selectedPin?.id, 'fethiye');

    vm.setLayer(MapLayer.events);
    await pumpEventQueue();
    vm.focusPin(_data.pins[0]); // yer pini, katman etkinlik
    await pumpEventQueue();
    expect(vm.layer, MapLayer.places);
    expect(vm.selectedPin?.id, 'tiyatro');
  });

  test('konum izni varsa kullanıcı konumu kaydedilir', () async {
    when(() => location.current()).thenAnswer((_) async => const LocationResult(LocationStatus.ok, LatLng(40.2, 29.0)));
    final r = await vm.locate();
    expect(r.isOk, isTrue);
    expect(vm.userLocation, const LatLng(40.2, 29.0));
    expect(vm.locating, isFalse);
  });

  test('konum izni reddedilirse konum boş kalır, durum döner', () async {
    when(() => location.current()).thenAnswer((_) async => const LocationResult(LocationStatus.denied));
    final r = await vm.locate();
    expect(r.status, LocationStatus.denied);
    expect(vm.userLocation, isNull);
  });
}
