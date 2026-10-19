import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import 'motion.dart';

/// Sonsuz BUAN coin yağmuru (16 jeton, 1,6–3 sn, Y ekseninde döner).
/// Hareketi azalt → çizilmez.
class CoinRain extends StatefulWidget {
  const CoinRain({super.key});

  @override
  State<CoinRain> createState() => _CoinRainState();
}

class _CoinRainState extends State<CoinRain> with SingleTickerProviderStateMixin {
  Ticker? _ticker;
  double _t = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!context.reduceMotion && _ticker == null) {
      _ticker = createTicker((e) => setState(() => _t = e.inMicroseconds / 1e6))..start();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (context.reduceMotion) return const SizedBox.shrink();
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (_, c) {
          final sx = c.maxWidth / 393;
          return Stack(children: [for (var i = 0; i < 16; i++) _coin(i, sx, c.maxHeight)]);
        },
      ),
    );
  }

  Widget _coin(int i, double sx, double h) {
    final dur = 1.6 + (i % 5) * .35;
    final delay = (i * .19) % 1.5;
    final local = _t - delay;
    if (local < 0) return const SizedBox.shrink();
    final f = (local % dur) / dur;
    final size = 18.0 + (i % 4) * 8;
    return Positioned(
      left: ((i * 47) % 370) * sx,
      top: -80 + (h + 80) * f,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(f * 4 * math.pi),
        child: BuanCoin(size: size, ring: true),
      ),
    );
  }
}

/// Haptik eşikleri: zaman çizelgesinde geçilince bir kez titreşir.
class HapticCues {
  HapticCues(this.cues);

  final List<(double, Future<void> Function())> cues;
  double _last = -1;

  void at(double seconds) {
    for (final (s, f) in cues) {
      if (_last < s && seconds >= s) f();
    }
    _last = seconds;
  }

  void reset() => _last = -1;

  static HapticCues summit() => HapticCues([(1.5, Haptics.heavy), (3.1, Haptics.medium), (3.6, Haptics.medium), (4.1, Haptics.medium)]);
}

/// Kart zaman çizelgesi (sn → değer) yardımcıları, cubic-bezier(.2,.8,.2,1).
double summitSeg(double seconds, double a, double b, [Curve curve = onbCurve]) =>
    curve.transform(((seconds - a) / (b - a)).clamp(0.0, 1.0));
