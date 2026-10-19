import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/buan/buan_badge.dart';
import '../../../../data/repositories/buan_repository.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/buan_skeleton.dart';
import '../view_model/badges_view_model.dart';
import '../widgets/badge_tile.dart';

/// E5 · Rozetler.
class BadgesView extends StatelessWidget {
  const BadgesView({super.key});

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider(create: (_) => BadgesViewModel(sl<BuanRepository>())..load(), child: const _Body());
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BadgesViewModel>();
    final p = context.palette;
    final l = context.l10n;
    final hasData = vm.state.dataOrNull != null;
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        children: [
          AppBackHeader(
            title: l.buanBadgesTitle,
            trailing: [
              if (hasData)
                Semantics(
                  label: l.buanBadgesProgress(vm.earnedCount, vm.total),
                  excludeSemantics: true,
                  child: Text(l.buanBadgesCount(vm.earnedCount, vm.total), style: AppTypography.number(15, color: p.ink)),
                ),
            ],
          ),
          Expanded(
            child: ViewStateBuilder<List<BuanBadge>>(
              state: vm.state,
              onRetry: vm.load,
              skeleton: (_) => MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: const BuanSkeleton(rows: 4, rowHeight: 130, grid: true),
              ),
              empty: (_) => EmptyState(title: l.buanBadgesEmptyTitle, message: l.buanBadgesEmptyMessage),
              builder: (context, badges, {required offline}) => _Grid(badges: badges, offline: offline),
            ),
          ),
        ],
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.badges, required this.offline});

  final List<BuanBadge> badges;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<BadgesViewModel>();
    final p = context.palette;
    final l = context.l10n;
    final bottom = AppSpacing.tabBarHeight + MediaQuery.paddingOf(context).bottom;
    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: ListView(
        padding: EdgeInsets.only(bottom: bottom + 28),
        children: [
          if (offline) const OfflineBanner(margin: EdgeInsets.fromLTRB(20, 12, 20, 0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: AppProgressBar(
              value: vm.progress,
              height: 12,
              semanticsValue: l.buanBadgesProgress(vm.earnedCount, vm.total),
              gradient: LinearGradient(colors: [p.secondary, p.primary]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: LayoutBuilder(
              builder: (context, c) {
                const gap = 12.0;
                final w = ((c.maxWidth - gap * 2) / 3).floorToDouble();
                return Wrap(
                  spacing: gap,
                  runSpacing: 22,
                  children: [
                    for (var i = 0; i < badges.length; i++)
                      SizedBox(
                        width: w,
                        child: BadgeTile(badge: badges[i], index: i),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
