import 'package:geolocator/geolocator.dart';

import 'photo_report_view_model.dart';

/// Geolocator ile tek seferlik konum. İzin yoksa / servis kapalıysa null.
// TODO(varsayım): Adres ("Tophane, Osmangazi") sunucuda ters geokodlanır; istemci yalnız koordinat yollar.
Future<GeoPoint?> readCurrentLocation() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return null;
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 10)),
    );
    return (lat: pos.latitude, lng: pos.longitude);
  } on Object {
    return null;
  }
}
