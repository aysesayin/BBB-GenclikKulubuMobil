import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/base/base_view.dart';
import '../../../core/di/locator.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/buan/buan_task.dart';
import '../../../data/repositories/buan_repository.dart';
import '../../../l10n/l10n.dart';
import '../view_model/buan_view_model.dart';
import '../widgets/buan_hero.dart';
import '../widgets/buan_skeleton.dart';
import '../widgets/streak_strip.dart';
import '../widgets/task_card.dart';
import '../widgets/task_info_sheet.dart';

/// E1 · BUAN ana ekranı + Kazan sekmesi.
class BuanView extends StatelessWidget {
  const BuanView({super.key});

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider(create: (_) => BuanViewModel(sl<BuanRepository>())..load(), child: const _Body());
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BuanViewModel>();
    final l = context.l10n;
    return Scaffold(
      backgroundColor: context.palette.bg,
      body: ViewStateBuilder<BuanHomeData>(
        state: vm.state,
        onRetry: vm.load,
        skeleton: (_) => const BuanSkeleton(heroHeight: 250, rows: 6),
        empty: (_) => EmptyState(title: l.buanEarnEmptyTitle, message: l.buanEarnEmptyMessage),
        builder: (context, data, {required offline}) => _Content(data: data, balance: vm.balance, offline: offline),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.data, required this.balance, required this.offline});

  final BuanHomeData data;
  final int balance;
  final bool offline;

  void _openTask(BuildContext context, BuanTask task) {
    final route = BuanViewModel.routeFor(task);
    if (route == null) {
      TaskInfoSheet.show(context, task);
    } else {
      context.push(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.read<BuanViewModel>();
    final bottom = AppSpacing.tabBarHeight + MediaQuery.paddingOf(context).bottom;
    return RefreshIndicator(
      onRefresh: vm.refresh,
      edgeOffset: MediaQuery.paddingOf(context).top,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: BuanHero(balance: balance, level: data.level, onHistory: () => context.push(Routes.history)),
          ),
          if (offline) const SliverToBoxAdapter(child: OfflineBanner(margin: EdgeInsets.fromLTRB(20, 12, 20, 0))),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(child: StreakStrip(streak: data.streak)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Semantics(
                container: true,
                label: l.buanHomeSectionsLabel,
                child: SegmentedTabs(
                  labels: [l.buanTabEarn, l.buanTabMarket, l.buanTabLeague, l.buanTabBadges],
                  index: 0,
                  onChanged: (i) {
                    const routes = [null, Routes.market, Routes.league, Routes.badges];
                    final r = routes[i];
                    if (r != null) context.push(r);
                  },
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 6, 20, 28 + bottom),
            sliver: SliverList.list(
              children: [
                for (final g in data.groups) ...[
                  _GroupHeader(title: g.title, note: g.note),
                  for (final t in g.tasks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TaskCard(task: t, onTap: () => _openTask(context, t)),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title, required this.note});

  final String title, note;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: AppTypography.display(20, color: p.ink)),
            ),
          ),
          if (note.isNotEmpty)
            Text(
              note,
              style: AppTypography.body(12, weight: FontWeight.w800, color: p.mut),
            ),
        ],
      ),
    );
  }
}
