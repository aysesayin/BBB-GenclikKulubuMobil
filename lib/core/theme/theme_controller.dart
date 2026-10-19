import 'package:flutter/material.dart';

import '../storage/cache_store.dart';

/// Açık / koyu / sistem tema tercihi; cihazda saklanır.
class ThemeController extends ChangeNotifier {
  ThemeController(this._cache) {
    final saved = _cache.readString(_key);
    _mode = ThemeMode.values.firstWhere((m) => m.name == saved, orElse: () => ThemeMode.system);
  }

  static const _key = 'pref.themeMode';
  final CacheStore _cache;
  late ThemeMode _mode;

  ThemeMode get mode => _mode;

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _cache.writeString(_key, mode.name);
  }
}
