import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/buan/buan_wallet.dart';
import '../../../l10n/l10n.dart';

/// E1 üst cüzdan: mor gradyan, BU'AN logosu, "Geçmiş", count-up bakiye, seviye kartı.
class BuanHero extends StatelessWidget {
  const BuanHero({super.key, required this.balance, required this.level, required this.onHistory});

  final int balance;
  final BuanLevel level;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return Semantics(
      container: true,
      label: l.buanHomeWalletLabel,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        child: DecoratedBox(
          decoration: BoxDecoration(gradient: p.buanGradient),
          child: Stack(
            children: [
              Positioned(
                right: -70,
                top: -50,
                child: SvgArt(
                  '<svg viewBox="0 0 260 240"><path d="M140 10c70 0 115 50 110 115s-55 105-120 105S10 180 18 115 70 10 140 10z" '
                  'fill="${p.coinMark.hex}" opacity=".3"/></svg>',
                  width: 260,
                  height: 240,
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 8, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopRow(onHistory: onHistory),
                    const SizedBox(height: 14),
                    Text(
                      l.buanSlogan,
                      style: AppTypography.body(13, weight: FontWeight.w800, color: p.onBuan.withValues(alpha: .9)),
                    ),
                    _Balance(balance: balance),
                    const SizedBox(height: 12),
                    _LevelCard(level: level),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({required this.onHistory});

  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: SvgArt(
            '<svg viewBox="0 0 24 24"><path d="M7 4.5l13 7.5-13 7.5z" fill="${p.coinMark.hex}" stroke="${p.coinMark.hex}" '
            'stroke-width="2" stroke-linejoin="round"/></svg>',
            width: 20,
            height: 20,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(l.buanHomeTitle, style: AppTypography.display(22, color: p.onBuan)),
          ),
        ),
        Semantics(
          button: true,
          label: l.buanHomeHistorySemantics,
          excludeSemantics: true,
          child: Material(
            color: p.paper.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onHistory,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                child: Text(
                  l.buanHomeHistory,
                  style: AppTypography.body(13, weight: FontWeight.w900, color: p.paper),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Balance extends StatelessWidget {
  const _Balance({required this.balance});

  final int balance;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      liveRegion: true,
      label: context.l10n.buanBalanceSemantics(Fmt.number(balance)),
      excludeSemantics: true,
      child: Row(
        children: [
          SvgArt(
            '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="11" fill="${p.paper.hex}"/>'
            '<circle cx="12" cy="12" r="9" fill="${p.buanFill.hex}"/><path d="M9.8 8l6.4 4-6.4 4z" fill="${p.glow.hex}"/></svg>',
            width: 44,
            height: 44,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: CountUpText(
                value: balance,
                style: AppTypography.number(52, height: 1.05, color: p.onBuan),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.level});

  final BuanLevel level;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final soft = p.onBuan.withValues(alpha: .9);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: p.paper.withValues(alpha: .12), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(color: p.cta, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  l.buanLevelChip(level.level, level.name),
                  style: AppTypography.body(13, weight: FontWeight.w900, color: p.onCta),
                ),
              ),
              const Spacer(),
              if (level.nextName != null)
                Flexible(
                  flex: 3,
                  child: Text(
                    l.buanLevelToNext(level.nextName!, Fmt.number(level.pointsToNext)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: AppTypography.number(13, color: soft),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Semantics(
            label: l.buanLevelProgress,
            child: AppProgressBar(
              value: level.progress,
              height: 10,
              track: p.paper.withValues(alpha: .2),
              gradient: LinearGradient(colors: [p.secondary, p.glow]),
            ),
          ),
          if (level.tiers.isNotEmpty) ...[
            const SizedBox(height: 8),
            ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final t in level.tiers)
                    Flexible(
                      child: Text(
                        t,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: AppTypography.body(10, weight: FontWeight.w900, color: p.onBuan.withValues(alpha: .85)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
