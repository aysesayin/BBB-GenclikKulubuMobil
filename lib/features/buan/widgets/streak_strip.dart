import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/buan/buan_wallet.dart';
import '../../../l10n/l10n.dart';

/// Hero içindeki kompakt 7 günlük seri: ateş + "Seri N gün" + tek satır küçük nokta.
/// Tamamlanan gün sarı dolu, bugün açık çerçeveli, bekleyen gün yarı saydam.
class StreakDots extends StatelessWidget {
  const StreakDots({super.key, required this.streak, this.dot = 10});

  final BuanStreak streak;
  final double dot;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final soft = p.onBuan.withValues(alpha: .9);
    return Semantics(
      label: l.buanStreakTitle(streak.days),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(AppIcons.flame, size: 16, color: p.cta, fill: p.cta, strokeWidth: 1.5),
          const SizedBox(width: 4),
          Text(
            l.buanStreakCompact(streak.days),
            maxLines: 1,
            softWrap: false,
            style: AppTypography.body(12, weight: FontWeight.w900, color: soft),
          ),
          if (streak.week.isNotEmpty) ...[
            const SizedBox(width: 8),
            for (final d in streak.week.take(7))
              Padding(
                padding: const EdgeInsets.only(left: 3),
                child: Container(
                  width: dot,
                  height: dot,
                  decoration: BoxDecoration(
                    color: d.done ? p.cta : p.paper.withValues(alpha: .25),
                    shape: BoxShape.circle,
                    border: d.today ? Border.all(color: p.paper, width: 2) : null,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
