import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/opportunities/opportunity.dart';
import '../../../l10n/l10n.dart';
import 'opp_style.dart';

/// Logo + "Marka · Kategori" + eğik indirim sticker'ı.
class DetailBrandRow extends StatelessWidget {
  const DetailBrandRow({super.key, required this.detail});

  final OpportunityDetail detail;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final s = detail.summary;
    final meta = detail.categoryName.isEmpty ? s.brand : '${s.brand} · ${detail.categoryName}';
    // Görünüm bunu 26 px yukarı taşan bir OverflowBox içinde konumlar (tasarım: margin-top −26).
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        OppLogoTile(text: s.logoText, size: 64, radius: AppRadii.tile, fontSize: 14),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              meta,
              maxLines: 2,
              style: AppTypography.body(14, weight: FontWeight.w800, color: p.mut),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Transform.rotate(
          angle: -4 * 3.14159 / 180,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: p.cta,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.onTile, width: 2),
              boxShadow: [BoxShadow(color: p.onTile, offset: const Offset(3, 3))],
            ),
            child: Text(s.discountLabel, style: AppTypography.display(22, height: 1, color: p.onCta)),
          ),
        ),
      ],
    );
  }
}

/// Kalan gün · yaş aralığı · +BUAN çipleri.
class DetailInfoChips extends StatelessWidget {
  const DetailInfoChips({super.key, required this.detail, required this.daysLeft, required this.urgent});

  final OpportunityDetail detail;
  final int daysLeft;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    Widget chip(Widget child, Color bg, {double left = 12}) => Container(
      height: 32,
      padding: EdgeInsets.fromLTRB(left, 0, 12, 0),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: child,
    );
    final days = urgent ? p.pinkT : p.ink;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        chip(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(AppIcons.clock, size: 14, color: days, strokeWidth: 2.6),
              const SizedBox(width: 6),
              Text(
                l.daysLeft(daysLeft),
                style: AppTypography.body(13, weight: FontWeight.w900, color: days),
              ),
            ],
          ),
          urgent ? p.pinkS : p.sf2,
        ),
        if (detail.minAge != null && detail.maxAge != null)
          chip(
            Center(
              widthFactor: 1,
              child: Text(
                l.oppAgeRange(detail.minAge!, detail.maxAge!),
                style: AppTypography.body(13, weight: FontWeight.w900, color: p.ink),
              ),
            ),
            p.sf2,
          ),
        if (detail.buanReward > 0)
          Semantics(
            label: l.buanAmount(Fmt.signed(detail.buanReward)),
            excludeSemantics: true,
            child: Container(
              constraints: const BoxConstraints(minWidth: 112),
              child: chip(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BuanCoin(),
                    const SizedBox(width: 6),
                    Text(l.buanAmount(Fmt.signed(detail.buanReward)), softWrap: false, style: AppTypography.number(13, color: p.purT)),
                  ],
                ),
                p.purS,
                left: 4,
              ),
            ),
          ),
      ],
    );
  }
}

/// "Kalan kod 18 / 200" kutusu.
class DetailStockBox extends StatelessWidget {
  const DetailStockBox({super.key, required this.deal});

  final Opportunity deal;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final low = deal.isLowStock;
    final ratio = '${Fmt.number(deal.stockRemaining)} / ${Fmt.number(deal.stockTotal)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(AppRadii.tile)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.oppStockRemaining,
                  style: AppTypography.body(14, weight: FontWeight.w800, color: p.ink),
                ),
              ),
              Text(
                ratio,
                style: AppTypography.number(14, weight: FontWeight.w800, color: low ? p.pinkT : p.teal),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppProgressBar(value: deal.stockRatio, height: 10, color: low ? p.hotFill : p.primary, semanticsValue: l.stockLabel(deal)),
          const SizedBox(height: 8),
          Text(l.oppStockNote, style: AppTypography.body(12, color: p.mut)),
        ],
      ),
    );
  }
}

/// "Nasıl kullanılır?" numaralı adımlar.
class DetailSteps extends StatelessWidget {
  const DetailSteps({super.key, required this.steps});

  final List<String> steps;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final colors = [p.tile1, p.tile6, p.tile2];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(context.l10n.oppHowTo, style: AppTypography.display(20, color: p.ink)),
        ),
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: colors[i % 3], borderRadius: BorderRadius.circular(AppRadii.sm)),
                  alignment: Alignment.center,
                  child: Text(
                    '${i + 1}',
                    style: AppTypography.body(15, weight: FontWeight.w900, color: p.onTile),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(steps[i], style: AppTypography.body(15, color: p.ink)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
