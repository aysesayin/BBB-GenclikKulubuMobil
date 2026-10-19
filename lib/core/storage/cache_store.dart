import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Hafif anahtar-değer önbelleği (tercihler, son içerikler, son aramalar).
/// Hassas veri (token, TCKN) BURAYA yazılmaz → [SecureStorage].
class CacheStore {
  CacheStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<CacheStore> create() async => CacheStore(await SharedPreferences.getInstance());

  String? readString(String key) => _prefs.getString(key);
  Future<void> writeString(String key, String value) => _prefs.setString(key, value);

  bool? readBool(String key) => _prefs.getBool(key);
  Future<void> writeBool(String key, {required bool value}) => _prefs.setBool(key, value);

  List<String> readList(String key) => _prefs.getStringList(key) ?? const [];
  Future<void> writeList(String key, List<String> value) => _prefs.setStringList(key, value);

  Map<String, dynamic>? readJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as Map).cast<String, dynamic>();
    } on Object {
      return null;
    }
  }

  Future<void> writeJson(String key, Map<String, dynamic> value) => _prefs.setString(key, jsonEncode(value));

  Future<void> remove(String key) => _prefs.remove(key);

  /// Oturum kapatırken API önbelleğini temizler (tercihler kalır).
  Future<void> clearApiCache() async {
    for (final k in _prefs.getKeys().where((k) => k.startsWith('api.') || k.startsWith('user.')).toList()) {
      await _prefs.remove(k);
    }
  }
}
