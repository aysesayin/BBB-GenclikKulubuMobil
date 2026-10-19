import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/buan/buan_reward.dart';
import '../../widgets/buan_icons.dart';
import '../../widgets/buan_ui.dart';

/// Ödül detayı üst illüstrasyonu (300 px). Teleferik ödüllerinde dağ + kabin çizimi,
/// diğerlerinde aynı dağ zemininde ödül ikonu.
class RewardArt extends StatelessWidget {
  const RewardArt({super.key, required this.reward, this.height = 300});

  final BuanReward reward;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final cable = reward.icon == 'cable';
    final gondola = cable
        ? '<line x1="-10" y1="60" x2="410" y2="150" stroke="${p.onTile.hex}" stroke-width="2.5"/>'
              '<g transform="translate(170 82)"><line x1="22" y1="0" x2="22" y2="22" stroke="${p.onTile.hex}" stroke-width="3"/>'
              '<rect x="0" y="22" width="46" height="40" rx="10" fill="${p.hotFill.hex}" stroke="${p.onTile.hex}" stroke-width="3"/>'
              '<rect x="7" y="30" width="13" height="12" rx="3" fill="${p.paper.hex}"/>'
              '<rect x="26" y="30" width="13" height="12" rx="3" fill="${p.paper.hex}"/></g>'
        : '';
    final svg =
        '<svg viewBox="0 0 393 300"><path d="M-20 300 L120 150 L200 230 L290 120 L420 300 Z" fill="${p.secondary.hex}"/>'
        '<path d="M220 300 L290 120 L340 180 L420 300 Z" fill="${p.grnT.hex}" opacity=".5"/>'
        '<path d="M270 130 L290 120 L310 130" fill="${p.paper.hex}"/>$gondola'
        '<circle cx="70" cy="60" r="26" fill="${p.cta.hex}"/></svg>';
    return SizedBox(
      height: height,
      child: ColoredBox(
        color: buanTile(p, reward.tile),
        child: Stack(
          fit: StackFit.expand,
          children: [
            SvgArt(svg, fit: BoxFit.cover),
            if (!cable)
              Align(
                alignment: const Alignment(0, -.1),
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: p.paper,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: p.onTile, width: 3),
                    boxShadow: [BoxShadow(color: p.onTile, offset: const Offset(4, 4))],
                  ),
                  alignment: Alignment.center,
                  child: AppIcon(BuanIcons.byKey(reward.icon), size: 48, color: p.onTile, strokeWidth: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
