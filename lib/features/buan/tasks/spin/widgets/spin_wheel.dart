import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/formatters.dart';
import '../../../../../core/utils/haptics.dart';
import '../../../../../core/widgets/widgets.dart';
import '../../../../../data/models/buan_tasks/daily_spin.dart';

/// Şans çarkı. [targetIndex] null'dan bir değere geçince 3,2 sn easeOutQuart ile
/// o dilime döner, her dilim geçişinde selectionClick haptik verir, sonunda [onEnd].
/// "Hareketi azalt" açıkken doğrudan sonuca atlar.
class SpinWheel extends StatefulWidget {
  const SpinWheel({
    super.key,
    required this.slices,
    required this.targetIndex,
    required this.onEnd,
    required this.semanticLabel,
    this.dimmed = false,
  });

  final List<SpinSlice> slices;
  final int? targetIndex;
  final VoidCallback onEnd;
  final String semanticLabel;
  final bool dimmed;

  @override
  State<SpinWheel> createState() => _SpinWheelState();
}

class _SpinWheelState extends State<SpinWheel> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: AppDurations.spin);
  Animation<double> _rotation = const AlwaysStoppedAnimation(0);
  double _deg = 0;
  int _lastSlice = 0;

  double get _sweep => 360 / math.max(1, widget.slices.length);

  @override
  void initState() {
    super.initState();
    _c.addListener(_tick);
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onEnd();
    });
  }

  @override
  void didUpdateWidget(SpinWheel old) {
    super.didUpdateWidget(old);
    final t = widget.targetIndex;
    if (t != null && old.targetIndex == null) _spinTo(t);
  }

  void _spinTo(int index) {
    final center = index * _sweep + _sweep / 2;
    final base = _deg - (_deg % 360);
    final target = base + 360 * 5 + (360 - center);
    if (context.reduceMotion) {
      setState(() => _deg = target);
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        if (mounted) widget.onEnd();
      });
      return;
    }
    _rotation = Tween<double>(begin: _deg, end: target).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutQuart));
    _c.forward(from: 0);
  }

  void _tick() {
    _deg = _rotation.value;
    final under = (((360 - (_deg % 360)) % 360) / _sweep).floor();
    if (under != _lastSlice) {
      _lastSlice = under;
      Haptics.selection();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, box) {
        final size = math.max(120.0, math.min(320.0, math.min(box.maxWidth, box.maxHeight - 20)));
        final wheel = RepaintBoundary(
          child: CustomPaint(size: Size.square(size), painter: _WheelPainter(widget.slices, p)),
        );
        return Center(
          child: Semantics(
            label: widget.semanticLabel,
            image: true,
            child: Opacity(
              opacity: widget.dimmed ? .55 : 1,
              child: SizedBox(
                width: size,
                height: size + 18,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 18,
                      left: 0,
                      child: AnimatedBuilder(
                        animation: _c,
                        child: wheel,
                        builder: (_, child) => Transform.rotate(angle: _deg * math.pi / 180, child: child),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: size / 2 - 22,
                      child: SvgArt(
                        '<svg viewBox="0 0 44 48"><path d="M22 46 L4 10 Q2 2 10 2 H34 Q42 2 40 10 Z" fill="${p.cta.hex}" '
                        'stroke="${p.onTile.hex}" stroke-width="3" stroke-linejoin="round"/></svg>',
                        width: 44,
                        height: 48,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter(this.slices, this.p);

  final List<SpinSlice> slices;
  final AppPalette p;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 300; // tasarım viewBox 300
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, 148 * k, Paint()..color = p.onTile);
    final n = slices.length;
    if (n == 0) return;
    final sweep = 2 * math.pi / n;
    final colors = [p.tile6, p.tile2, p.tile1, p.tile5, p.tile6, p.tile4, p.tile1, p.tile3];
    final rect = Rect.fromCircle(center: c, radius: 146 * k);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * k
      ..color = p.onTile;
    for (var i = 0; i < n; i++) {
      final start = -math.pi / 2 + i * sweep;
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..arcTo(rect, start, sweep, false)
        ..close();
      canvas
        ..drawPath(path, Paint()..color = colors[i % colors.length])
        ..drawPath(path, stroke);
      final tp = TextPainter(
        text: TextSpan(
          text: Fmt.number(slices[i].amount),
          style: AppTypography.display(22 * k, color: p.onTile),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      canvas
        ..save()
        ..translate(c.dx, c.dy)
        ..rotate(start + sweep / 2 + math.pi / 2)
        ..translate(0, -92 * k);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2 - 4 * k));
      canvas.restore();
    }
    canvas
      ..drawCircle(c, 34 * k, Paint()..color = p.paper)
      ..drawCircle(
        c,
        34 * k,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 * k
          ..color = p.onTile,
      );
    final tri = Path()
      ..moveTo(c.dx - 9 * k, c.dy - 14 * k)
      ..lineTo(c.dx + 9 * k, c.dy)
      ..lineTo(c.dx - 9 * k, c.dy + 14 * k)
      ..close();
    canvas.drawPath(tri, Paint()..color = p.coinMark);
  }

  @override
  bool shouldRepaint(_WheelPainter o) => o.slices != slices || o.p != p;
}
