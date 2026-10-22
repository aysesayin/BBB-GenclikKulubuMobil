import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/buan/buan_wallet.dart';
import '../../../l10n/l10n.dart';

/// Hero'nun açık hâlindeki parçalar: üst satır, bakiye, seviye pill'i.
class HeroTopRow extends StatelessWidget {
  const HeroTopRow({super.key, required this.onHistory});

  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(9)),
            alignment: Alignment.center,
            child: SvgArt(
              '<svg viewBox="0 0 24 24"><path d="M7 4.5l13 7.5-13 7.5z" fill="${p.coinMark.hex}" stroke="${p.coinMark.hex}" '
              'stroke-width="2" stroke-linejoin="round"/></svg>',
              width: 18,
              height: 18,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(l.buanHomeTitle, maxLines: 1, style: AppTypography.display(20, color: p.onBuan)),
            ),
          ),
          Semantics(
            button: true,
            label: l.buanHomeHistorySemantics,
            excludeSemantics: true,
            child: Material(
              color: p.paper.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                onTap: onHistory,
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  child: Text(l.buanHomeHistory, style: AppTypography.body(13, weight: FontWeight.w900, color: p.paper)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HeroBalance extends StatelessWidget {
  const HeroBalance({super.key, required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      liveRegion: true,
      label: context.l10n.buanBalanceSemantics(Fmt.number(balance)),
      excludeSemantics: true,
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            const BuanCoin(size: 36, ring: true),
            const SizedBox(width: 10),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: CountUpText(value: balance, style: AppTypography.number(40, height: 1.05, color: p.onBuan)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeroLevelPill extends StatelessWidget {
  const HeroLevelPill({super.key, required this.level});

  final BuanLevel level;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: p.cta, borderRadius: BorderRadius.circular(12)),
      alignment: Alignment.center,
      child: Text(
        context.l10n.buanLevelChip(level.level, level.name),
        maxLines: 1,
        softWrap: false,
        style: AppTypography.body(12, weight: FontWeight.w900, color: p.onCta),
      ),
    );
  }
}
