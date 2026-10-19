import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../l10n/l10n.dart';
import 'marquee.dart';
import 'motion.dart';

/// A2 · 2. hikâye: kayan kupon şeridi. Kupona dokun → 700 ms yukarı fırlar,
/// "%25" 550 ms patlar.
class StoryCouponScene extends StatelessWidget {
  const StoryCouponScene({super.key, required this.flung, required this.onFling});

  final int? flung;
  final ValueChanged<int> onFling;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final coupons = [
      (l.onbCoupon1Off, l.onbCoupon1Brand, p.tile3),
      (l.onbCoupon2Off, l.onbCoupon2Brand, p.tile1),
      (l.onbCoupon3Off, l.onbCoupon3Brand, p.tile5),
      (l.onbCoupon4Off, l.onbCoupon4Brand, p.tile2),
      (l.onbCoupon5Off, l.onbCoupon5Brand, p.tile4),
      (l.onbCoupon6Off, l.onbCoupon6Brand, p.tile5),
    ];
    const tilts = [-4.0, 3.0, -2.0, 5.0, -3.0, 2.0];
    final caught = flung == null ? null : coupons[flung! % coupons.length];
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Marquee(
          height: 150,
          duration: const Duration(seconds: 14),
          gap: 16,
          leading: 20,
          paused: flung != null,
          children: [
            for (var k = 0; k < coupons.length; k++)
              _Coupon(
                off: coupons[k].$1,
                brand: coupons[k].$2,
                color: coupons[k].$3,
                tilt: tilts[k],
                flung: flung == k,
                onTap: () {
                  Haptics.light();
                  onFling(k);
                },
              ),
          ],
        ),
        if (caught != null)
          Positioned(
            left: 0,
            right: 0,
            top: -40,
            child: _Burst(off: caught.$1, key: ValueKey(flung)),
          ),
      ],
    );
  }
}

class _Coupon extends StatelessWidget {
  const _Coupon({required this.off, required this.brand, required this.color, required this.tilt, required this.flung, required this.onTap});

  final String off, brand;
  final Color color;
  final double tilt;
  final bool flung;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final card = Container(
      width: 210,
      height: 128,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.onTile, width: 3),
        boxShadow: [BoxShadow(color: p.onTile, offset: const Offset(5, 5))],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(off, style: AppTypography.display(44, height: 1, color: p.onTile)),
              Text(brand, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.body(13, weight: FontWeight.w900, color: p.onTile)),
            ],
          ),
          Positioned(right: 38, top: -17, bottom: -17, child: CustomPaint(size: const Size(3, 0), painter: _Dash(p.onTile))),
        ],
      ),
    );
    return Semantics(
      button: true,
      label: context.l10n.onbCouponFling(brand, off),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: flung ? null : onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: flung ? 1 : 0),
          duration: flung && !context.reduceMotion ? const Duration(milliseconds: 700) : Duration.zero,
          curve: onbCurve,
          child: card,
          builder: (_, v, child) => Opacity(
            opacity: 1 - v,
            child: Transform.translate(
              offset: Offset(0, -420 * v),
              child: Transform.rotate(angle: (tilt + (-28 - tilt) * v) * 3.1416 / 180, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dash extends CustomPainter {
  _Dash(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3;
    for (var y = 0.0; y < size.height; y += 9) {
      canvas.drawLine(Offset(1.5, y), Offset(1.5, (y + 5).clamp(0, size.height)), paint);
    }
  }

  @override
  bool shouldRepaint(_Dash o) => o.color != color;
}

class _Burst extends StatelessWidget {
  const _Burst({super.key, required this.off});

  final String off;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final style = AppTypography.display(120, height: 1);
    return Semantics(
      liveRegion: true,
      label: context.l10n.onbCouponCaught,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: context.reduceMotion ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 550),
        builder: (_, v, child) {
          // hkBurst: scale .2 → 1.25 → 1, rotate −12° → 4° → −4°.
          final s = v < .55 ? .2 + 1.05 * (v / .55) : 1.25 - .25 * ((v - .55) / .45);
          final r = v < .55 ? -12 + 16 * (v / .55) : 4 - 8 * ((v - .55) / .45);
          return Opacity(opacity: (v / .55).clamp(0, 1), child: Transform.rotate(angle: r * 3.1416 / 180, child: Transform.scale(scale: s, child: child)));
        },
        child: ExcludeSemantics(
          child: Column(
            children: [
              Stack(
                children: [
                  Transform.translate(offset: const Offset(6, 6), child: Text(off, style: style.copyWith(color: p.onTile))),
                  Text(
                    off,
                    style: style.copyWith(
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 6
                        ..color = p.onTile,
                    ),
                  ),
                  Text(off, style: style.copyWith(color: p.pinkT)),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(14)),
                child: Text(context.l10n.onbCouponCaught, style: AppTypography.body(15, weight: FontWeight.w900, color: p.onChip)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
