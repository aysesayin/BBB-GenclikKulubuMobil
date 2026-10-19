import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';

/// Tasarımdaki kinetik "poster" tipografi: −8° eğik, satır satır sağdan kayarak
/// girer (600 ms, 120–140 ms arayla). Hareketi azalt → 400 ms fade.
///
/// Font: Anton (tasarımdaki gibi); çok uzun satırlar sığması için küçültülür.
class PosterTitle extends StatelessWidget {
  const PosterTitle({
    super.key,
    required this.lines,
    required this.size,
    this.color,
    this.highlight,
    this.highlightLine = 1,
    this.from = const Offset(70, 0),
    this.stagger = const Duration(milliseconds: 140),
    this.animate = true,
    this.align = CrossAxisAlignment.start,
    this.lineHeight = .9,
  });

  final List<String> lines;
  final double size;
  final Color? color, highlight;
  final int highlightLine;

  /// Giriş ofseti (A2: 70 px sağdan, A3: 40 px aşağıdan).
  final Offset from;
  final Duration stagger;
  final bool animate;
  final CrossAxisAlignment align;
  final double lineHeight;

  /// −8° yatay eğim matrisi (CSS `skewX(-8deg)`).
  static Matrix4 get skew => Matrix4.skewX(-8 * math.pi / 180);

  @override
  Widget build(BuildContext context) {
    final ink = color ?? context.palette.ink;
    final reduce = context.reduceMotion;
    return Semantics(
      header: true,
      label: lines.join(' '),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: align,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < lines.length; i++)
            _Line(
              key: ValueKey('${lines[i]}-$i'),
              text: lines[i],
              style: AppTypography.poster(size, height: lineHeight, color: i == highlightLine && highlight != null ? highlight : ink),
              delay: stagger * i,
              from: from,
              animate: animate && !reduce,
              align: align,
            ),
        ],
      ),
    );
  }
}

class _Line extends StatefulWidget {
  const _Line({super.key, required this.text, required this.style, required this.delay, required this.from, required this.animate, required this.align});

  final String text;
  final TextStyle style;
  final Duration delay;
  final Offset from;
  final bool animate;
  final CrossAxisAlignment align;

  @override
  State<_Line> createState() => _LineState();
}

class _LineState extends State<_Line> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.animate ? const Duration(milliseconds: 600) : const Duration(milliseconds: 400),
  );

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (!widget.animate || widget.delay == Duration.zero) {
      _c.forward();
    } else {
      _timer = Timer(widget.delay, _c.forward);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alignment = widget.align == CrossAxisAlignment.center ? Alignment.center : Alignment.centerLeft;
    final text = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: alignment,
      child: Transform(
        transform: PosterTitle.skew,
        alignment: Alignment.center,
        child: Text(widget.text, maxLines: 1, softWrap: false, style: widget.style),
      ),
    );
    return AnimatedBuilder(
      animation: _c,
      child: text,
      builder: (_, child) {
        final t = const Cubic(.2, .8, .2, 1).transform(_c.value);
        if (!widget.animate) return Opacity(opacity: _c.value, child: child);
        return Opacity(opacity: t.clamp(0, 1), child: Transform.translate(offset: widget.from * (1 - t), child: child));
      },
    );
  }
}
