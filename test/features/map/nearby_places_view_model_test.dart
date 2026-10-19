import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/data/models/places/place.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/place_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/map/location/location_provider.dart';
import 'package:bbb_genclik_kulubu_app/features/map/utils/pin_clustering.dart';
import 'package:bbb_genclik_kulubu_app/features/map/view_model/nearby_places_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements PlaceRepository {}

class _MockLocation extends Mock implements LocationProvider {}

const _places = [
  PlaceSummary(id: 'gemlik', name: 'Gemlik GM', lat: 40.4318, lng: 29.1563),
  PlaceSummary(id: 'kozahan', name: 'Kozahan', lat: 40.1838, lng: 29.0641),
  PlaceSummary(id: 'millet', name: 'Millet GSM', lat: 40.2238, lng: 29.0052),
];

void main() {
  late _MockRepo repo;
  late _MockLocation location;

  setUp(() {
    repo = _MockRepo();
    location = _MockLocation();
    when(
      () => repo.nearby(
        lat: any(named: 'lat'),
        lng: any(named: 'lng'),
      ),
    ).thenAnswer((_) async => const Success(_places));
  });

  test('konum alınırsa ona göre en yakından uzağa sıralar', () async {
    const me = LatLng(40.2240, 29.0050); // Millet GSM yanı
    when(() => location.current()).thenAnswer((_) async => const LocationResult(LocationStatus.ok, me));
    final vm = NearbyPlacesViewModel(repo, location);
    await vm.load();

    final items = vm.state.dataOrNull!;
    expect(items.map((e) => e.place.id), ['millet', 'kozahan', 'gemlik']);
    expect(items.first.distanceMeters, lessThan(100));
    expect(vm.usingFallback, isFalse);
    verify(() => repo.nearby(lat: me.latitude, lng: me.longitude)).called(1);
  });

  test('izin reddedilirse Bursa merkezine göre sıralar ve geri dönüşü bildirir', () async {
    when(() => location.current()).thenAnswer((_) async => const LocationResult(LocationStatus.denied));
    final vm = NearbyPlacesViewModel(repo, location);
    await vm.load();

    expect(vm.usingFallback, isTrue);
    expect(vm.locationStatus, LocationStatus.denied);
    expect(vm.origin, bursaCenter);
    expect(vm.state.dataOrNull!.first.place.id, 'kozahan');
    verify(() => repo.nearby(lat: bursaCenter.latitude, lng: bursaCenter.longitude)).called(1);
  });

  test('bilinen konum verilirse izin istenmez', () async {
    final vm = NearbyPlacesViewModel(repo, location, knownLocation: const LatLng(40.43, 29.15));
    await vm.load();
    verifyNever(() => location.current());
    expect(vm.state.dataOrNull!.first.place.id, 'gemlik');
  });

  test('boş liste → ViewEmpty', () async {
    when(
      () => repo.nearby(
        lat: any(named: 'lat'),
        lng: any(named: 'lng'),
      ),
    ).thenAnswer((_) async => const Success(<PlaceSummary>[]));
    final vm = NearbyPlacesViewModel(repo, location, knownLocation: bursaCenter);
    await vm.load();
    expect(vm.state, isA<ViewEmpty<List<NearbyPlace>>>());
  });
}
