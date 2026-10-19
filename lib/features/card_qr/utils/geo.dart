import 'package:geolocator/geolocator.dart';

import '../../../data/models/card/digital_card.dart';

/// Check-in için konum. İzin istemez; yalnız önceden verilmişse gönderir.
// TODO(varsayım): konum izni A akışındaki izin ekranında alınır; burada sorulmaz, yoksa geo=null gider.
Future<GeoPoint?> currentGeoIfPermitted() async {
  try {
    final perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever || perm == LocationPermission.unableToDetermine) {
      return null;
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 4)),
    );
    return GeoPoint(pos.latitude, pos.longitude);
  } on Object {
    return null;
  }
}

/// Kamera izni reddedildiyse uygulama ayarlarını açar (geolocator yardımcı API'si).
Future<void> openAppSettings() async {
  try {
    await Geolocator.openAppSettings();
  } on Object {
    // desteklenmiyor
  }
}
