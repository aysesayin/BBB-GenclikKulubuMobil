import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/auth/interest_option.dart';
import 'motion.dart';
import 'onb_icons.dart';

/// Tek ilgi baloncuğu: seçilince pastel dolgu, 3 px ink kenar, sert gölge,
/// scale 1.12 + 500 ms wobble. Ekran okuyucu için toggle buton.
class InterestBubble extends StatefulWidget {
  const InterestBubble({super.key, required this.option, required this.selected, required this.wobble, required this.onTap});

  final InterestOption option;
  final bool selected, wobble;
  final VoidCallback onTap;

  @override
  State<InterestBubble> createState() => _InterestBubbleState();
}

class _InterestBubbleState extends State<InterestBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _w = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

  @override
  void didUpdateWidget(InterestBubble old) {
    super.didUpdateWidget(old);
    if (widget.selected && widget.wobble && !old.selected && !context.reduceMotion) _w.forward(from: 0);
  }

  @override
  void dispose() {
    _w.dispose();
    super.dispose();
  }

  /// ilWob: 1 → 1.2 → 1.06 (−4°) → 1.15 (3°) → 1.12.
  (double, double) _wobble(double v) {
    const keys = [(0.0, 1.0, 0.0), (.3, 1.2, 0.0), (.55, 1.06, -4.0), (.75, 1.15, 3.0), (1.0, 1.12, 0.0)];
    for (var i = 0; i < keys.length - 1; i++) {
      final a = keys[i], b = keys[i + 1];
      if (v <= b.$1) {
        final f = (v - a.$1) / (b.$1 - a.$1);
        return (a.$2 + (b.$2 - a.$2) * f, a.$3 + (b.$3 - a.$3) * f);
      }
    }
    return (1.12, 0);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final o = widget.option;
    final on = widget.selected;
    final tile = p.tiles[(o.tile - 1).clamp(0, 5)];
    final fg = on ? p.onTile : p.ink;
    final body = LayoutBuilder(
      builder: (_, c) {
        final large = c.maxWidth >= 120;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? tile : (p.isDark ? p.onNight.withValues(alpha: .06) : p.sf),
            border: on ? Border.all(color: p.onTile, width: 3) : null,
            boxShadow: on ? [BoxShadow(color: p.onTile, offset: const Offset(6, 6)), BoxShadow(color: tile.withValues(alpha: .53), blurRadius: 30)] : null,
          ),
          child: CustomPaint(
            painter: on ? null : _DashedCircle(p.isDark ? p.onNight.withValues(alpha: .35) : p.borderStrong),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(OnbIcons.interest(o.icon), size: large ? 30 : 24, color: fg, strokeWidth: 2.2),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: c.maxWidth * .86,
                    child: Text(
                      o.label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.display(large ? 18 : 16, height: 1.05, color: fg),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return Semantics(
      button: true,
      toggled: on,
      label: o.label,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: GestureDetector(
        onTap: () {
          Haptics.light();
          widget.onTap();
        },
        child: AnimatedScale(
          scale: on ? 1.12 : 1,
          duration: const Duration(milliseconds: 350),
          curve: onbCurve,
          child: AnimatedBuilder(
            animation: _w,
            child: body,
            builder: (_, child) {
              if (!_w.isAnimating) return child!;
              final (s, r) = _wobble(_w.value);
              return Transform.rotate(angle: r * math.pi / 180, child: Transform.scale(scale: s / 1.12, child: child));
            },
          ),
        ),
      ),
    );
  }
}

class _DashedCircle extends CustomPainter {
  _DashedCircle(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2 - 1;
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final n = (2 * math.pi * r / 9).floor();
    for (var i = 0; i < n; i++) {
      final a = i * 2 * math.pi / n;
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), a, (2 * math.pi / n) * .55, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedCircle o) => o.color != color;
}
