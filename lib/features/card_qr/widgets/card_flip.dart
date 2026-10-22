import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../opportunities/widgets/ticket_parts.dart';

/// Dokununca Y ekseninde 3B dönen kart: ön yüz [front], arka yüz [back].
/// "Hareketi azalt" / Kolay Mod'da animasyonsuz anlık geçiş.
class FlipCard extends StatefulWidget {
  const FlipCard({super.key, required this.front, required this.back, required this.flipped, required this.onTap});

  final Widget front, back;
  final bool flipped;
  final VoidCallback onTap;

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
    value: widget.flipped ? 1 : 0,
  );

  @override
  void didUpdateWidget(FlipCard old) {
    super.didUpdateWidget(old);
    if (old.flipped == widget.flipped) return;
    final target = widget.flipped ? 1.0 : 0.0;
    if (context.reduceMotion) {
      _c.value = target;
    } else {
      _c.animateTo(target, curve: Curves.easeInOutCubic);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Semantics(
      button: true,
      label: l.cardFlipSemantics(widget.flipped ? l.cardFlipBack : l.cardFlipFront),
      hint: l.cardFlipHint,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Haptics.selection();
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final angle = _c.value * math.pi;
            final showBack = angle > math.pi / 2;
            // Arka yüz ayna görüntüsü olmasın diye π kadar geri çevrilir.
            final transform = Matrix4.identity()
              ..setEntry(3, 2, 1 / 800)
              ..rotateY(showBack ? angle - math.pi : angle);
            return Transform(
              alignment: Alignment.center,
              transform: transform,
              child: showBack ? ExcludeSemantics(child: widget.back) : ExcludeSemantics(child: widget.front),
            );
          },
        ),
      ),
    );
  }
}

/// Kartın arka yüzü: büyük QR + 4 haneli kod (aynı en-boy oranı).
class CardBackFace extends StatelessWidget {
  const CardBackFace({super.key, required this.token, required this.pin, required this.secondsLeft, required this.ring});

  final String? token, pin;
  final int secondsLeft;
  final double ring;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return AspectRatio(
      aspectRatio: 1 / .595,
      child: Container(
        decoration: BoxDecoration(
          color: p.onTile,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [BoxShadow(color: p.buanShadow.withValues(alpha: .4), blurRadius: 36, offset: const Offset(0, 18))],
        ),
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, c) {
            final qr = (c.maxHeight - 32).clamp(96.0, 180.0);
            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(16)),
                  child: SizedBox.square(
                    dimension: qr,
                    child: token != null
                        ? QrImageView(
                            data: token!,
                            size: qr,
                            padding: EdgeInsets.zero,
                            backgroundColor: p.paper,
                            eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: p.onTile),
                            dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: p.onTile),
                          )
                        : Center(child: AppIcon(AppIcons.qr, size: 48, color: p.line, strokeWidth: 1.8)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.cardBackTitle, style: AppTypography.body(12, weight: FontWeight.w900, color: p.paper.withValues(alpha: .8))),
                      const SizedBox(height: 8),
                      if (pin case final code?)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: PinBoxes(parts: code.split(''), minWidth: 36, height: 48, fontSize: 28, radius: 12),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ProgressRing(value: ring, color: p.cta, size: 22, stroke: 3, track: p.paper.withValues(alpha: .25)),
                          const SizedBox(width: 6),
                          Text(l.cardTurnstileSeconds(secondsLeft), style: AppTypography.number(12, color: p.paper)),
                        ],
                      ),
                    ],
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
