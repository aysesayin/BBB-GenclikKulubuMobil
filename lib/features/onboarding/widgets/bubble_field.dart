import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/utils/haptics.dart';
import '../../../data/models/auth/interest_option.dart';
import 'interest_bubble.dart';

/// Hafif "fizik": baloncuklar yerçekimsiz, evlerinin çevresinde süzülür,
/// birbirine çarpınca itişir; seçilen büyüyünce komşularını iter.
/// (forge2d kurulu değil — yay + çarpışma çözümüyle yaklaşık.)
class BubbleField extends StatefulWidget {
  const BubbleField({super.key, required this.options, required this.selected, required this.last, required this.onToggle});

  final List<InterestOption> options;
  final Set<String> selected;
  final String? last;
  final ValueChanged<String> onToggle;

  @override
  State<BubbleField> createState() => _BubbleFieldState();
}

class _Body {
  _Body(this.home, this.size, this.phase) : pos = home;
  Offset home, pos, vel = Offset.zero;
  double size;
  final double phase;
}

class _BubbleFieldState extends State<BubbleField> with SingleTickerProviderStateMixin {
  /// Tasarımdaki yerleşim (393 × 560 kare): (çap, sol, üst).
  static const _slots = [
    (130.0, 16.0, 26.0), (112.0, 172.0, 10.0), (114.0, 272.0, 130.0), (140.0, 14.0, 176.0), (100.0, 168.0, 140.0),
    (118.0, 158.0, 276.0), (104.0, 284.0, 266.0), (96.0, 20.0, 340.0), (110.0, 268.0, 390.0), (124.0, 116.0, 420.0),
  ];
  static const _frame = Size(393, 560);

  late final Ticker _ticker = createTicker(_tick);
  final _bodies = <String, _Body>{};
  Size _area = Size.zero;
  Duration _lastTick = Duration.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      if (_ticker.isActive) _ticker.stop();
    } else if (!_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _layout(Size area) {
    if (area == _area && _bodies.length == widget.options.length) return;
    _area = area;
    final sx = area.width / _frame.width, sy = area.height / _frame.height;
    final k = math.min(sx, sy).clamp(.6, 1.2);
    _bodies.clear();
    for (var i = 0; i < widget.options.length; i++) {
      final slot = i < _slots.length
          ? _slots[i]
          : (100.0, 30.0 + (i * 97) % (_frame.width - 140), 40.0 + (i * 131) % (_frame.height - 140));
      final d = slot.$1 * k;
      final home = Offset((slot.$2 + slot.$1 / 2) * sx, (slot.$3 + slot.$1 / 2) * sy);
      _bodies[widget.options[i].id] = _Body(home, d, i * .37);
    }
    for (var n = 0; n < 60; n++) {
      _collide();
    }
  }

  double _radius(String id, _Body b) => b.size / 2 * (widget.selected.contains(id) ? 1.12 : 1);

  void _collide() {
    final entries = _bodies.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      for (var j = i + 1; j < entries.length; j++) {
        final a = entries[i].value, b = entries[j].value;
        final d = b.pos - a.pos;
        final dist = math.max(d.distance, .01);
        final min = _radius(entries[i].key, a) + _radius(entries[j].key, b) + 4;
        if (dist < min) {
          final n = d / dist;
          final push = n * ((min - dist) / 2);
          a.pos -= push;
          b.pos += push;
          final rel = (b.vel - a.vel).dx * n.dx + (b.vel - a.vel).dy * n.dy;
          if (rel < 0) {
            a.vel += n * rel * .5;
            b.vel -= n * rel * .5;
          }
        }
      }
    }
    for (final e in entries) {
      final r = _radius(e.key, e.value);
      final p = e.value.pos;
      e.value.pos = Offset(p.dx.clamp(r, math.max(r, _area.width - r)), p.dy.clamp(r, math.max(r, _area.height - r)));
    }
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _lastTick).inMicroseconds / 1e6).clamp(0.0, 1 / 30);
    _lastTick = elapsed;
    if (_bodies.isEmpty || dt == 0) return;
    final t = elapsed.inMicroseconds / 1e6;
    for (final b in _bodies.values) {
      // ilFloat: ±6 px yatay, ±8 px dikey, 5–8 sn.
      final w = 2 * math.pi / (5 + (b.phase * 10) % 4);
      final target = b.home + Offset(math.sin(t * w + b.phase * 7) * 6, -math.cos(t * w * .8 + b.phase * 5) * 8);
      final acc = (target - b.pos) * 6 - b.vel * 3.2;
      b.vel += acc * dt;
      b.pos += b.vel * dt;
    }
    _collide();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (_, c) {
          _layout(Size(c.maxWidth, c.maxHeight));
          if (!_ticker.isActive) {
            // Hareketi azalt: statik yerleşim, yalnız seçim büyümesi çözülür.
            for (var n = 0; n < 30; n++) {
              _collide();
            }
          }
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (final o in widget.options)
                if (_bodies[o.id] case final b?)
                  Positioned(
                    left: b.pos.dx - b.size / 2,
                    top: b.pos.dy - b.size / 2,
                    width: b.size,
                    height: b.size,
                    child: InterestBubble(
                      option: o,
                      selected: widget.selected.contains(o.id),
                      wobble: widget.last == o.id,
                      onTap: () => widget.onToggle(o.id),
                    ),
                  ),
            ],
          );
        },
      );
}
