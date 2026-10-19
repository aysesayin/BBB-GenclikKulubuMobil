import 'package:latlong2/latlong.dart';

import '../../../core/base/base_view_model.dart';
import '../../../core/network/api_result.dart';
import '../../../data/models/places/place.dart';
import '../../../data/repositories/place_repository.dart';
import '../location/location_provider.dart';
import '../utils/pin_clustering.dart';

/// Yakındaki yer + hesaplanmış mesafe.
class NearbyPlace {
  const NearbyPlace(this.place, this.distanceMeters);

  final PlaceSummary place;
  final int distanceMeters;
}

/// "Yakınımdaki yerler" sayfası. Konum izni yoksa / alınamazsa Bursa merkezine göre sıralar
/// (zarif geri dönüş) ve [locationStatus] ile kullanıcıya nedenini söyler.
class NearbyPlacesViewModel extends LoadableViewModel<List<NearbyPlace>> {
  NearbyPlacesViewModel(this._repo, this._location, {LatLng? knownLocation}) : _known = knownLocation;

  final PlaceRepository _repo;
  final LocationProvider _location;
  LatLng? _known;

  LocationStatus? _status;
  LocationStatus? get locationStatus => _status;

  LatLng _origin = bursaCenter;
  LatLng get origin => _origin;

  bool get usingFallback => _status != null && _status != LocationStatus.ok;

  static const _distance = Distance();

  @override
  Future<ApiResult<List<NearbyPlace>>> fetch() async {
    final known = _known;
    if (known != null) {
      _status = LocationStatus.ok;
      _origin = known;
    } else {
      final r = await _location.current();
      _status = r.isOk ? LocationStatus.ok : r.status;
      _origin = r.position ?? bursaCenter;
      if (r.isOk) _known = r.position;
    }
    final result = await _repo.nearby(lat: _origin.latitude, lng: _origin.longitude);
    return result.map(_sorted);
  }

  List<NearbyPlace> _sorted(List<PlaceSummary> places) => places
      .map((p) => NearbyPlace(p, _distance.as(LengthUnit.Meter, _origin, LatLng(p.lat, p.lng)).round()))
      .toList()
    ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));

  @override
  bool isEmpty(List<NearbyPlace> data) => data.isEmpty;

  Future<bool> openLocationSettings() => _location.openSettings();
}
