import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import 'marquee.dart';
import 'motion.dart';
import 'onb_icons.dart';

/// A3 · −8° eğik 4 marquee şeridi (26–44 sn döngü, alternatif yön).
class WelcomeMarquee extends StatelessWidget {
  const WelcomeMarquee({super.key, required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Etiket sırası tasarımdaki renk eşlemesiyle aynı.
    final colors = <(Color, Color)>[
      (p.tile2, p.onTile),
      (p.hotFill, p.onHot),
      (p.buanFill, p.onBuan),
      (p.tile4, p.onTile),
      (p.tile3, p.onTile),
      (p.tile6, p.onTile),
      (p.tile1, p.onTile),
      (p.tile5, p.onTile),
      (p.tile3, p.onTile),
      (p.tile1, p.onTile),
      (p.tile5, p.onTile),
      (p.tile3, p.onTile),
      (p.cta, p.onCta),
      (p.tile2, p.onTile),
    ];
    const tilt = [-3.0, 2.0, -1.0, 3.0, 0.0, -2.0];
    return ExcludeSemantics(
      child: Transform.rotate(
        angle: -8 * math.pi / 180,
        child: SizedBox(
          height: 4 * 60 + 3 * 14,
          child: OverflowBox(
            maxWidth: MediaQuery.sizeOf(context).width + 120,
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var r = 0; r < 4; r++) ...[
                  if (r > 0) const SizedBox(height: 14),
                  Opacity(
                    opacity: 1 - r * .12,
                    child: Marquee(
                      height: 60,
                      duration: Duration(seconds: 26 + r * 6),
                      reverse: r.isOdd,
                      children: [
                        for (var k = 0; k < tags.length; k++)
                          _Tag(
                            label: tags[(k + r * 3) % tags.length],
                            colors: colors[((k + r * 3) % tags.length) % colors.length],
                            tilt: tilt[(k + r) % 6],
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.colors, required this.tilt});

  final String label;
  final (Color, Color) colors;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Transform.rotate(
      angle: tilt * math.pi / 180,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.$1,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.onTile, width: 3),
          boxShadow: [BoxShadow(color: p.onTile, offset: const Offset(4, 4))],
        ),
        child: Text(label, maxLines: 1, style: AppTypography.display(20, height: 1, color: colors.$2)),
      ),
    );
  }
}

/// "100 BUAN seni bekliyor" — 2,6 sn süzülen mor rozet.
class WelcomeBonusPill extends StatelessWidget {
  const WelcomeBonusPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final coin =
        '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="11" fill="${p.onBuan.hex}" fill-opacity=".18"/>'
        '<path d="M9.5 7.5l7 4.5-7 4.5z" fill="${p.coinMark.hex}" stroke="${p.onBuan.hex}" stroke-width=".8"/></svg>';
    return LoopMotion(
      duration: const Duration(milliseconds: 1300),
      builder: (_, t, child) {
        final e = Curves.easeInOut.transform(t);
        return Transform.translate(
          offset: Offset(0, -6 * e),
          child: Transform.rotate(angle: (-3 + 6 * e) * math.pi / 180, child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
        decoration: BoxDecoration(
          color: p.buanFill,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: p.buanShadow.withValues(alpha: .4), blurRadius: 30, offset: const Offset(0, 10))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgArt(coin, width: 36, height: 36),
            const SizedBox(width: 10),
            Flexible(child: Text(label, style: AppTypography.body(16, weight: FontWeight.w900, color: p.onBuan))),
          ],
        ),
      ),
    );
  }
}

/// Ana CTA: 3 px dönen gradyan kenar (3 sn) + 2,4 sn nefes (1 → 1.025).
class BreathingCta extends StatelessWidget {
  const BreathingCta({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final inner = Container(
      height: 58,
      decoration: BoxDecoration(
        color: p.cta,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: p.cta.withValues(alpha: .53), blurRadius: 28)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTypography.body(18, weight: FontWeight.w900, color: p.onCta),
          ),
          const SizedBox(width: 8),
          AppIcon(OnbIcons.arrowRight, size: 20, color: p.onCta, strokeWidth: 2.8),
        ],
      ),
    );
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          Haptics.light();
          onPressed();
        },
        child: LoopMotion(
          duration: const Duration(seconds: 12),
          reverse: false,
          child: inner,
          builder: (_, t, child) {
            // 12 sn'lik ortak saat: gradyan 4 tur (3 sn), nefes 5 tur (2,4 sn).
            final breath = (1 - math.cos(t * 2 * math.pi * 5)) / 2;
            return Transform.scale(
              scale: 1 + .025 * breath,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    colors: [p.cta, p.glow, p.hotFill, p.cta],
                    transform: _Slide((t * 4) % 1),
                    tileMode: TileMode.repeated,
                  ),
                ),
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Slide extends GradientTransform {
  const _Slide(this.t);
  final double t;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) => Matrix4.translationValues(-bounds.width * t, 0, 0);
}
