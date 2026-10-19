import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'app_icon.dart';
import 'app_icons.dart';

/// Yatay ilerleme çubuğu (stok, kontenjan, seviye). [gradient] verilirse dolgu gradyan olur.
/// Erişilebilirlik: yalnız renk değil, yanında metin de gösterilmeli (ör. "Son 12 kod").
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({super.key, required this.value, this.color, this.gradient, this.height = 6, this.track, this.semanticsValue});

  final double value;
  final Color? color, track;
  final Gradient? gradient;
  final double height;
  final String? semanticsValue;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final v = value.clamp(0.0, 1.0);
    return Semantics(
      value: semanticsValue ?? '${(v * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: track ?? p.sf2)),
              FractionallySizedBox(
                widthFactor: v,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: gradient == null ? (color ?? p.primary) : null,
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(height / 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dairesel ilerleme halkası (görev kartı 44 px, kart QR geri sayımı).
class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value, required this.color, this.size = 44, this.stroke = 4, this.track, this.child});

  final double value;
  final Color color;
  final Color? track;
  final double size, stroke;
  final Widget? child;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(value.clamp(0, 1), color, track ?? context.palette.sf2, stroke),
          child: Center(child: child),
        ),
      );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v, this.color, this.track, this.stroke);
  final double v, stroke;
  final Color color, track;

  @override
  void paint(Canvas canvas, Size size) {
    final r = (size.shortestSide - stroke) / 2;
    final c = size.center(Offset.zero);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = track;
    canvas.drawCircle(c, r, base);
    if (v <= 0) return;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * v, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.v != v || o.color != color || o.track != track;
}

/// Kalan süre çipi: saat ikonu + "12 gün kaldı". [urgent] → sıcak pembe.
class DaysLeftLabel extends StatelessWidget {
  const DaysLeftLabel({super.key, required this.days, this.urgent = false, this.color});

  final int days;
  final bool urgent;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = color ?? (urgent ? p.pinkT : p.mut);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(AppIcons.clock, size: 14, color: c, strokeWidth: 2.4),
        const SizedBox(width: 4),
        Text(context.l10n.daysLeft(days), style: AppTypography.body(12, weight: FontWeight.w800, color: c)),
      ],
    );
  }
}

/// Geri sayım (mm:ss) — sepet 5 dk rezervi, QR yenileme. Sunucu saatine göre
/// [deadline] verilir; uygulama arka plandan dönse de doğru kalan süreyi gösterir.
class CountdownText extends StatefulWidget {
  const CountdownText({super.key, required this.deadline, required this.style, this.onFinished, this.now, this.showHours = false});

  /// true → bir saatten uzun sürelerde hh:mm:ss.
  final bool showHours;

  final DateTime deadline;
  final TextStyle style;
  final VoidCallback? onFinished;

  /// Testler için saat kaynağı.
  final DateTime Function()? now;

  @override
  State<CountdownText> createState() => _CountdownTextState();
}

class _CountdownTextState extends State<CountdownText> {
  Timer? _timer;
  bool _fired = false;

  DateTime _now() => widget.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) return;
    final left = widget.deadline.difference(_now());
    if (left <= Duration.zero && !_fired) {
      _fired = true;
      widget.onFinished?.call();
    }
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.deadline.difference(_now());
    final d = left.isNegative ? Duration.zero : left;
    return Text(widget.showHours ? Fmt.hhmmss(d) : Fmt.mmss(d), style: widget.style);
  }
}
