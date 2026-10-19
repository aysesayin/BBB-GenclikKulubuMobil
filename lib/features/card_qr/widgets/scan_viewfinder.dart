import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';

/// 260 px vizör: köşeler 900 ms "nefes" alır (scale 1 → 1,05), tarama çizgisi 2,4 sn'de
/// iner-çıkar. "Hareketi azalt" açıkken ikisi de durur.
class ScanViewfinder extends StatefulWidget {
  const ScanViewfinder({super.key, this.size = 260, this.onTap, this.semanticLabel});

  final double size;

  /// Mock modunda vizöre dokunmak taramayı simüle eder.
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  State<ScanViewfinder> createState() => _ScanViewfinderState();
}

class _ScanViewfinderState extends State<ScanViewfinder> with TickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  late final AnimationController _line = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _breath.stop();
      _line.stop();
      _line.value = .5;
    } else {
      _breath.repeat(reverse: true);
      _line.repeat();
    }
  }

  @override
  void dispose() {
    _breath.dispose();
    _line.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final box = SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breath, _line]),
        builder: (context, _) {
          final scale = 1 + .05 * Curves.easeInOut.transform(_breath.value);
          // 8 % → 88 % → 8 %
          final t = _line.value < .5 ? _line.value * 2 : (1 - _line.value) * 2;
          final y = widget.size * (.08 + .8 * Curves.easeInOut.transform(t));
          return Transform.scale(
            scale: scale,
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _CornersPainter(p.glow))),
                Positioned(
                  left: 18,
                  right: 18,
                  top: y,
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: p.secondary,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [BoxShadow(color: p.secondary, blurRadius: 14)],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    return Semantics(
      label: widget.semanticLabel,
      button: widget.onTap != null,
      child: GestureDetector(onTap: widget.onTap, behavior: HitTestBehavior.opaque, child: box),
    );
  }
}

class _CornersPainter extends CustomPainter {
  _CornersPainter(this.color);
  final Color color;

  static const _len = 56.0, _r = 26.0, _w = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _w
      ..strokeCap = StrokeCap.round;
    const h = _w / 2;
    final w = size.width, ht = size.height;
    // c: köşe noktası, (dx, dy): içe doğru yön.
    Path corner(Offset c, double dx, double dy) => Path()
      ..moveTo(c.dx, c.dy + dy * _len)
      ..lineTo(c.dx, c.dy + dy * _r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + dx * _r, c.dy)
      ..lineTo(c.dx + dx * _len, c.dy);
    canvas
      ..drawPath(corner(const Offset(h, h), 1, 1), paint)
      ..drawPath(corner(Offset(w - h, h), -1, 1), paint)
      ..drawPath(corner(Offset(h, ht - h), 1, -1), paint)
      ..drawPath(corner(Offset(w - h, ht - h), -1, -1), paint);
  }

  @override
  bool shouldRepaint(_CornersPainter o) => o.color != color;
}
