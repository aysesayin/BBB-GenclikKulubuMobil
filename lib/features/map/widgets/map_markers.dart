import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';

/// Pin işaretçisinin kutusu: en büyük (seçili, 52 px) damlanın köşegeni sığar.
const double kPinBox = 76;

/// Tasarımdaki damla pin: köşeleri 50%/50%/50%/8px kare, −45° döndürülmüş, 3 px beyaz çerçeve.
/// Uç (sol-alt köşe) kutunun alt ortasına denk gelir → `Marker(alignment: Alignment.topCenter)`.
class TeardropPin extends StatelessWidget {
  const TeardropPin({super.key, required this.color, required this.icon, required this.label, required this.selected, required this.onTap});

  final Color color;
  final String icon, label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = selected ? 52.0 : 42.0;
    final duration = context.reduceMotion ? Duration.zero : AppDurations.fast;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Haptics.selection();
          onTap();
        },
        child: Align(
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: duration,
            curve: Curves.easeOutBack,
            width: s * math.sqrt2,
            height: s * math.sqrt2,
            alignment: Alignment.center,
            child: Transform.rotate(
              angle: -math.pi / 4,
              child: AnimatedContainer(
                duration: duration,
                curve: Curves.easeOutBack,
                width: s,
                height: s,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: p.paper, width: 3),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(s / 2),
                    topRight: Radius.circular(s / 2),
                    bottomRight: Radius.circular(s / 2),
                    bottomLeft: const Radius.circular(8),
                  ),
                  boxShadow: [BoxShadow(color: p.shadowColor, blurRadius: 14, offset: const Offset(0, 6))],
                ),
                alignment: Alignment.center,
                child: Transform.rotate(angle: math.pi / 4, child: AppIcon(icon, size: 18, color: p.paper, strokeWidth: 2.4)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Küme balonu: 50 px daire, koyu dolgu, "+N".
class ClusterBubble extends StatelessWidget {
  const ClusterBubble({super.key, required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return Semantics(
      button: true,
      label: l.mapClusterSemantics(count),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          Haptics.selection();
          onTap();
        },
        child: Container(
          width: 50,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: p.onTile,
            shape: BoxShape.circle,
            border: Border.all(color: p.paper, width: 3),
            boxShadow: [BoxShadow(color: p.shadowColor, blurRadius: 14, offset: const Offset(0, 6))],
          ),
          child: Text(l.mapClusterLabel(count), style: AppTypography.body(14, weight: FontWeight.w900, color: p.paper)),
        ),
      ),
    );
  }
}

/// Kullanıcı konumu: 22 px dolgu + 4 px beyaz çerçeve + 10 px yumuşak halka.
class UserLocationDot extends StatelessWidget {
  const UserLocationDot({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: context.l10n.mapMyLocation,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: p.primary,
          shape: BoxShape.circle,
          border: Border.all(color: p.paper, width: 4),
          boxShadow: [BoxShadow(color: p.tealS, spreadRadius: 10)],
        ),
      ),
    );
  }
}
