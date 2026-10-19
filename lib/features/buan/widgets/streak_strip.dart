import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/buan/buan_wallet.dart';
import '../../../l10n/l10n.dart';

/// 7 günlük seri şeridi: tamamlanan günler sarı + ateş, bugün ink çerçeveli.
class StreakStrip extends StatelessWidget {
  const StreakStrip({super.key, required this.streak});

  final BuanStreak streak;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final locale = Localizations.localeOf(context).languageCode;
    return Semantics(
      container: true,
      label: l.buanStreakLabel,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AppIcon(AppIcons.flame, size: 22, color: p.ctaShadow, fill: p.cta, strokeWidth: 1.5),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l.buanStreakTitle(streak.days),
                    style: AppTypography.body(15, weight: FontWeight.w900, color: p.ink),
                  ),
                ),
                if (streak.bonusDay != null && streak.bonusAmount != null)
                  Text(
                    l.buanStreakBonus(streak.bonusDay!, Fmt.number(streak.bonusAmount!)),
                    style: AppTypography.body(12, weight: FontWeight.w800, color: p.mut),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (final d in streak.week)
                  Expanded(
                    child: _Day(day: d, label: Fmt.weekdayShort(d.date, locale)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({required this.day, required this.label});

  final BuanStreakDay day;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final fg = day.done ? p.onTile : p.mut;
    return Semantics(
      label: day.done ? l.buanStreakDayDone(label) : l.buanStreakDayPending(label),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: day.done ? p.cta : p.sf2,
                shape: BoxShape.circle,
                border: day.today ? Border.all(color: p.ink, width: 3) : null,
              ),
              alignment: Alignment.center,
              child: AppIcon(AppIcons.flame, size: 16, color: fg, fill: day.done ? p.tile6 : null, strokeWidth: 2),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              style: AppTypography.body(11, weight: FontWeight.w900, color: day.today ? p.ink : p.mut),
            ),
          ],
        ),
      ),
    );
  }
}
