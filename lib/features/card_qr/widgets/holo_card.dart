import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';

/// Holografik dijital kart: mor gradyan, blob'lar, BU'AN üçgeni ve cihaz
/// eğimine göre kayan parlama (sensors_plus). Sensör yoksa ya da "hareketi azalt"
/// açıksa tasarımdaki sabit eğimle (4°) çizilir.
class HoloCard extends StatefulWidget {
  const HoloCard({
    super.key,
    required this.name,
    required this.memberNo,
    required this.levelLabel,
    required this.semanticLabel,
    this.live = true,
  });

  final String name, memberNo, levelLabel, semanticLabel;

  /// false → sensör dinlenmez (sekme gizli, misafir önizlemesi).
  final bool live;

  @override
  State<HoloCard> createState() => _HoloCardState();
}

class _HoloCardState extends State<HoloCard> {
  static const _static = 4.0;
  StreamSubscription<AccelerometerEvent>? _sub;
  double _ex = _static, _ey = 0;
  double? _baseY;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(HoloCard old) {
    super.didUpdateWidget(old);
    if (old.live != widget.live) _sync();
  }

  void _sync() {
    final want = widget.live && !context.reduceMotion;
    if (want && _sub == null) {
      try {
        _sub = accelerometerEventStream(
          samplingPeriod: const Duration(milliseconds: 50),
        ).listen(_onEvent, onError: (Object _) => _stop(), cancelOnError: true);
      } on Object {
        _stop();
      }
    } else if (!want) {
      _stop();
    }
  }

  void _stop() {
    _sub?.cancel();
    _sub = null;
    if (mounted && (_ex != _static || _ey != 0)) {
      setState(() {
        _ex = _static;
        _ey = 0;
      });
    }
  }

  void _onEvent(AccelerometerEvent e) {
    _baseY ??= e.y;
    final tx = (-e.x * 2).clamp(-12.0, 12.0);
    final ty = ((e.y - _baseY!) * 2).clamp(-12.0, 12.0);
    final nx = _ex + (tx - _ex) * .2, ny = _ey + (ty - _ey) * .2;
    if ((nx - _ex).abs() < .05 && (ny - _ey).abs() < .05) return;
    if (mounted) {
      setState(() {
        _ex = nx;
        _ey = ny;
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    const deg = math.pi / 180;
    final rotX = (_ex * .4 + _ey * .4) * deg;
    final rotY = -_ex * deg;
    final sheen = (110 + _ex * 4) * deg;
    final dir = Alignment(math.sin(sheen), -math.cos(sheen));
    final white = p.paper;
    return Semantics(
      label: widget.semanticLabel,
      image: true,
      excludeSemantics: true,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 1 / 900)
          ..rotateX(rotX)
          ..rotateY(rotY),
        child: AspectRatio(
          aspectRatio: 1 / .595,
          child: Container(
            decoration: BoxDecoration(
              gradient: p.buanGradient,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [BoxShadow(color: p.buanShadow.withValues(alpha: .4), blurRadius: 36, offset: const Offset(0, 18))],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                SvgArt(
                  '<svg viewBox="0 0 353 210" preserveAspectRatio="xMidYMid slice">'
                  '<path d="M250 -40c90 0 140 60 120 140s-90 100-160 80-80-90-50-150 0-70 90-70z" fill="${p.coinMark.hex}" fill-opacity=".45"/>'
                  '<path d="M-40 150c50-40 130-30 150 20s-40 90-100 80-100-60-50-100z" fill="${p.secondary.hex}" fill-opacity=".4"/>'
                  '<path d="M262 120 L310 148 L262 176 Z" fill="${p.coinMark.hex}" stroke="${p.coinMark.hex}" stroke-width="6" '
                  'stroke-linejoin="round" fill-opacity=".9" stroke-opacity=".9"/></svg>',
                  fit: BoxFit.cover,
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: -dir,
                      end: dir,
                      colors: [
                        white.withValues(alpha: 0),
                        white.withValues(alpha: .28),
                        white.withValues(alpha: .12),
                        white.withValues(alpha: .2),
                        white.withValues(alpha: 0),
                      ],
                      stops: const [.3, .45, .52, .58, .72],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l.brandCity, style: AppTypography.script(20, color: p.secondary)),
                                Text(
                                  l.brandClub,
                                  style: AppTypography.display(18, height: .95, color: p.onBuan).copyWith(letterSpacing: .6),
                                ),
                              ],
                            ),
                          ),
                          Transform.rotate(
                            angle: 4 * deg,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: p.cta,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: p.onTile, width: 2),
                              ),
                              child: Text(
                                widget.levelLabel,
                                style: AppTypography.body(12, weight: FontWeight.w900, color: p.onCta),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(widget.name, maxLines: 1, style: AppTypography.display(26, height: 1, color: p.onBuan)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.cardMemberNo(widget.memberNo),
                            style: AppTypography.number(
                              13,
                              weight: FontWeight.w800,
                              color: p.onBuan.withValues(alpha: .9),
                            ).copyWith(letterSpacing: 1.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
