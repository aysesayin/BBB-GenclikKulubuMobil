import 'package:flutter/widgets.dart';

/// Boşluk ölçeği (tasarım sistemi §3): 4 · 8 · 12 · 16 · 20 · 24 · 32 · 48.
abstract final class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;

  /// Ekran yatay kenar boşluğu.
  static const screenH = 20.0;
  static const screenPadding = EdgeInsets.symmetric(horizontal: screenH);

  /// Alt navigasyon yüksekliği (88 px; güvenli alan dahil değil).
  static const tabBarHeight = 88.0;

  /// Minimum dokunma hedefi.
  static const minTouch = 44.0;
}

/// Köşe yarıçapları: sm 12 (chip/input) · md 16 · lg 22 (kart) · xl 28 (sheet/hero) · pill.
abstract final class AppRadii {
  static const sm = 12.0;
  static const md = 16.0;
  static const tile = 20.0;
  static const lg = 22.0;
  static const card = 24.0;
  static const xl = 28.0;
  static const pill = 999.0;

  static BorderRadius circular(double r) => BorderRadius.circular(r);
}

/// Hareket süreleri (tasarım sistemi §7).
abstract final class AppDurations {
  static const chip = Duration(milliseconds: 120);
  static const fast = Duration(milliseconds: 200);
  static const toastIn = Duration(milliseconds: 240);
  static const sheet = Duration(milliseconds: 300);
  static const countUp = Duration(milliseconds: 900);
  static const shimmer = Duration(milliseconds: 1200);
  static const coinRain = Duration(milliseconds: 1500);
  static const confetti = Duration(milliseconds: 1800);
  static const levelUp = Duration(milliseconds: 2400);
  static const toastStay = Duration(milliseconds: 2500);
  static const spin = Duration(milliseconds: 3200);
}
