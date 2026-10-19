import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../theme/app_palette.dart';
import '../utils/haptics.dart';
import 'app_icon.dart';

/// Maskot "Buancık" — BU'AN üçgeninden türetilmiş özgün karakter (ad panelden gelir).
enum MascotMood { happy, celebrate, surprised, sleepy }

/// Maskot animasyonu: süzülme (boş), sallanma (hata), yok.
enum MascotMotion { none, float, wobble }

class Mascot extends StatefulWidget {
  const Mascot({super.key, this.mood = MascotMood.happy, this.size = 120, this.motion = MascotMotion.none, this.semanticLabel});

  final MascotMood mood;
  final double size;
  final MascotMotion motion;

  /// null → dekoratif.
  final String? semanticLabel;

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.motion == MascotMotion.wobble ? 2400 : 2600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.motion != MascotMotion.none && !context.reduceMotion) {
      _c.repeat(reverse: true);
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  String _svg(AppPalette p) {
    final ink = p.onTile.hex, white = p.paper.hex, body = p.coinMark.hex, hot = p.hotFill.hex, z = p.buanFill.hex;
    const shape = 'M30 14 Q18 8 18 22 V98 Q18 112 30 106 L104 68 Q114 60 104 52 Z';
    final face = switch (widget.mood) {
      MascotMood.happy => '<path d="M30 14 Q18 8 18 22 V40 Q40 28 70 38 Z" fill="$white" fill-opacity=".25"/>'
          '<ellipse cx="44" cy="54" rx="6" ry="8" fill="$ink"/><ellipse cx="62" cy="56" rx="6" ry="8" fill="$ink"/>'
          '<circle cx="46" cy="51" r="2" fill="$white"/><circle cx="64" cy="53" r="2" fill="$white"/>'
          '<circle cx="36" cy="68" r="5" fill="$hot" fill-opacity=".6"/><circle cx="72" cy="70" r="5" fill="$hot" fill-opacity=".6"/>'
          '<path d="M44 70 Q53 80 62 71" stroke="$ink" stroke-width="4" fill="none" stroke-linecap="round"/>',
      MascotMood.celebrate => '<path d="M38 52 Q44 44 50 52M56 54 Q62 46 68 54" stroke="$ink" stroke-width="4" fill="none" stroke-linecap="round"/>'
          '<path d="M40 66 Q53 84 66 67 Z" fill="$ink"/>',
      MascotMood.surprised => '<circle cx="44" cy="54" r="8" fill="$white"/><circle cx="64" cy="56" r="8" fill="$white"/>'
          '<circle cx="45" cy="55" r="4" fill="$ink"/><circle cx="65" cy="57" r="4" fill="$ink"/>'
          '<ellipse cx="54" cy="74" rx="5" ry="6" fill="$ink"/>'
          '<path d="M84 30 l10 -10 M92 36 l14 -4" stroke="$hot" stroke-width="4" stroke-linecap="round"/>',
      MascotMood.sleepy => '<path d="M38 56 Q44 60 50 56M56 58 Q62 62 68 58" stroke="$ink" stroke-width="4" fill="none" stroke-linecap="round"/>'
          '<path d="M48 72 H60" stroke="$ink" stroke-width="4" stroke-linecap="round"/>'
          '<path d="M78 24h10l-10 12h10" stroke="$z" stroke-width="3.2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
          '<path d="M92 14h7l-7 8h7" stroke="$z" stroke-width="2.6" fill="none" stroke-linecap="round" stroke-linejoin="round"/>',
    };
    return '<svg viewBox="0 0 120 120"><path d="$shape" fill="$body"/>$face</svg>';
  }

  @override
  Widget build(BuildContext context) {
    final art = SvgArt(_svg(context.palette), width: widget.size, height: widget.size);
    final animated = widget.motion == MascotMotion.none
        ? art
        : AnimatedBuilder(
            animation: _c,
            child: art,
            builder: (_, child) {
              final t = Curves.easeInOut.transform(_c.value);
              return widget.motion == MascotMotion.float
                  ? Transform.translate(offset: Offset(0, -8 * t), child: child)
                  : Transform.rotate(angle: (t * 2 - 1) * 0.07, child: child);
            },
          );
    if (widget.semanticLabel == null) return animated;
    return Semantics(label: widget.semanticLabel ?? context.l10n.mascotName, image: true, child: animated);
  }
}
