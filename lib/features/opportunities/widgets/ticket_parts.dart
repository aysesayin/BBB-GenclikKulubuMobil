import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Kesik çizgi (kupon "yırtık kenar" ayracı). [vertical] → dikey.
class DashedLine extends StatelessWidget {
  const DashedLine({super.key, required this.color, this.vertical = false, this.thickness = 2, this.dash = 6, this.gap = 4});

  final Color color;
  final bool vertical;
  final double thickness, dash, gap;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: vertical ? Size(thickness, double.infinity) : Size(double.infinity, thickness),
    painter: _DashPainter(color, vertical, thickness, dash, gap),
  );
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color, this.vertical, this.thickness, this.dash, this.gap);
  final Color color;
  final bool vertical;
  final double thickness, dash, gap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    final length = vertical ? size.height : size.width;
    for (var d = 0.0; d < length; d += dash + gap) {
      final e = (d + dash).clamp(0, length).toDouble();
      if (vertical) {
        canvas.drawLine(Offset(size.width / 2, d), Offset(size.width / 2, e), paint);
      } else {
        canvas.drawLine(Offset(d, size.height / 2), Offset(e, size.height / 2), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashPainter o) => o.color != color;
}

/// Kesik çerçeveli yuvarlatılmış kutu (indirim kodu kutusu).
class DashedBox extends StatelessWidget {
  const DashedBox({
    super.key,
    required this.child,
    required this.color,
    this.radius = 18,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
    this.background,
  });

  final Widget child;
  final Color color;
  final Color? background;
  final double radius;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _DashedRRectPainter(color, radius),
    child: Container(
      padding: padding,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(radius)),
      child: child,
    ),
  );
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter(this.color, this.radius);
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()..addRRect(RRect.fromRectAndRadius((Offset.zero & size).deflate(1), Radius.circular(radius)));
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 10) {
        canvas.drawPath(m.extractPath(d, d + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRectPainter o) => o.color != color;
}

/// "47:58:12" geri sayımı; [builder] metni sarar ("… içinde kullan").
class HmsCountdown extends StatefulWidget {
  const HmsCountdown({super.key, required this.deadline, required this.builder});

  final DateTime deadline;
  final Widget Function(BuildContext context, String hms, Duration left) builder;

  static String format(Duration d) {
    final s = d.isNegative ? 0 : d.inSeconds;
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(s ~/ 3600)}:${two(s % 3600 ~/ 60)}:${two(s % 60)}';
  }

  @override
  State<HmsCountdown> createState() => _HmsCountdownState();
}

class _HmsCountdownState extends State<HmsCountdown> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.deadline.difference(DateTime.now());
    return widget.builder(context, HmsCountdown.format(left), left);
  }
}

/// Kod kutucukları (4 hane / PNR parçaları).
class PinBoxes extends StatelessWidget {
  const PinBoxes({super.key, required this.parts, this.minWidth = 44, this.height = 54, this.fontSize = 30, this.radius = 14});

  final List<String> parts;
  final double minWidth, height, fontSize, radius;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < parts.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Container(
            constraints: BoxConstraints(minWidth: minWidth),
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(radius)),
            alignment: Alignment.center,
            child: Text(parts[i], style: AppTypography.display(fontSize, height: 1, color: p.ink)),
          ),
        ],
      ],
    );
  }
}

/// Ekran okuyucu için harf harf okuma: "EXT-7K2Q-91" → "E X T 7 K 2 Q 9 1".
String spellOut(String code) => code.replaceAll(RegExp(r'[\s-]'), '').split('').join(' ');
