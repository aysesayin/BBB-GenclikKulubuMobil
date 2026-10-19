import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../onboarding/widgets/motion.dart';
import '../../onboarding/widgets/poster_title.dart';

/// A1 sahnesi (393×852 tasarım karesi, ekrana `cover` ile oturur).
/// [t] 0→1 = 2,2 sn: nokta → koşan figür + iz → Bursa silüeti → blob'lar + logo.
class SplashScene extends StatelessWidget {
  const SplashScene({super.key, required this.t});

  final Animation<double> t;

  static const _total = 2.2;

  /// [a]–[b] saniye aralığındaki ilerleme (0–1).
  static double seg(double v, double a, double b, [Curve curve = onbCurve]) =>
      curve.transform(((v * _total - a) / (b - a)).clamp(0.0, 1.0));

  static String figure(String a, String b) =>
      '<svg viewBox="0 0 64 64"><circle cx="38" cy="12" r="7" fill="$a"/><path d="M22 30 L34 22 L44 30 L52 26 M34 22 L30 40 L40 50 M30 40 L18 48" '
      'stroke="$b" stroke-width="6" fill="none" stroke-linecap="round" stroke-linejoin="round"/></svg>';

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: 393,
        height: 852,
        child: AnimatedBuilder(
          animation: t,
          builder: (context, _) {
            final v = t.value;
            final blobs = seg(v, 1.3, 1.75);
            final logo = seg(v, 1.45, 1.9);
            final dotIn = seg(v, 0, .35, Curves.easeOutBack);
            final dotPulse = seg(v, .35, .6, Curves.easeInOut);
            final dotOut = seg(v, .6, .75);
            final run = seg(v, .35, 1.1, Curves.easeInOut);
            final runOp = seg(v, .35, .45) * (1 - seg(v, 1.1, 1.25));
            final draw = seg(v, .35, 1.25, Curves.easeInOut);
            final trailOp = 1 - .82 * seg(v, 1.25, 1.6);
            final cab = seg(v, 1.0, 1.2);
            final cabOp = cab * (1 - .75 * seg(v, 1.3, 1.6));
            final dotScale = dotIn * (1 + .35 * (dotPulse < .5 ? dotPulse * 2 : (1 - dotPulse) * 2)) * (1 - .8 * dotOut);
            return Stack(
              clipBehavior: Clip.none,
              children: [
                _blob(left: -110, top: 90, size: 300, color: p.blob, k: blobs, seed: 0, secs: 9),
                _blob(left: 203, top: 300, size: 320, color: p.mint, k: blobs, seed: 3, secs: 11),
                _blob(left: 40, top: 662, size: 340, color: p.sky, k: blobs, seed: 5, secs: 13),
                Positioned(
                  left: 189,
                  top: 389,
                  child: Opacity(
                    opacity: (1 - dotOut).clamp(0, 1),
                    child: Transform.scale(
                      scale: dotScale,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: p.glow,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: p.glow, blurRadius: 24, spreadRadius: 8),
                            BoxShadow(color: p.primary, blurRadius: 80, spreadRadius: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 300,
                  child: CustomPaint(
                    size: const Size(393, 220),
                    painter: _TrailPainter(
                      progress: draw,
                      opacity: draw == 0 ? 0 : trailOp,
                      cab: cabOp,
                      cabShift: 1 - cab,
                      colors: [p.primary, p.secondary, p.cta],
                      glow: p.glow,
                      cabColor: p.cta,
                      window: p.bg,
                    ),
                  ),
                ),
                Positioned(
                  left: 60 - 40 + 260 * run,
                  top: 418,
                  child: Opacity(opacity: runOp, child: SvgArt(figure(p.logoA.hex, p.logoB.hex), width: 56, height: 56)),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 296,
                  child: Opacity(
                    opacity: logo,
                    child: Transform.translate(
                      offset: Offset(0, 24 * (1 - logo)),
                      child: Transform.scale(scale: .94 + .06 * logo, child: const _Logo()),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _blob({required double left, required double top, required double size, required Color color, required double k, required int seed, required int secs}) =>
      Positioned(
        left: left,
        top: top,
        child: Opacity(
          opacity: k,
          child: Transform.scale(
            scale: .3 + .7 * k,
            child: MorphBlob(size: size, color: color, opacity: .9, seed: seed, period: Duration(seconds: secs)),
          ),
        ),
      );
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return Semantics(
      label: l.onbSplashLogoSemantics,
      image: true,
      excludeSemantics: true,
      child: Column(
        children: [
          SvgArt(SplashScene.figure(p.logoA.hex, p.logoB.hex), width: 72, height: 72),
          const SizedBox(height: 4),
          Text(l.brandCity, style: AppTypography.script(38, color: p.logoA)),
          const SizedBox(height: 4),
          Text(l.brandClub, style: AppTypography.display(40, height: 1, color: p.logoB).copyWith(letterSpacing: 1)),
          const SizedBox(height: 22),
          Transform(
            transform: PosterTitle.skew,
            alignment: Alignment.center,
            child: Text(l.onbSplashTagline, style: AppTypography.display(30, height: 1, color: p.ink).copyWith(letterSpacing: .5)),
          ),
        ],
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  _TrailPainter({
    required this.progress,
    required this.opacity,
    required this.cab,
    required this.cabShift,
    required this.colors,
    required this.glow,
    required this.cabColor,
    required this.window,
  });

  final double progress, opacity, cab, cabShift;
  final List<Color> colors;
  final Color glow, cabColor, window;

  /// Uludağ zirveleri → Ulu Cami kubbeleri → minare → teleferik hattı.
  static final Path _path = Path()
    ..moveTo(-10, 170)
    ..lineTo(40, 170)
    ..lineTo(95, 72)
    ..lineTo(118, 96)
    ..lineTo(150, 38)
    ..lineTo(184, 112)
    ..lineTo(204, 170)
    ..lineTo(214, 170)
    ..quadraticBezierTo(221, 148, 228, 170)
    ..quadraticBezierTo(235, 148, 242, 170)
    ..quadraticBezierTo(249, 148, 256, 170)
    ..quadraticBezierTo(263, 148, 270, 170)
    ..lineTo(276, 170)
    ..lineTo(276, 116)
    ..lineTo(280, 104)
    ..lineTo(284, 116)
    ..lineTo(284, 170)
    ..lineTo(300, 170)
    ..lineTo(410, 84);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress > 0 && opacity > 0) {
      final metric = _path.computeMetrics().first;
      final part = metric.extractPath(0, metric.length * progress);
      final shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, 0),
        [for (final c in colors) c.withValues(alpha: c.a * opacity)],
        const [0, .5, 1],
      );
      Paint stroke(double w) => Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(
        part,
        stroke(5)
          ..color = glow.withValues(alpha: .6 * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawPath(part, stroke(5)..shader = shader);
    }
    if (cab > 0) {
      canvas.save();
      canvas.translate(-30 * cabShift, 20 * cabShift);
      final c = Paint()..color = cabColor.withValues(alpha: cab);
      canvas.drawLine(const Offset(342, 132), const Offset(342, 146), c..strokeWidth = 3);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(330, 146, 24, 20), const Radius.circular(6)), c);
      final w = Paint()..color = window.withValues(alpha: cab);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(335, 151, 6, 6), const Radius.circular(2)), w);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(343, 151, 6, 6), const Radius.circular(2)), w);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_TrailPainter o) => o.progress != progress || o.opacity != opacity || o.cab != cab || o.colors != colors;
}
