import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

/// API'deki 1–6 karo indeksini palette rengine çevirir.
Color buanTile(AppPalette p, int? index) => p.tiles[((index ?? 1) - 1).clamp(0, 5)];

/// KVKK: herkese açık listelerde "Ad S." biçimi. Sunucu zaten kısaltsa da
/// istemci tam ad sızmasına karşı yeniden kısaltır.
String kvkkShortName(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  if (parts.length < 2) return parts.isEmpty ? '' : parts.first;
  final last = parts.last;
  final initial = last.endsWith('.') && last.characters.length <= 2 ? last : '${last.characters.first}.';
  return '${parts.first} $initial';
}

/// Ad → iki harfli baş harf (Türkçe büyük harf).
String initialsOf(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  final letters = parts.take(2).map((s) => s.characters.first).join();
  return trUpper(letters);
}

/// Kesikli yuvarlak çerçeve (kilitli rozet: `3px dashed line`).
class DashedRRectBorder extends StatelessWidget {
  const DashedRRectBorder({
    super.key,
    required this.child,
    required this.color,
    this.radius = 28,
    this.width = 3,
    this.dash = 7,
    this.gap = 5,
  });

  final Widget child;
  final Color color;
  final double radius, width, dash, gap;

  @override
  Widget build(BuildContext context) => CustomPaint(foregroundPainter: _DashedPainter(color, radius, width, dash, gap), child: child);
}

class _DashedPainter extends CustomPainter {
  _DashedPainter(this.color, this.radius, this.width, this.dash, this.gap);

  final Color color;
  final double radius, width, dash, gap;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(width / 2);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius - width / 2)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedPainter o) => o.color != color || o.radius != radius || o.width != width;
}

/// Bakiye eski → yeni sayımı (takas sonrası 600 ms). "Hareketi azalt" açıkken anında.
class BalanceTween extends StatelessWidget {
  const BalanceTween({
    super.key,
    required this.from,
    required this.to,
    required this.builder,
    this.duration = const Duration(milliseconds: 600),
  });

  final int from, to;
  final Duration duration;
  final Widget Function(BuildContext context, int value) builder;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return builder(context, to);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: from.toDouble(), end: to.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (ctx, v, _) => builder(ctx, v.round()),
    );
  }
}

/// Madde işaretli kural satırı (görev ve ödül kuralları).
class BuanBullet extends StatelessWidget {
  const BuanBullet({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.body(14, weight: FontWeight.w600, height: 1.5, color: context.palette.mut);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: Text('•  ', style: style)),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}
