import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../storage/cache_store.dart';

/// "Kolay Mod": ileri yaş / düşük teknoloji okuryazarlığı için sadeleştirilmiş arayüz.
/// Açıkken: yazı %20 büyük, animasyonlar kapalı, dokunma hedefleri 56 px,
/// Keşfet'te yalnız 4 büyük kısayol, hikâye/karusel gizli, menüler kısaltılmış.
/// Ayarlar → Görünüm'den açılır; cihazda saklanır.
class UiPrefsController extends ChangeNotifier {
  UiPrefsController(this._cache) : _easy = _cache.readBool(_key) ?? false;

  static const _key = 'pref.easyMode';
  final CacheStore _cache;
  bool _easy;

  bool get easyMode => _easy;

  /// Kolay modda metin ölçeği.
  double get textScale => _easy ? 1.2 : 1.0;

  Future<void> setEasyMode(bool value) async {
    if (value == _easy) return;
    _easy = value;
    notifyListeners();
    await _cache.writeBool(_key, value: value);
  }
}

extension EasyModeX on BuildContext {
  /// Widget'lar düzen kararı için: `if (context.easyMode) …`. Yeniden çizim için watch eder.
  bool get easyMode => select<UiPrefsController, bool>((c) => c.easyMode);

  /// Kolay modda büyük dokunma hedefi (56) / normalde 44.
  double get touchTarget => easyMode ? 56 : 44;
}
