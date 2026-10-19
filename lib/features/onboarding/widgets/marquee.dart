import 'package:flutter/material.dart';

import '../../../core/utils/haptics.dart';

/// Sonsuz yatay kayan şerit (CSS `translateX(0 → −50%)`): çocuklar iki kez
/// dizilir, bir kopyanın genişliği kadar kaydırılır. Hareketi azalt → durur.
class Marquee extends StatefulWidget {
  const Marquee({
    super.key,
    required this.children,
    required this.duration,
    required this.height,
    this.reverse = false,
    this.gap = 12,
    this.leading = 0,
    this.paused = false,
  });

  final List<Widget> children;
  final Duration duration;

  /// Şerit yüksekliği (gölge/eğim taşmaları dahil).
  final double height;

  /// true → soldan sağa akar.
  final bool reverse;
  final double gap, leading;
  final bool paused;

  @override
  State<Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<Marquee> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  final _rowKey = GlobalKey();
  double _half = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(Marquee old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    if (context.reduceMotion || widget.paused) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  void _measure() {
    final box = _rowKey.currentContext?.findRenderObject() as RenderBox?;
    final w = box == null || !box.hasSize ? 0.0 : box.size.width / 2;
    if (w != _half && mounted) setState(() => _half = w);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final items = [...widget.children, ...widget.children];
    final row = Row(
      key: _rowKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++) Padding(padding: EdgeInsets.only(right: widget.gap), child: items[i]),
      ],
    );
    return SizedBox(
      height: widget.height,
      child: OverflowBox(
        alignment: Alignment.centerLeft,
        minWidth: 0,
        maxWidth: double.infinity,
        child: AnimatedBuilder(
          animation: _c,
          child: Padding(padding: EdgeInsets.only(left: widget.leading), child: row),
          builder: (_, child) {
            final p = widget.reverse ? 1 - _c.value : _c.value;
            return Transform.translate(offset: Offset(-p * _half, 0), child: child);
          },
        ),
      ),
    );
  }
}
