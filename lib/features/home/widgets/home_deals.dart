import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/home/home_items.dart';
import '../../../l10n/l10n.dart';
import '../home_links.dart';

/// "Sana Özel Fırsatlar": 262 px yatay kartlar.
class HomeDeals extends StatelessWidget {
  const HomeDeals({super.key, required this.deals});

  final List<HomeDeal> deals;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: context.l10n.homeDealsTitle, onAction: () => context.go(Routes.opportunities)),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < deals.length; i++) ...[if (i > 0) const SizedBox(width: 12), _DealCard(deal: deals[i])],
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _DealCard extends StatelessWidget {
  const _DealCard({required this.deal});

  final HomeDeal deal;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final blob =
        '<svg viewBox="0 0 262 90"><path d="M160 -10c50 0 110 20 105 60s-50 50-95 45-55-30-50-60 5-45 40-45z" '
        'fill="${p.paper.hex}" fill-opacity=".35"/></svg>';
    return SizedBox(
      width: 262,
      child: AppCard(
        padding: EdgeInsets.zero,
        clip: true,
        semanticLabel: '${deal.brand}, ${deal.title}',
        onTap: () => context.push(Routes.opportunity(deal.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 90,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(child: ColoredBox(color: toneColor(p, deal.tone))),
                  Positioned.fill(child: SvgArt(blob, fit: BoxFit.cover)),
                  if (deal.badge.isNotEmpty) Positioned(left: 12, top: 12, child: TagBadge(label: deal.badge)),
                  Positioned(
                    right: 12,
                    bottom: -18,
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: p.paper,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: p.line),
                      ),
                      child: Text(
                        deal.logo,
                        maxLines: 1,
                        style: AppTypography.body(11, weight: FontWeight.w900, color: p.onTile),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deal.brand,
                    style: AppTypography.body(12, weight: FontWeight.w800, color: p.mut),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(right: 40),
                    child: Text(
                      deal.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.body(15, weight: FontWeight.w800, color: p.ink, height: 1.25),
                    ),
                  ),
                  const SizedBox(height: 4),
                  DaysLeftLabel(days: deal.daysLeft, color: p.pinkT),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
