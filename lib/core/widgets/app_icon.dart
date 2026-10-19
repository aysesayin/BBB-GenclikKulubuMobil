import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_palette.dart';

/// Tasarımdaki çizgi ikonlar (24×24 viewBox, 2–2.4 px yuvarlak uçlu çizgi).
/// [path] bir SVG `d` dizesidir — bkz. [AppIcons].
///
/// Renk verilmezse `IconTheme`/`DefaultTextStyle` rengini kullanır ("currentColor").
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.path, {
    super.key,
    this.size = 22,
    this.color,
    this.strokeWidth = 2.2,
    this.fill,
    this.semanticLabel,
  });

  final String path;
  final double size;
  final Color? color;
  final double strokeWidth;

  /// Dolgu rengi (ör. dolu kalp, seri ateşi). null → yalnız çizgi.
  final Color? fill;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? DefaultTextStyle.of(context).style.color ?? Colors.black;
    final f = fill == null ? 'none' : fill!.hex;
    final fo = fill == null ? '' : ' fill-opacity="${fill!.svgOpacity}"';
    final svg = '<svg viewBox="0 0 24 24" fill="$f"$fo stroke="${c.hex}" stroke-opacity="${c.svgOpacity}" '
        'stroke-width="$strokeWidth" stroke-linecap="round" stroke-linejoin="round"><path d="$path"/></svg>';
    final pic = SvgPicture.string(svg, width: size, height: size, excludeFromSemantics: semanticLabel == null);
    if (semanticLabel == null) return ExcludeSemantics(child: pic);
    return Semantics(label: semanticLabel, image: true, child: pic);
  }
}

/// Serbest SVG çizimi (blob, illüstrasyon, harita süsü). Renkleri
/// `palette.x.hex` ile dizeye gömün. Daima dekoratif kabul edilir.
class SvgArt extends StatelessWidget {
  const SvgArt(this.svg, {super.key, this.width, this.height, this.fit = BoxFit.contain});

  final String svg;
  final double? width, height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) =>
      ExcludeSemantics(child: SvgPicture.string(svg, width: width, height: height, fit: fit));
}
