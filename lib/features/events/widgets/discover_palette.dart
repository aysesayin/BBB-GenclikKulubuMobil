import 'package:flutter/widgets.dart';

import '../../../core/theme/app_theme.dart';

/// API'den gelen palette adını ("tile2", "hotFill", "cta"…) renge çevirir.
/// Etkinlik, harita ve yer ekranlarında ortak kullanılır; bilinmeyen ad → [fallback].
Color paletteColor(AppPalette p, String? name, {Color? fallback}) => switch (name) {
      'tile1' => p.tile1,
      'tile2' => p.tile2,
      'tile3' => p.tile3,
      'tile4' => p.tile4,
      'tile5' => p.tile5,
      'tile6' => p.tile6,
      'hotFill' || 'hot' => p.hotFill,
      'cta' => p.cta,
      'secondary' => p.secondary,
      'buanFill' => p.buanFill,
      'primary' => p.primary,
      'teal' => p.teal,
      'pink' => p.pink,
      'mint' => p.mint,
      'sky' => p.sky,
      _ => fallback ?? p.tile4,
    };

/// Yer galerisi çizim tonu → (zemin, gövde, çatı) — tasarım G4 `G[]` dizisi.
(Color, Color, Color) galleryTones(AppPalette p, String tone) => switch (tone) {
      'pink' => (p.tile1, p.hotFill, p.buanFill),
      'sun' => (p.tile6, p.cta, p.ctaShadow),
      _ => (p.tile3, p.primary, p.tealB),
    };
