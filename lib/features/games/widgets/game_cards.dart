import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/games/game.dart';
import '../../../l10n/l10n.dart';
import '../../buan/tasks/widgets/task_dates.dart';
import '../../buan/tasks/widgets/task_icons.dart';
import 'game_icons.dart';

/// Haftalık turnuva kartı (chip zemin, mor blob + kupa).
class TournamentCard extends StatelessWidget {
  const TournamentCard({super.key, required this.tournament, required this.onTap});

  final Tournament tournament;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final t = tournament;
    final fg = p.onChip;
    final sub = '${l.gameTournamentPrize(t.winnerCount, Fmt.number(t.totalPrize))} · ${l.daysLeft(daysUntil(t.endsAt))}';
    return Semantics(
      button: true,
      container: true,
      child: Material(
        color: p.chip,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -30,
                child: SvgArt(
                  '<svg viewBox="0 0 220 200"><path d="M120 10c55 0 95 40 90 95s-45 90-100 90S10 150 18 95 65 10 120 10z" fill="${p.buanFill.hex}"/>'
                  '<path d="${GameIcons.trophyArt}" stroke="${p.cta.hex}" stroke-width="8" fill="none" stroke-linecap="round" stroke-linejoin="round"/></svg>',
                  width: 220,
                  height: 200,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TagBadge(label: trUpper(l.gameTournamentTag), background: p.cta, foreground: p.onCta, fontSize: 11),
                    const SizedBox(height: 10),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(t.title, style: AppTypography.display(26, height: 1.05, color: fg)),
                    ),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(
                        sub,
                        style: AppTypography.body(13, weight: FontWeight.w800, color: fg.withValues(alpha: .9)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: p.glow, borderRadius: BorderRadius.circular(22)),
                          child: Text(
                            l.gameTournamentJoin,
                            style: AppTypography.body(15, weight: FontWeight.w900, color: p.onTile),
                          ),
                        ),
                        if (t.rank case final rank?) ...[
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              l.gameTournamentRank(Fmt.number(rank), Fmt.number(t.participants)),
                              style: AppTypography.body(13, weight: FontWeight.w800, color: fg.withValues(alpha: .9)),
                            ),
                          ),
                        ],
                      ],
                    ),
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

/// Oyun kartı: eğik sticker karo + başlık/açıklama + ödül + hak + oynat butonu.
class GameCard extends StatelessWidget {
  const GameCard({super.key, required this.game, required this.tile, required this.tilt, required this.onTap});

  final Game game;
  final Color tile;
  final double tilt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final plays = game.playsPerDay == null ? l.gameUnlimited : l.gamePlaysLeft(game.playsLeft, game.playsPerDay!);
    return AppCard(
      radius: AppRadii.card,
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      semanticLabel: l.gamePlay(game.title),
      child: Row(
        children: [
          Transform.rotate(
            angle: tilt * math.pi / 180,
            child: IconTile(
              icon: GameIcons.of(game.kind),
              color: tile,
              size: 84,
              radius: 22,
              iconSize: 40,
              border: Border.all(color: p.onTile, width: 3),
              shadow: [BoxShadow(color: p.onTile, offset: const Offset(3, 3))],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game.title,
                  style: AppTypography.body(16, weight: FontWeight.w900, color: p.ink),
                ),
                const SizedBox(height: 4),
                Text(game.description, style: AppTypography.body(13, height: 1.3, color: p.mut)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    BuanPointsBadge(points: game.reward, minWidth: 56, height: 24),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        plays,
                        style: AppTypography.body(12, weight: FontWeight.w800, color: p.mut),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ExcludeSemantics(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: p.cta, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: AppIcon(TaskIcons.play, size: 20, color: p.onCta, fill: p.onCta, strokeWidth: 1),
            ),
          ),
        ],
      ),
    );
  }
}
