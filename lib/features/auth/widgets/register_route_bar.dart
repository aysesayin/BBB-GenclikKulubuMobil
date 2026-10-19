import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../onboarding/widgets/motion.dart';
import '../../onboarding/widgets/onb_icons.dart';

/// Kayıt rotası: 5 durak (Tophane → Zirve), dolan çizgi ve zıplayan maskot.
class RegisterRouteBar extends StatelessWidget {
  const RegisterRouteBar({super.key, required this.index});

  final int index;

  static List<String> stopNames(BuildContext context) {
    final l = context.l10n;
    return [l.authStopTophane, l.authStopUluCami, l.authStopKozahan, l.authStopTeleferik, l.authStopZirve];
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final names = stopNames(context);
    final pct = index / (names.length - 1);
    final mascot = '<svg viewBox="0 0 120 120"><path d="M30 14 Q18 8 18 22 V98 Q18 112 30 106 L104 68 Q114 60 104 52 Z" fill="${p.coinMark.hex}"/>'
        '<ellipse cx="44" cy="54" rx="7" ry="9" fill="${p.onTile.hex}"/><ellipse cx="64" cy="56" rx="7" ry="9" fill="${p.onTile.hex}"/></svg>';
    return Semantics(
      label: context.l10n.authRegRoute,
      value: context.l10n.authRegStop(index + 1, names.length, names[index]),
      excludeSemantics: true,
      child: SizedBox(
        height: 64,
        child: LayoutBuilder(
          builder: (_, c) {
            final w = c.maxWidth;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(left: 10, right: 10, top: 40, height: 4, child: _line(p.line)),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  curve: onbCurve,
                  left: 10,
                  top: 40,
                  height: 4,
                  width: (w - 20) * pct,
                  child: _line(p.primary),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 30,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [for (var i = 0; i < names.length; i++) _Stop(name: names[i], icon: OnbIcons.stops[i], state: i.compareTo(index))],
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 500),
                  curve: onbCurve,
                  top: -2,
                  left: (w - 24) * pct - 3,
                  child: LoopMotion(
                    key: ValueKey(index),
                    duration: const Duration(milliseconds: 600),
                    builder: (_, t, child) {
                      final e = Curves.easeInOut.transform(t);
                      return Transform.translate(offset: Offset(0, -12 * e), child: Transform.rotate(angle: -.1 * e, child: child));
                    },
                    child: SvgArt(mascot, width: 30, height: 30),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _line(Color c) => DecoratedBox(decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2)));
}

class _Stop extends StatelessWidget {
  const _Stop({required this.name, required this.icon, required this.state});

  final String name, icon;

  /// −1 geçildi, 0 şu an, 1 ileride.
  final int state;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (bg, fg, border) = switch (state) {
      < 0 => (p.primary, p.onTile, p.primary),
      0 => (p.cta, p.onCta, p.cta),
      _ => (p.sf, p.mut, p.line),
    };
    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: AppDurations.fast,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle, border: Border.all(color: border, width: 3)),
            alignment: Alignment.center,
            child: AppIcon(icon, size: 12, color: fg, strokeWidth: 3),
          ),
          Positioned(
            top: 26,
            child: Text(
              name,
              maxLines: 1,
              softWrap: false,
              style: AppTypography.body(10, weight: FontWeight.w900, color: state == 0 ? p.ink : p.mut),
            ),
          ),
        ],
      ),
    );
  }
}
