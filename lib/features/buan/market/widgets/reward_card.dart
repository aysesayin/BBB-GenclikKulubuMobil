import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/buan/buan_reward.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/buan_icons.dart';
import '../../widgets/buan_ui.dart';

/// Kart altındaki stok / "ilk N" sayacı metni.
String rewardStockNote(AppLocalizations l, BuanReward r) {
  if (r.soldOut) return l.buanMarketSoldOut;
  if (r.limitNote case final s? when s.isNotEmpty) return s;
  if (r.firstN != null && r.firstNLeft != null) return l.buanMarketFirstN(r.firstN!, r.firstNLeft!);
  if (r.stock != null) return l.buanMarketStock(r.stock!);
  if (r.perPersonLimit != null) return l.buanMarketPerPerson(r.perPersonLimit!);
  return '';
}

/// Fiyat çipi: bakiye yetiyorsa mor dolgu, yetmiyorsa gri. Sabit min genişlik, satır kırmaz.
class RewardPriceChip extends StatelessWidget {
  const RewardPriceChip({super.key, required this.price, required this.affordable});

  final int price;
  final bool affordable;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return BuanPointsBadge(
      points: price,
      signed: false,
      minWidth: 72,
      height: 26,
      background: affordable ? p.buanFill : p.sf2,
      foreground: affordable ? p.paper : p.mut,
    );
  }
}

/// 2 sütunlu pazar ızgarasındaki ödül kartı.
class RewardCard extends StatelessWidget {
  const RewardCard({super.key, required this.reward, required this.affordable, required this.onTap, this.missing = 0});

  final BuanReward reward;
  final bool affordable;

  /// Bakiye yetmiyorsa eksik BUAN ("1.250 BUAN daha"); 0 → gösterilmez.
  final int missing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final note = rewardStockNote(l, reward);
    final semantics = l.buanMarketCardSemantics(
      reward.title,
      Fmt.number(reward.price),
      [if (note.isNotEmpty) note, if (!affordable) l.buanMarketNotAffordable, if (!affordable && missing > 0) l.buanMarketMissing(Fmt.number(missing))].join(', '),
    );
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      clip: true,
      semanticLabel: semantics,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 104,
              color: buanTile(p, reward.tile),
              child: Stack(
                children: [
                  Center(child: AppIcon(BuanIcons.byKey(reward.icon), size: 44, color: p.onTile, strokeWidth: 1.9)),
                  if (reward.tag != null) Positioned(left: 8, top: 8, child: TagBadge(label: reward.tag!, fontSize: 10, radius: 8)),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        reward.title,
                        style: AppTypography.body(14, weight: FontWeight.w800, height: 1.25, color: p.ink),
                      ),
                    ),
                    const SizedBox(height: 6),
                    RewardPriceChip(price: reward.price, affordable: affordable),
                    if (!affordable && missing > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        l.buanMarketMissing(Fmt.number(missing)),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.number(11, weight: FontWeight.w800, color: p.pinkT),
                      ),
                    ],
                    if (note.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        note,
                        maxLines: 2,
                        style: AppTypography.body(11, weight: FontWeight.w800, color: reward.soldOut ? p.pinkT : p.mut),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
