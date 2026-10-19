import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/di/locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/games/game.dart';
import '../../../data/repositories/games_repository.dart';
import '../../../l10n/l10n.dart';
import '../view_model/memory_game_view_model.dart';
import 'game_icons.dart';

/// Hafıza Kartları — alt sayfada oynanan yerleşik mini oyun (4×3).
abstract final class MemoryGameSheet {
  static Future<void> show(BuildContext context, Game game) => AppSheet.show<void>(
    context,
    builder: (_) => ChangeNotifierProvider(
      create: (_) => MemoryGameViewModel(sl<GamesRepository>(), gameId: game.id),
      child: _MemoryBody(title: game.title),
    ),
  );
}

class _MemoryBody extends StatelessWidget {
  const _MemoryBody({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.watch<MemoryGameViewModel>();
    final names = [l.gameSymbolKoza, l.gameSymbolKilicKalkan, l.gameSymbolKaragoz, l.gameSymbolCami, l.gameSymbolTeleferik, l.gameSymbolKestane];
    final tiles = [p.tile1, p.tile2, p.tile3, p.tile5, p.tile6, p.tile4];
    final reward = vm.result?.awarded ?? 0;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(title, style: AppTypography.display(24, color: p.ink)),
              ),
            ),
            Text(l.gameMemoryMoves(vm.moves), style: AppTypography.number(14, color: p.mut)),
          ],
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: [
            for (var i = 0; i < vm.deck.length; i++)
              _Card(
                up: vm.isFaceUp(i),
                matched: vm.isMatched(i),
                icon: GameIcons.symbols[vm.deck[i] % GameIcons.symbols.length],
                color: tiles[vm.deck[i] % tiles.length],
                label: vm.isFaceUp(i) ? names[vm.deck[i] % names.length] : l.gameMemoryCardHidden(i + 1),
                onTap: () {
                  Haptics.selection();
                  vm.flip(i);
                },
              ),
          ],
        ),
        if (vm.finished) ...[
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(
              vm.submitting ? l.commonLoading : l.gameMemoryDone,
              textAlign: TextAlign.center,
              style: AppTypography.display(20, color: p.ink),
            ),
          ),
          if (reward > 0)
            Text(
              l.buanAmount(Fmt.signed(reward)),
              textAlign: TextAlign.center,
              style: AppTypography.number(28, color: p.buanFill),
            ),
          const SizedBox(height: 12),
          if (vm.submitFailed)
            AppButton(label: l.commonRetry, onPressed: vm.retrySubmit)
          else
            AppButton(
              label: l.gameMemoryAgain,
              onPressed: vm.submitting ? null : vm.restart,
              variant: AppButtonVariant.outlineInk,
              size: AppButtonSize.medium,
            ),
        ],
      ],
    );
    return Stack(
      children: [
        body,
        Positioned.fill(child: CelebrationOverlay(play: reward > 0)),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.up, required this.matched, required this.icon, required this.color, required this.label, required this.onTap});

  final bool up, matched;
  final String icon, label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: !up,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: context.reduceMotion ? Duration.zero : AppDurations.fast,
          decoration: BoxDecoration(
            color: up ? color : p.buanFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: matched ? p.onTile : Colors.transparent, width: 2),
          ),
          alignment: Alignment.center,
          child: up
              ? AppIcon(icon, size: 32, color: p.onTile, strokeWidth: 2)
              : AppIcon(AppIcons.buanTab, size: 26, color: p.coinMark, strokeWidth: 2),
        ),
      ),
    );
  }
}
