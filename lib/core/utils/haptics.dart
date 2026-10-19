import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Haptik geri bildirim (tasarım sistemi §7): kazanımda medium, seviye atlamada heavy,
/// chip/çark diliminde selection, hatalı girişte error (vibrate).
abstract final class Haptics {
  static Future<void> light() => HapticFeedback.lightImpact();
  static Future<void> medium() => HapticFeedback.mediumImpact();
  static Future<void> heavy() => HapticFeedback.heavyImpact();
  static Future<void> selection() => HapticFeedback.selectionClick();
  static Future<void> error() => HapticFeedback.vibrate();
}

extension MotionX on BuildContext {
  /// "Hareketi azalt" açıksa true → döngüsel animasyonlar durur, geçişler kısa fade olur.
  bool get reduceMotion => MediaQuery.maybeDisableAnimationsOf(this) ?? false;
}
