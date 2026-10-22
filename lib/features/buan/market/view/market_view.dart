import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/ui_prefs_controller.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/buan/buan_reward.dart';
import '../../../../data/repositories/buan_repository.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/buan_skeleton.dart';
import '../view_model/market_view_model.dart';
import '../widgets/market_hero.dart';
import '../widgets/reward_card.dart';

/// E2 · BUAN Pazar.
class MarketView extends StatelessWidget {
  const MarketView({super.key});

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider(create: (_) => MarketViewModel(sl<BuanRepository>())..load(), child: const _Body());
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MarketViewModel>();
    final l = context.l10n;
    return Scaffold(
      backgroundColor: context.palette.bg,
      body: Column(
        children: [
          AppBackHeader(
            title: l.buanMarketTitle,
            titleSize: 28,
            trailing: [BuanBalanceChip(balance: vm.balance)],
          ),
          Expanded(
            child: ViewStateBuilder<BuanMarket>(
              state: vm.state,
              onRetry: vm.load,
              skeleton: (_) => const _MarketSkeleton(),
              builder: (context, _, {required offline}) => _Content(offline: offline),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarketSkeleton extends StatelessWidget {
  const _MarketSkeleton();

  @override
  Widget build(BuildContext context) =>
      MediaQuery.removePadding(context: context, removeTop: true, child: const BuanSkeleton(rows: 4, rowHeight: 200, grid: true));
}

class _Content extends StatelessWidget {
  const _Content({required this.offline});

  final bool offline;

  void _open(BuildContext context, BuanReward r) => context.push(Routes.reward(r.id));

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MarketViewModel>();
    final l = context.l10n;
    final featured = vm.featured;
    final items = vm.visibleItems;
    final bottom = AppSpacing.tabBarHeight + MediaQuery.paddingOf(context).bottom;
    final easy = context.easyMode;
    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: ListView(
        padding: EdgeInsets.only(bottom: bottom + 24),
        children: [
          if (offline) const OfflineBanner(margin: EdgeInsets.fromLTRB(20, 12, 20, 0)),
          if (featured != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: MarketHero(reward: featured, onTap: () => _open(context, featured)),
            ),
          const SizedBox(height: 16),
          Semantics(
            container: true,
            label: l.buanMarketCategories,
            child: PillRow(
              children: [
                FilterPill(label: l.commonAll, selected: vm.categoryId == null, onTap: () => vm.selectCategory(null)),
                for (final c in vm.categories)
                  FilterPill(label: c.label, selected: vm.categoryId == c.id, onTap: () => vm.selectCategory(c.id)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: _AffordableSwitch(value: vm.affordableOnly, onChanged: vm.setAffordableOnly),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: EmptyState(
                title: l.buanMarketEmptyTitle,
                message: l.buanMarketEmptyMessage,
                ctaLabel: l.buanMarketEmptyCta,
                onCta: vm.clearFilters,
              ),
            )
          else if (easy)
            // Kolay Mod: tek sütun, büyük kartlar.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                children: [
                  for (final r in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SizedBox(height: 230, child: _card(context, vm, r)),
                    ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i += 2)
                    Padding(
                      padding: EdgeInsets.only(bottom: i + 2 < items.length ? 12 : 0),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _card(context, vm, items[i])),
                            const SizedBox(width: 12),
                            Expanded(child: i + 1 < items.length ? _card(context, vm, items[i + 1]) : const SizedBox.shrink()),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, MarketViewModel vm, BuanReward r) =>
      RewardCard(reward: r, affordable: vm.canAfford(r), missing: (r.price - vm.balance).clamp(0, r.price), onTap: () => _open(context, r));
}

class _AffordableSwitch extends StatelessWidget {
  const _AffordableSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    void toggle() {
      Haptics.selection();
      onChanged(!value);
    }

    return MergeSemantics(
      child: Material(
        color: p.sf,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          onTap: toggle,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  AppIcon(AppIcons.filter, size: 20, color: p.teal, strokeWidth: 2.4),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.l10n.buanMarketAffordable,
                      style: AppTypography.body(15, weight: FontWeight.w800, color: p.ink),
                    ),
                  ),
                  Switch(
                    value: value,
                    onChanged: (_) => toggle(),
                    activeTrackColor: p.teal,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
