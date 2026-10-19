import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/buan/buan_reward.dart';
import '../../../../l10n/l10n.dart';

/// "BÜYÜK ÖDÜL" kartı: sarı zemin, balon/dağ illüstrasyonu, ilk-N sayacı, fiyat.
class MarketHero extends StatelessWidget {
  const MarketHero({super.key, required this.reward, required this.onTap});

  final BuanReward reward;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final fg = p.onCta;
    final counter = reward.firstN != null && reward.firstNLeft != null
        ? l.buanMarketFirstNHero(reward.firstN!, reward.firstNLeft!)
        : (reward.stock != null ? l.buanRewardStockLeft(reward.stock!) : null);
    final art =
        '<svg viewBox="0 0 353 210"><circle cx="290" cy="50" r="30" fill="${p.yelS.hex}"/>'
        '<path d="M150 210 C180 130 200 120 220 140 C235 90 255 80 270 110 C285 70 310 60 330 100 L360 210 Z" fill="${p.hotFill.hex}"/>'
        '<path d="M200 210 C220 160 240 150 260 170 C280 140 300 140 320 170 L360 210 Z" fill="${p.pinkT.hex}" opacity=".6"/>'
        '<ellipse cx="250" cy="70" rx="16" ry="20" fill="${p.paper.hex}"/><path d="M244 88 L256 88 L253 100 L247 100 Z" fill="${p.buanFill.hex}"/>'
        '<ellipse cx="300" cy="105" rx="10" ry="13" fill="${p.coinMark.hex}"/><path d="M296 117 L304 117 L302 125 L298 125 Z" fill="${p.buanFill.hex}"/></svg>';
    return Semantics(
      button: true,
      label: [l.buanMarketBigPrize, reward.title, ?counter, l.buanAmount(Fmt.number(reward.price))].join(', '),
      excludeSemantics: true,
      child: Material(
        color: p.cta,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 210,
            child: Stack(
              children: [
                Positioned.fill(child: SvgArt(art, fit: BoxFit.cover)),
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, c) => Padding(
                      padding: EdgeInsets.fromLTRB(18, 18, c.maxWidth * .44 - 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(10)),
                            child: Text(
                              l.buanMarketBigPrize,
                              style: AppTypography.body(11, weight: FontWeight.w900, color: p.onChip).copyWith(letterSpacing: .4),
                            ),
                          ),
                          Text(
                            reward.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.display(26, height: 1.02, color: fg),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (counter != null)
                                Text(
                                  counter,
                                  style: AppTypography.body(13, weight: FontWeight.w900, color: fg),
                                ),
                              const SizedBox(height: 6),
                              Container(
                                height: 32,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(color: p.buanFill, borderRadius: BorderRadius.circular(16)),
                                child: Text(
                                  l.buanAmount(Fmt.number(reward.price)),
                                  maxLines: 1,
                                  style: AppTypography.number(14, color: p.onBuan),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
