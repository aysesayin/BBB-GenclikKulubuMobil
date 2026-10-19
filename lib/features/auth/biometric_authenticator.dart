import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Face ID / parmak izi soyutlaması (ViewModel testlerinde taklit edilir).
abstract interface class BiometricAuthenticator {
  Future<bool> isAvailable();
  Future<bool> authenticate(String reason);
}

class LocalBiometricAuthenticator implements BiometricAuthenticator {
  LocalBiometricAuthenticator([LocalAuthentication? auth]) : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason, biometricOnly: true);
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    } on LocalAuthException {
      return false;
    }
  }
}
