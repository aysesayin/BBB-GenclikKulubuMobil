import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/base/base_view.dart';
import '../../../core/di/locator.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/games/game.dart';
import '../../../data/repositories/games_repository.dart';
import '../../../l10n/l10n.dart';
import '../view_model/games_view_model.dart';
import '../widgets/game_cards.dart';
import '../widgets/memory_game_sheet.dart';

/// F1 · Oyunlar — Keşfet sekmesi içinde (alt navigasyon görünür).
class GamesView extends StatelessWidget {
  const GamesView({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(create: (_) => GamesViewModel(sl<GamesRepository>())..load(), child: const _Body());
}

class _Body extends StatelessWidget {
  const _Body();

  void _open(BuildContext context, Game game) {
    final l = context.l10n;
    if (game.playsPerDay != null && game.playsLeft <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.gameNoPlaysLeft)));
      return;
    }
    switch (game.kind) {
      // TODO(varsayım): Bilgi yarışması şimdilik BUAN "Cevapla Kazan" ekranını açar; ayrı oyun motoru (Flame) gelince değişir.
      case GameKind.quiz:
        context.push(Routes.quiz);
      case GameKind.memory:
        MemoryGameSheet.show(context, game);
      case GameKind.whereIsIt || GameKind.other:
        _comingSoon(context, game);
    }
  }

  void _comingSoon(BuildContext context, Game game) {
    final l = context.l10n;
    AppSheet.show<void>(
      context,
      builder: (ctx) => Column(
        children: [
          const Mascot(mood: MascotMood.surprised, size: 110),
          const SizedBox(height: 12),
          Semantics(
            header: true,
            child: Text(l.gameComingSoonTitle, style: AppTypography.display(26, color: ctx.palette.ink)),
          ),
          const SizedBox(height: 8),
          Text(
            l.gameComingSoonBody(game.title),
            textAlign: TextAlign.center,
            style: AppTypography.body(15, color: ctx.palette.mut, height: 1.4),
          ),
          const SizedBox(height: 20),
          AppButton(label: l.commonDone, onPressed: () => Navigator.of(ctx).pop()),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.watch<GamesViewModel>();
    final bottom = AppSpacing.tabBarHeight + MediaQuery.paddingOf(context).bottom;
    final header = AppBackHeader(title: l.gameTitle, titleSize: 28);
    return Scaffold(
      body: ViewStateBuilder<GamesHub>(
        state: vm.state,
        onRetry: vm.load,
        skeleton: (_) => Shimmer(
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 64, 20, bottom),
            children: const [
              SkeletonBox(height: 220, radius: 28),
              SizedBox(height: 18),
              SkeletonBox(height: 108, radius: 24),
              SizedBox(height: 12),
              SkeletonBox(height: 108, radius: 24),
            ],
          ),
        ),
        empty: (_) => Column(
          children: [
            header,
            Expanded(
              child: EmptyState(title: l.gameEmptyTitle, message: l.gameEmptyBody),
            ),
            SizedBox(height: bottom),
          ],
        ),
        builder: (context, hub, {required offline}) {
          final tiles = [p.tile6, p.tile2, p.tile1, p.tile5, p.tile3, p.tile4];
          const tilts = [-4.0, 3.0, -2.0];
          final t = hub.tournament;
          return ListView(
            padding: EdgeInsets.only(bottom: bottom + 24),
            children: [
              header,
              if (offline) const OfflineBanner(),
              if (t != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: TournamentCard(
                    tournament: t,
                    onTap: () {
                      final g = vm.gameById(t.gameId);
                      if (g != null) _open(context, g);
                    },
                  ),
                ),
              for (var i = 0; i < hub.games.length; i++)
                Padding(
                  padding: EdgeInsets.fromLTRB(20, i == 0 ? 18 : 12, 20, 0),
                  child: GameCard(
                    game: hub.games[i],
                    tile: tiles[i % tiles.length],
                    tilt: tilts[i % tilts.length],
                    onTap: () => _open(context, hub.games[i]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
