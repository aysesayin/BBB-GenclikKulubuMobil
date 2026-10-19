import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import 'app_icon.dart';

/// Organik "blob" şekilleri — eski kimlikle süreklilik. Yollar tasarım dosyalarından.
enum BlobShape {
  /// 320×300 — Keşfet sağ üst, Fırsatlar, boş durum.
  a('0 0 320 300', 'M170 20c60-10 130 30 140 100s-40 150-120 160S20 250 30 170 110 30 170 20z'),

  /// 220×200 — Keşfet sol.
  b('0 0 220 200', 'M110 10c50 0 100 30 100 90s-40 95-100 90S10 150 15 95 60 10 110 10z'),

  /// 300×260 — Fırsatlar başlık arkası.
  c('0 0 300 260', 'M160 10c80 0 135 55 130 125s-60 120-140 120S10 205 18 130 80 10 160 10z'),

  /// 420×400 — splash büyük.
  d('0 0 420 400', 'M220 20c110 0 190 70 180 180s-90 190-200 180S10 290 30 180 110 20 220 20z'),

  /// 360×340 — splash orta.
  e('0 0 360 340', 'M180 10c90 0 170 60 170 160s-70 160-170 160S10 260 20 160 90 10 180 10z'),

  /// 320×300 — boş durum / çevrimdışı arka planı.
  f('0 0 320 300', 'M170 10c80 0 140 60 135 140s-65 140-145 140S10 220 18 140 90 10 170 10z');

  const BlobShape(this.viewBox, this.path);
  final String viewBox;
  final String path;

  Size get size {
    final p = viewBox.split(' ').map(double.parse).toList();
    return Size(p[2], p[3]);
  }
}

/// Tek blob. Konumlandırmak için [Positioned] içinde kullanın.
class Blob extends StatelessWidget {
  const Blob({super.key, required this.shape, required this.color, this.width, this.opacity = 1});

  final BlobShape shape;
  final Color color;
  final double? width;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final s = shape.size;
    final w = width ?? s.width;
    return SvgArt(
      '<svg viewBox="${shape.viewBox}"><path d="${shape.path}" fill="${color.hex}" fill-opacity="$opacity"/></svg>',
      width: w,
      height: w * s.height / s.width,
    );
  }
}

/// Sık kullanılan arka plan: sağ üstte nane, solda pembe blob (Keşfet düzeni).
/// [child] üstte çizilir.
class BlobBackground extends StatelessWidget {
  const BlobBackground({super.key, required this.child, this.variant = BlobLayout.explore});

  final Widget child;
  final BlobLayout variant;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: p.bg)),
        ...switch (variant) {
          BlobLayout.explore => [
              Positioned(top: -90, right: -110, child: Blob(shape: BlobShape.a, color: p.mint)),
              Positioned(top: 40, left: -120, child: Blob(shape: BlobShape.b, color: p.blob)),
            ],
          BlobLayout.cornerPink => [Positioned(top: -110, right: -90, child: Blob(shape: BlobShape.c, color: p.blob))],
          BlobLayout.cornerMint => [Positioned(top: -110, right: -90, child: Blob(shape: BlobShape.c, color: p.mint))],
          BlobLayout.none => const <Widget>[],
        },
        Positioned.fill(child: child),
      ],
    );
  }
}

enum BlobLayout { explore, cornerPink, cornerMint, none }
