import 'package:flutter/material.dart';

import 'app_palette_values.dart';

/// Tasarımdaki "P1 · Bursa Klasik" semantik token seti (açık / koyu).
///
/// Ekranlar renkleri YALNIZCA bu extension'dan alır:
/// `context.palette.teal`, `context.palette.buanFill` …
/// Kısa adlar (sf, ink, mut, teal, purS …) tasarım dosyalarındaki `t.xxx`
/// anahtarlarıyla birebir aynıdır; böylece mockup → kod eşlemesi kolaydır.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.isDark,
    required this.bg,
    required this.sf,
    required this.sf2,
    required this.ink,
    required this.mut,
    required this.line,
    required this.borderStrong,
    required this.primary,
    required this.secondary,
    required this.teal,
    required this.tealB,
    required this.tealS,
    required this.grn,
    required this.grnT,
    required this.grnS,
    required this.pur,
    required this.purT,
    required this.purS,
    required this.yel,
    required this.yelS,
    required this.pink,
    required this.pinkT,
    required this.pinkS,
    required this.mint,
    required this.sky,
    required this.blob,
    required this.cta,
    required this.onCta,
    required this.ctaShadow,
    required this.buanFill,
    required this.onBuan,
    required this.buanShadow,
    required this.buanGlow,
    required this.buanGradStart,
    required this.buanGradEnd,
    required this.coinMark,
    required this.hotFill,
    required this.onHot,
    required this.success,
    required this.successSoft,
    required this.successText,
    required this.warning,
    required this.warningSoft,
    required this.warningText,
    required this.error,
    required this.errorSoft,
    required this.errorText,
    required this.accentText,
    required this.tile1,
    required this.tile2,
    required this.tile3,
    required this.tile4,
    required this.tile5,
    required this.tile6,
    required this.onTile,
    required this.chip,
    required this.onChip,
    required this.night,
    required this.onNight,
    required this.glow,
    required this.heroStart,
    required this.heroEnd,
    required this.mapLand,
    required this.mapRoad,
    required this.mapRoad2,
    required this.mapWater,
    required this.mapPark,
    required this.logoA,
    required this.logoB,
    required this.paper,
    required this.scrim,
    required this.shadowColor,
  });

  final bool isDark;

  /// Zemin / yüzeyler / metin.
  final Color bg, sf, sf2, ink, mut, line, borderStrong;

  /// Marka dolguları ve metin-güvenli ("T") varyantları + yumuşak ("S") tonlar.
  final Color primary, secondary;
  final Color teal, tealB, tealS;
  final Color grn, grnT, grnS;
  final Color pur, purT, purS;
  final Color yel, yelS;
  final Color pink, pinkT, pinkS;
  final Color mint, sky, blob;

  /// CTA (sarı) ve BUAN (mor).
  final Color cta, onCta, ctaShadow;
  final Color buanFill, onBuan, buanShadow, buanGlow, buanGradStart, buanGradEnd;
  final Color coinMark;
  final Color hotFill, onHot;

  /// Durum renkleri.
  final Color success, successSoft, successText;
  final Color warning, warningSoft, warningText;
  final Color error, errorSoft, errorText;
  final Color accentText;

  /// Pastel karo dolguları (kategori / kısayol ikon kareleri) — üzerinde [onTile].
  final Color tile1, tile2, tile3, tile4, tile5, tile6, onTile;
  final Color chip, onChip;
  final Color night, onNight, glow;
  final Color heroStart, heroEnd;

  /// Harita stili.
  final Color mapLand, mapRoad, mapRoad2, mapWater, mapPark;
  final Color logoA, logoB, paper, scrim, shadowColor;

  /// Tasarımdaki `sh` gölgesi: 0 8px 24px.
  List<BoxShadow> get cardShadow => [
        BoxShadow(color: shadowColor, blurRadius: 24, offset: const Offset(0, 8)),
      ];

  LinearGradient get buanGradient => LinearGradient(
        begin: const Alignment(-0.34, -0.94),
        end: const Alignment(0.34, 0.94),
        colors: [buanGradStart, buanGradEnd],
      );

  LinearGradient get heroGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [heroStart, heroEnd],
      );

  /// Hikâye halkası gradyanı (yeşil → turkuaz → mor).
  LinearGradient get storyRing => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [secondary, primary, buanFill],
        stops: const [0, .55, 1],
      );

  List<Color> get tiles => [tile1, tile2, tile3, tile4, tile5, tile6];

  /// Token değerleri: app_palette_values.dart.
  static const light = kLightPalette;
  static const dark = kDarkPalette;

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) =>
      (other is AppPalette && t >= .5) ? other : this;
}

extension AppPaletteX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}

extension ColorHex on Color {
  /// `#RRGGBB` — inline SVG dizelerinde renk vermek için.
  String get hex {
    final v = toARGB32() & 0xFFFFFF;
    return '#${v.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  /// SVG `opacity` / `fill-opacity` için 0–1 değeri.
  String get svgOpacity => a.toStringAsFixed(3);
}
