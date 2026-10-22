import 'package:flutter/foundation.dart';

import 'brightness_boost.dart';

/// Kod/QR gösterilirken ekranı "uyanık" tutar: parlaklık %100 ([BrightnessBoost])
/// + uyku kilidi. `wakelock_plus` bağımlılık çakışması yüzünden eklenemedi; kilit
/// kısmı şimdilik no-op, görünüm kullanıcıya "ekran kapanırsa…" ipucu gösterir.
class KeepAwake {
  KeepAwake({BrightnessBoost? boost}) : _boost = boost ?? BrightnessBoost();

  final BrightnessBoost _boost;
  bool _active = false;
  bool get active => _active;

  /// Parlaklık artırıldıysa true (UI "Parlaklık %100" çipi).
  Future<bool> enable() async {
    _active = true;
    final bright = await _boost.enable();
    await _setWakeLock(true);
    return bright;
  }

  Future<void> disable() async {
    if (!_active) return;
    _active = false;
    await _setWakeLock(false);
    await _boost.restore();
  }

  // TODO(varsayım): wakelock_plus eklenince `WakelockPlus.toggle(enable: on)` çağrılacak;
  // şu an platform uyku kilidi yok, bu yüzden görünümde oppKeepAwakeHint gösterilir.
  Future<void> _setWakeLock(bool on) async {
    if (kDebugMode && !kIsWeb) debugPrint('[keep-awake] wake lock ${on ? 'on' : 'off'} (no-op)');
  }
}
