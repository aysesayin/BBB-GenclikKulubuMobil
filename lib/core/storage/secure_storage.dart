import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Token'lar ve cihazda tutulması gereken hassas veriler (KVKK).
/// TCKN açık metin olarak ASLA saklanmaz.
class SecureStorage {
  SecureStorage([FlutterSecureStorage? storage]) : _s = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _s;

  static const _access = 'auth.accessToken';
  static const _refresh = 'auth.refreshToken';
  static const _cardPin = 'card.lastPin'; // çevrimdışı kart için son geçerli 4 haneli kod
  static const _deviceId = 'device.id';

  String? _accessCache;

  Future<String?> get accessToken async => _accessCache ??= await _s.read(key: _access);
  Future<String?> get refreshToken => _s.read(key: _refresh);

  Future<void> saveTokens({required String access, required String refresh}) async {
    _accessCache = access;
    await _s.write(key: _access, value: access);
    await _s.write(key: _refresh, value: refresh);
  }

  Future<void> clearTokens() async {
    _accessCache = null;
    await _s.delete(key: _access);
    await _s.delete(key: _refresh);
    await _s.delete(key: _cardPin);
  }

  Future<String?> get lastCardPin => _s.read(key: _cardPin);
  Future<void> saveCardPin(String pin) => _s.write(key: _cardPin, value: pin);

  Future<String?> get deviceId => _s.read(key: _deviceId);
  Future<void> saveDeviceId(String id) => _s.write(key: _deviceId, value: id);
}
