import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import 'discover_palette.dart';
import 'events_icons.dart';

/// G2 kapak (270 px). Görsel adresi yoksa çizim: "mountain" → tasarımdaki dağ sahnesi,
/// diğerleri → ton zemin + dalga + büyük ikon.
class EventCover extends StatelessWidget {
  const EventCover({super.key, required this.cover, required this.icon, required this.tone, this.url, this.height = 270});

  final String cover, icon, tone;
  final String? url;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final art = switch (cover) {
      'mountain' => ColoredBox(color: p.primary, child: SvgArt(_mountain(p), fit: BoxFit.cover)),
      _ => _GenericCover(icon: icon, tone: tone),
    };
    return SizedBox(
      height: height,
      width: double.infinity,
      child: url == null
          ? art
          : CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover, placeholder: (_, _) => art, errorWidget: (_, _, _) => art),
    );
  }

  static String _mountain(AppPalette p) => '<svg viewBox="0 0 393 270" preserveAspectRatio="xMidYMid slice">'
      '<circle cx="300" cy="80" r="34" fill="${p.cta.hex}"/>'
      '<path d="M-20 270 L100 110 L170 190 L250 90 L420 270 Z" fill="${p.grnT.hex}"/>'
      '<path d="M220 130 L250 90 L280 130 Z" fill="${p.paper.hex}"/>'
      '<path d="M-20 270 L60 200 L140 250 L230 180 L420 270 Z" fill="${p.secondary.hex}"/>'
      '<path d="M60 270 q10-40 20 0M90 270 q12-50 24 0M300 270 q10-40 20 0" fill="${p.grnT.hex}"/></svg>';
}

class _GenericCover extends StatelessWidget {
  const _GenericCover({required this.icon, required this.tone});

  final String icon, tone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final wave = '<svg viewBox="0 0 393 270" preserveAspectRatio="none">'
        '<path d="M-20 270 C70 150 150 230 220 170 S330 110 420 170 L420 270 Z" fill="${p.paper.hex}" fill-opacity=".35"/>'
        '<circle cx="70" cy="90" r="26" fill="${p.paper.hex}" fill-opacity=".3"/></svg>';
    return ColoredBox(
      color: paletteColor(p, tone),
      child: Stack(
        children: [
          Positioned.fill(child: SvgArt(wave, fit: BoxFit.fill)),
          Positioned(
            right: 40,
            top: 70,
            child: AppIcon(EventIcons.forKey(icon), size: 110, color: p.onTile, strokeWidth: 1.6),
          ),
        ],
      ),
    );
  }
}

/// Kapak üstündeki yarı saydam beyaz 44 px yuvarlak buton (geri / paylaş / favori).
class CoverIconButton extends StatelessWidget {
  const CoverIconButton({super.key, required this.icon, required this.semanticLabel, required this.onPressed, this.color, this.iconSize = 22, this.fill});

  final String icon, semanticLabel;
  final VoidCallback onPressed;
  final Color? color, fill;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: p.paper.withValues(alpha: .92),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 44,
            child: Center(child: AppIcon(icon, size: iconSize, color: color ?? p.onTile, strokeWidth: 2.4, fill: fill)),
          ),
        ),
      ),
    );
  }
}
