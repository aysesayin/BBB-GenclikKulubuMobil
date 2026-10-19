import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import 'onb_icons.dart';

/// A2 · 1. hikâye: mini harita kartı, pinler 320 ms arayla "patlar".
class StoryCityScene extends StatelessWidget {
  const StoryCityScene({super.key, required this.bonusPin});

  /// Mor pindeki örnek BUAN tutarı (dekoratif).
  final int bonusPin;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final pins = [
      (40.0, 60.0, l.onbPinConcert, p.primary, p.onTile, AppIcons.music),
      (200.0, 40.0, l.onbPinDiscount, p.hotFill, p.onHot, OnbIcons.pinTag),
      (130.0, 150.0, l.onbPinYouthCenter, p.secondary, p.onTile, OnbIcons.pinBuilding),
      (260.0, 190.0, l.onbPinCamp, p.cta, p.onCta, OnbIcons.pinCamp),
      (30.0, 220.0, l.buanAmount(Fmt.signed(bonusPin)), p.buanFill, p.onBuan, OnbIcons.coinTriangle),
    ];
    final svg = '<svg viewBox="0 0 353 330" preserveAspectRatio="none">'
        '<path d="M-10 230 C80 200 140 250 220 215 S320 170 370 190" stroke="${p.mapWater.hex}" stroke-width="16" fill="none"/>'
        '<path d="M-10 120 L370 160M90 -10 L130 340M260 -10 L235 340" stroke="${p.mapRoad.hex}" stroke-width="10"/>'
        '<path d="M250 -10 C300 60 340 70 370 60 L370 -10Z" fill="${p.mapPark.hex}"/>'
        '<path d="M10 330 L80 260 L120 300 L170 250 L230 330Z" fill="${p.mapPark.hex}"/></svg>';
    return ExcludeSemantics(
      child: Container(
        height: 330,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: p.mapLand, borderRadius: BorderRadius.circular(34), boxShadow: p.cardShadow),
        child: LayoutBuilder(
          builder: (_, c) {
            final sx = c.maxWidth / 353;
            return Stack(
              children: [
                Positioned.fill(child: SvgArt(svg, fit: BoxFit.fill)),
                for (var k = 0; k < pins.length; k++)
                  Positioned(
                    left: pins[k].$1 * sx,
                    top: pins[k].$2,
                    child: _Pin(
                      label: pins[k].$3,
                      color: pins[k].$4,
                      on: pins[k].$5,
                      icon: pins[k].$6,
                      delay: Duration(milliseconds: 350 + k * 320),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Pin extends StatefulWidget {
  const _Pin({required this.label, required this.color, required this.on, required this.icon, required this.delay});

  final String label, icon;
  final Color color, on;
  final Duration delay;

  @override
  State<_Pin> createState() => _PinState();
}

class _PinState extends State<_Pin> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.value > 0 || _c.isAnimating) return;
    if (context.reduceMotion) {
      _c.value = 1;
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
    final p = context.palette;
    final pin = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: -math.pi / 4,
          child: Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.color,
              border: Border.all(color: p.paper, width: 3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(23),
                topRight: Radius.circular(23),
                bottomRight: Radius.circular(23),
                bottomLeft: Radius.circular(6),
              ),
              boxShadow: [BoxShadow(color: p.shadowColor, blurRadius: 16, offset: const Offset(0, 8))],
            ),
            child: Transform.rotate(angle: math.pi / 4, child: AppIcon(widget.icon, size: 20, color: widget.on, strokeWidth: 2.6)),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(10)),
          child: Text(widget.label, maxLines: 1, style: AppTypography.body(11, weight: FontWeight.w900, color: p.onChip)),
        ),
      ],
    );
    return AnimatedBuilder(
      animation: _c,
      child: pin,
      builder: (_, child) {
        // hkPop: scale 0 → 1.18 → 1, translateY 20 → 0.
        final v = _c.value;
        final s = v < .6 ? 1.18 * Curves.easeOut.transform(v / .6) : 1.18 - .18 * ((v - .6) / .4);
        return Opacity(
          opacity: (v / .6).clamp(0, 1),
          child: Transform.translate(offset: Offset(0, 20 * (1 - (v / .6).clamp(0, 1))), child: Transform.scale(scale: s, child: child)),
        );
      },
    );
  }
}
