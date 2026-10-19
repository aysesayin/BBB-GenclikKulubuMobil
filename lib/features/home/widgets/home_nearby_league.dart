import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/home/home_feed.dart';
import '../../../l10n/l10n.dart';
import '../view_model/home_view_model.dart';

/// "Yakınındaki Yerler": mini harita illüstrasyonu → Harita.
class HomeNearbyCard extends StatelessWidget {
  const HomeNearbyCard({super.key, required this.nearby});

  final HomeNearby nearby;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final m = nearby.distanceMeters;
    final distance = m < 1000
        ? l.homeDistanceMeters(m)
        : l.homeDistanceKm(
            NumberFormat.decimalPatternDigits(locale: Localizations.localeOf(context).languageCode, decimalDigits: 1).format(m / 1000),
          );
    final road = p.sf.hex;
    final art =
        '<svg viewBox="0 0 353 150" preserveAspectRatio="xMidYMid slice">'
        '<path d="M-10 110 C80 90 120 130 200 100 S320 60 370 80" stroke="$road" stroke-width="10" fill="none"/>'
        '<path d="M60 -10 L110 160" stroke="$road" stroke-width="7"/>'
        '<path d="M240 -10 L210 160" stroke="$road" stroke-width="6"/>'
        '<path d="M20 40 C60 50 140 30 360 45" stroke="$road" stroke-width="4" fill="none"/>'
        '<path d="M270 100c20-8 50 0 60 20s-10 35-40 33-40-45-20-53z" fill="${p.mint.hex}"/></svg>';
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title: l.homeNearbyTitle, actionLabel: l.homeNearbyOpenMap, onAction: () => context.push(Routes.map)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Semantics(
              button: true,
              label: l.homeNearbySemantics,
              child: GestureDetector(
                onTap: () => context.push(Routes.map),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  child: SizedBox(
                    height: 150,
                    child: ColoredBox(
                      color: p.sky,
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final sx = c.maxWidth / 353;
                          return Stack(
                            children: [
                              Positioned.fill(
                                child: SvgArt(art, fit: BoxFit.cover, width: c.maxWidth, height: 150),
                              ),
                              Positioned(
                                left: 92 * sx,
                                top: 46,
                                child: _Pin(color: p.secondary),
                              ),
                              Positioned(
                                left: 196 * sx,
                                top: 70,
                                child: _Pin(color: p.hotFill),
                              ),
                              Positioned(
                                left: 262 * sx,
                                top: 30,
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: p.buanFill,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: p.paper, width: 3),
                                  ),
                                  child: Text(
                                    l.homeMoreCount(nearby.moreCount),
                                    style: AppTypography.body(12, weight: FontWeight.w900, color: p.onBuan),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 12,
                                bottom: 12,
                                right: 12,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(color: p.sf, borderRadius: BorderRadius.circular(14)),
                                    child: Text(
                                      l.homeNearbyLabel(nearby.label, distance),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTypography.body(12, weight: FontWeight.w800, color: p.ink),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Damla biçimli harita iğnesi (r 17·17·17·4, −45°).
class _Pin extends StatelessWidget {
  const _Pin({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: -math.pi / 4,
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: context.palette.paper, width: 3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(17),
          topRight: Radius.circular(17),
          bottomRight: Radius.circular(17),
          bottomLeft: Radius.circular(4),
        ),
      ),
    ),
  );
}

/// Haftalık lig kartı → Lig.
class HomeLeagueCard extends StatelessWidget {
  const HomeLeagueCard({super.key, required this.league});

  final HomeLeague league;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final (days, hours) = HomeViewModel.remaining(league.secondsLeft);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      child: AppCard(
        radius: AppRadii.card,
        onTap: () => context.push(Routes.league),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: p.yelS, borderRadius: BorderRadius.circular(16)),
                  child: AppIcon(AppIcons.trophy, size: 26, color: p.ctaShadow, strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(l.homeLeagueTitle(league.tier), style: AppTypography.display(19, color: p.ink)),
                      ),
                      Text(l.homeLeagueSubtitle(league.rank, days, hours), style: AppTypography.body(13, color: p.mut)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AppProgressBar(value: league.progress, height: 10, color: p.grn),
            const SizedBox(height: 12),
            Text(
              l.homeLeaguePromotion(Fmt.number(league.pointsToPromotion)),
              style: AppTypography.body(13, weight: FontWeight.w800, color: p.grnT),
            ),
          ],
        ),
      ),
    );
  }
}
