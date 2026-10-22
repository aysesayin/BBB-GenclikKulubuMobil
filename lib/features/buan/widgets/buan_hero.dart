import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/buan/buan_wallet.dart';
import '../../../l10n/l10n.dart';
import 'buan_hero_parts.dart';
import 'streak_strip.dart';

/// E1 üst cüzdan — kaydırmayla daralan başlık.
/// Açıkken (ekranın ~%25'i): logo + "Geçmiş", count-up bakiye, seviye pill'i + tek satır 7 gün noktası.
/// Kaydırınca 72 px'lik yalnız bakiye çubuğuna iner; altındaki sekmeler sabit kalır.
class BuanHeroDelegate extends SliverPersistentHeaderDelegate {
  const BuanHeroDelegate({
    required this.balance,
    required this.level,
    required this.streak,
    required this.onHistory,
    required this.topPadding,
    required this.screenHeight,
  });

  static const barHeight = 72.0;

  /// Açık içeriğin (üst dolgu hariç) ihtiyaç duyduğu yükseklik.
  static const _restContent = 150.0;

  final int balance;
  final BuanLevel level;
  final BuanStreak streak;
  final VoidCallback onHistory;
  final double topPadding, screenHeight;

  @override
  double get minExtent => barHeight + topPadding;

  @override
  double get maxExtent => math.max(screenHeight * .25, topPadding + _restContent);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final range = maxExtent - minExtent;
    final t = range <= 0 ? 1.0 : (shrinkOffset / range).clamp(0.0, 1.0);
    return BuanHeroSurface(
      t: t,
      height: maxExtent,
      topPadding: topPadding,
      balance: balance,
      level: level,
      streak: streak,
      onHistory: onHistory,
    );
  }

  @override
  bool shouldRebuild(BuanHeroDelegate old) =>
      old.balance != balance ||
      old.level != level ||
      old.streak != streak ||
      old.topPadding != topPadding ||
      old.screenHeight != screenHeight;
}

/// Hero yüzeyi: `t` 0 → açık, 1 → daralmış. Bağımsız widget olarak test edilebilir.
class BuanHeroSurface extends StatelessWidget {
  const BuanHeroSurface({
    super.key,
    required this.t,
    required this.height,
    required this.topPadding,
    required this.balance,
    required this.level,
    required this.streak,
    required this.onHistory,
  });

  final double t, height, topPadding;
  final int balance;
  final BuanLevel level;
  final BuanStreak streak;
  final VoidCallback onHistory;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final expandedOpacity = (1 - t * 1.7).clamp(0.0, 1.0);
    final barOpacity = ((t - .55) / .45).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(32 * (1 - t))),
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: p.buanGradient),
        child: Stack(
          clipBehavior: Clip.hardEdge,
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
            // Açık içerik: daralırken yeniden akmaz, kırpılır ve solar.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: height,
              child: _Fade(
                opacity: expandedOpacity,
                child: Semantics(
                  container: true,
                  label: l.buanHomeWalletLabel,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, topPadding + 6, 20, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        HeroTopRow(onHistory: onHistory),
                        HeroBalance(balance: balance),
                        Row(
                          children: [
                            HeroLevelPill(level: level),
                            const Spacer(),
                            Flexible(
                              flex: 3,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: StreakDots(streak: streak),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Daralmış çubuk: yalnız bakiye.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: BuanHeroDelegate.barHeight,
              child: _Fade(
                opacity: barOpacity,
                child: Semantics(
                  label: l.buanHeroCollapsedSemantics(Fmt.number(balance)),
                  excludeSemantics: true,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        const BuanCoin(size: 28, ring: true),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            Fmt.number(balance),
                            maxLines: 1,
                            softWrap: false,
                            style: AppTypography.number(26, height: 1, color: p.onBuan),
                          ),
                        ),
                        Text(l.buanUnit, style: AppTypography.body(13, weight: FontWeight.w900, color: p.onBuan.withValues(alpha: .9))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opaklık 0 iken dokunma ve erişilebilirlik ağacından da çıkar.
class _Fade extends StatelessWidget {
  const _Fade({required this.opacity, required this.child});

  final double opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0) return const SizedBox.shrink();
    return IgnorePointer(
      ignoring: opacity < .5,
      child: ExcludeSemantics(excluding: opacity < .5, child: Opacity(opacity: opacity, child: child)),
    );
  }
}
