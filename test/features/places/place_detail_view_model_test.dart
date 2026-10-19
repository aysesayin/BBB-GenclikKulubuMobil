import 'package:bbb_genclik_kulubu_app/core/base/view_state.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_endpoints.dart';
import 'package:bbb_genclik_kulubu_app/core/network/api_result.dart';
import 'package:bbb_genclik_kulubu_app/core/network/app_exception.dart';
import 'package:bbb_genclik_kulubu_app/data/models/places/place.dart';
import 'package:bbb_genclik_kulubu_app/data/repositories/place_repository.dart';
import 'package:bbb_genclik_kulubu_app/features/places/view_model/place_detail_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements PlaceRepository {}

const _place = PlaceDetail(
  id: 'plc-sehir-tiyatrosu',
  name: 'Bursa Şehir Tiyatrosu',
  lat: 40.1921,
  lng: 29.0566,
  gallery: [
    PlaceGalleryImage(tone: 'pink'),
    PlaceGalleryImage(tone: 'teal'),
    PlaceGalleryImage(tone: 'sun'),
  ],
  actions: [PlaceAction(type: PlaceActionType.checkin, title: 'Check-in', buan: 300)],
);

void main() {
  late _MockRepo repo;
  late PlaceDetailViewModel vm;

  setUp(() {
    repo = _MockRepo();
    vm = PlaceDetailViewModel(repo, 'plc-sehir-tiyatrosu');
  });

  test('yükleme başarılı', () async {
    when(() => repo.detail('plc-sehir-tiyatrosu')).thenAnswer((_) async => const Success(_place));
    await vm.load();
    expect(vm.state, isA<ViewSuccess<PlaceDetail>>());
    expect(vm.galleryCount, 3);
  });

  test('yol tarifi yalnız şablondan üretilir', () async {
    when(() => repo.detail(any())).thenAnswer((_) async => const Success(_place));
    await vm.load();
    final uri = vm.directions!;
    final expected = ApiEndpoints.directionsUrlTemplate.replaceAll('{lat}', '40.192100').replaceAll('{lng}', '29.056600');
    expect(uri.toString(), Uri.parse(expected).toString());
  });

  test('koordinat yoksa yol tarifi yok', () async {
    when(() => repo.detail(any())).thenAnswer((_) async => const Success(PlaceDetail(id: 'x', name: 'X')));
    await vm.load();
    expect(vm.directions, isNull);
    expect(vm.galleryCount, 1, reason: 'görsel yoksa tek çizim gösterilir');
  });

  test('galeri indeksi sınırlar içinde kalır', () async {
    when(() => repo.detail(any())).thenAnswer((_) async => const Success(_place));
    await vm.load();
    vm.setGalleryIndex(2);
    expect(vm.galleryIndex, 2);
    vm.setGalleryIndex(9);
    expect(vm.galleryIndex, 2);
    vm.setGalleryIndex(-1);
    expect(vm.galleryIndex, 0);
  });

  test('favori yerel olarak değişir', () async {
    when(() => repo.detail(any())).thenAnswer((_) async => const Success(_place));
    await vm.load();
    expect(vm.favorite, isFalse);
    vm.toggleFavorite();
    expect(vm.favorite, isTrue);
    vm.toggleFavorite();
    expect(vm.favorite, isFalse);
  });

  test('bulunamadı → ViewError', () async {
    when(() => repo.detail(any())).thenAnswer((_) async => const Failure(NotFoundException()));
    await vm.load();
    expect(vm.state, isA<ViewError<PlaceDetail>>());
    expect(vm.directions, isNull);
  });
}
