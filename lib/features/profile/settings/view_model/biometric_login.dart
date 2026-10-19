import 'package:local_auth/local_auth.dart';

import '../../../../core/storage/cache_store.dart';

enum BiometricKind { face, fingerprint, generic }

/// Biyometrik giriş tercihi + cihaz yeteneği. ViewModel testlerinde taklit edilir.
abstract interface class BiometricLogin {
  /// Cihazda kullanılabilir biyometri türü; yoksa null.
  Future<BiometricKind?> availableKind();
  Future<bool> authenticate(String reason);
  bool get enabled;
  Future<void> setEnabled({required bool value});
}

/// local_auth tabanlı uygulama. Tercih bayrağı [CacheStore]'da tutulur (hassas veri değil).
// TODO(varsayım): Bayrak `pref.biometricLogin`; giriş ekranı (A grubu) bunu okuyup
// `/auth/biometric` ile cihaz anahtarı akışını yürütmeli.
class LocalBiometricLogin implements BiometricLogin {
  LocalBiometricLogin(this._cache, [LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  static const prefKey = 'pref.biometricLogin';

  final CacheStore _cache;
  final LocalAuthentication _auth;

  @override
  Future<BiometricKind?> availableKind() async {
    try {
      if (!await _auth.isDeviceSupported() || !await _auth.canCheckBiometrics) return null;
      final types = await _auth.getAvailableBiometrics();
      if (types.isEmpty) return null;
      if (types.contains(BiometricType.face)) return BiometricKind.face;
      if (types.contains(BiometricType.fingerprint)) return BiometricKind.fingerprint;
      return BiometricKind.generic;
    } on Object {
      // PlatformException / MissingPluginException / desteklenmeyen platform.
      return null;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason, biometricOnly: true);
    } on Object {
      return false;
    }
  }

  @override
  bool get enabled => _cache.readBool(prefKey) ?? false;

  @override
  Future<void> setEnabled({required bool value}) => _cache.writeBool(prefKey, value: value);
}
