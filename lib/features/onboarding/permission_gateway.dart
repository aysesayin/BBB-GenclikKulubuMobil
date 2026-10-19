import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

/// A8 kart destesindeki izinler (üstten alta sıra tasarımdaki gibi).
enum OnbPermission { location, notifications, motion }

/// OS izin istemlerinin soyutlaması (ViewModel testlerinde taklit edilir).
abstract interface class PermissionGateway {
  Future<bool> request(OnbPermission permission);
}

class DevicePermissionGateway implements PermissionGateway {
  const DevicePermissionGateway();

  @override
  Future<bool> request(OnbPermission permission) async {
    try {
      return switch (permission) {
        OnbPermission.location => await _location(),
        // TODO(varsayım): firebase_messaging kurulu değil; bildirim izni FCM entegrasyonunda
        // (requestPermission) istenecek. Şimdilik kullanıcının tercihi "verdi" kabul edilir.
        OnbPermission.notifications => true,
        // TODO(varsayım): permission_handler kurulu değil; Android ACTIVITY_RECOGNITION / iOS Motion
        // izni Adım At (pedometer) ilk açıldığında OS tarafından istenir. Tercih "verdi" kabul edilir.
        OnbPermission.motion => true,
      };
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> _location() async {
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    return p == LocationPermission.whileInUse || p == LocationPermission.always;
  }
}
