import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/haptics.dart';

/// Tasarımdaki ortak eğri: cubic-bezier(.2,.8,.2,1).
const onbCurve = Cubic(.2, .8, .2, 1);

/// Hatalı girişte yatay sallanma (450 ms). [trigger] her arttığında oynar.
/// Hareketi azalt açıkken sallanmaz.
class ShakeX extends StatefulWidget {
  const ShakeX({super.key, required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  State<ShakeX> createState() => _ShakeXState();
}

class _ShakeXState extends State<ShakeX> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

  static const _keys = [0.0, -10.0, 9.0, -6.0, 4.0, 0.0];

  @override
  void didUpdateWidget(ShakeX old) {
    super.didUpdateWidget(old);
    if (widget.trigger != old.trigger && widget.trigger > 0 && !context.reduceMotion) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        child: widget.child,
        builder: (_, child) {
          final t = onbCurve.transform(_c.value) * (_keys.length - 1);
          final i = t.floor().clamp(0, _keys.length - 2);
          final dx = _keys[i] + (_keys[i + 1] - _keys[i]) * (t - i);
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
      );
}

/// Sürekli döngü animasyonu (süzülme, nefes, morf). Hareketi azalt → durur ve
/// [builder] 0 değeriyle çağrılır.
class LoopMotion extends StatefulWidget {
  const LoopMotion({super.key, required this.duration, required this.builder, this.reverse = true, this.child, this.phase = 0});

  final Duration duration;
  final bool reverse;
  final double phase;
  final Widget? child;
  final Widget Function(BuildContext context, double t, Widget? child) builder;

  @override
  State<LoopMotion> createState() => _LoopMotionState();
}

class _LoopMotionState extends State<LoopMotion> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration, value: widget.phase);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _c.stop();
      _c.value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: widget.reverse);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      AnimatedBuilder(animation: _c, child: widget.child, builder: (ctx, child) => widget.builder(ctx, _c.value, child));
}

/// Organik, yavaşça biçim değiştiren blob (CSS border-radius morf karşılığı).
class MorphBlob extends StatelessWidget {
  const MorphBlob({super.key, required this.size, required this.color, this.opacity = 1, this.period = const Duration(seconds: 10), this.seed = 0});

  final double size;
  final Color color;
  final double opacity;
  final Duration period;
  final int seed;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: LoopMotion(
          duration: period,
          reverse: false,
          phase: (seed * .23) % 1,
          builder: (_, t, _) => CustomPaint(
            size: Size.square(size),
            painter: _BlobPainter(color.withValues(alpha: color.a * opacity), t * 2 * math.pi, seed),
          ),
        ),
      );
}

class _BlobPainter extends CustomPainter {
  _BlobPainter(this.color, this.angle, this.seed);
  final Color color;
  final double angle;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    const n = 8;
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final pts = <Offset>[];
    for (var i = 0; i < n; i++) {
      final a = i * 2 * math.pi / n;
      final k = .86 + .12 * math.sin(angle + i * 1.7 + seed) + .05 * math.cos(2 * angle + i * .9);
      pts.add(c + Offset(math.cos(a), math.sin(a)) * r * k);
    }
    // Catmull-Rom → kübik Bézier ile yumuşak kapalı eğri.
    final path = Path()..moveTo((pts[0].dx + pts[1].dx) / 2, (pts[0].dy + pts[1].dy) / 2);
    for (var i = 0; i < n; i++) {
      final p1 = pts[(i + 1) % n], p2 = pts[(i + 2) % n];
      path.quadraticBezierTo(p1.dx, p1.dy, (p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
    }
    canvas.drawPath(path..close(), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BlobPainter o) => o.angle != angle || o.color != color;
}
