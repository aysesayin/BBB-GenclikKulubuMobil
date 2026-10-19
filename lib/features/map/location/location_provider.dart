import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum LocationStatus { ok, denied, deniedForever, serviceDisabled, error }

class LocationResult {
  const LocationResult(this.status, [this.position]);

  final LocationStatus status;
  final LatLng? position;

  bool get isOk => status == LocationStatus.ok && position != null;
}

/// Cihaz konumu soyutlaması (ViewModel testlerinde taklit edilir).
abstract interface class LocationProvider {
  /// İzin ister ve anlık konumu döner. İzin yok / servis kapalı → hata durumu (asla fırlatmaz).
  Future<LocationResult> current();

  /// Uygulama ayarlarını açar (kalıcı ret sonrası).
  Future<bool> openSettings();
}

class GeolocatorLocationProvider implements LocationProvider {
  const GeolocatorLocationProvider();

  @override
  Future<LocationResult> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return const LocationResult(LocationStatus.serviceDisabled);
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return const LocationResult(LocationStatus.denied);
      if (permission == LocationPermission.deniedForever) return const LocationResult(LocationStatus.deniedForever);
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 10)),
      );
      return LocationResult(LocationStatus.ok, LatLng(pos.latitude, pos.longitude));
    } on Object {
      final last = await _lastKnown();
      return last == null ? const LocationResult(LocationStatus.error) : LocationResult(LocationStatus.ok, last);
    }
  }

  Future<LatLng?> _lastKnown() async {
    try {
      final p = await Geolocator.getLastKnownPosition();
      return p == null ? null : LatLng(p.latitude, p.longitude);
    } on Object {
      return null;
    }
  }

  @override
  Future<bool> openSettings() => Geolocator.openAppSettings();
}
