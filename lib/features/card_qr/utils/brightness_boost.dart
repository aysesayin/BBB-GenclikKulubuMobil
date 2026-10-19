import 'package:flutter/foundation.dart';
import 'package:screen_brightness/screen_brightness.dart';

/// Kod/QR ekranlarında parlaklığı %100'e çeker, çıkışta eski hâline döndürür.
/// Eklenti olmayan ortamlarda (web, test) sessizce hiçbir şey yapmaz.
class BrightnessBoost {
  BrightnessBoost([ScreenBrightness? sb]) : _sb = sb;

  final ScreenBrightness? _sb;
  bool _active = false;
  bool get active => _active;

  ScreenBrightness get _api => _sb ?? ScreenBrightness.instance;

  /// true → parlaklık artırıldı (UI "Parlaklık %100" çipini gösterir).
  Future<bool> enable() async {
    if (_active) return true;
    if (kIsWeb) return false;
    try {
      await _api.setApplicationScreenBrightness(1);
      _active = true;
    } on Object {
      _active = false;
    }
    return _active;
  }

  Future<void> restore() async {
    if (!_active) return;
    _active = false;
    try {
      await _api.resetApplicationScreenBrightness();
    } on Object {
      // yok say
    }
  }
}
