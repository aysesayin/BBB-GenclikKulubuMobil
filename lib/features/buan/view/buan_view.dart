import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/base/base_view.dart';
import '../../../core/di/locator.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ui_prefs_controller.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/repositories/buan_repository.dart';
import '../../../l10n/l10n.dart';
import '../view_model/buan_view_model.dart';
import '../widgets/buan_hero.dart';
import '../widgets/buan_skeleton.dart';
import '../widgets/buan_tabs_header.dart';
import '../widgets/task_card.dart';
import 'buan_easy_body.dart';

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
    final easy = context.easyMode;
    return Scaffold(
      backgroundColor: context.palette.bg,
      body: ViewStateBuilder<BuanHomeData>(
        state: vm.state,
        onRetry: vm.load,
        skeleton: (_) => const BuanSkeleton(heroHeight: 150, rows: 6),
        empty: (_) => EmptyState(title: l.buanEarnEmptyTitle, message: l.buanEarnEmptyMessage),
        builder: (context, data, {required offline}) => easy
            ? BuanEasyBody(data: data, balance: vm.balance, offline: offline)
            : _Content(data: data, balance: vm.balance, offline: offline),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.data, required this.balance, required this.offline});

  final BuanHomeData data;
  final int balance;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<BuanViewModel>();
    final mq = MediaQuery.of(context);
    final bottom = AppSpacing.tabBarHeight + mq.padding.bottom;
    return RefreshIndicator(
      onRefresh: vm.refresh,
      edgeOffset: mq.padding.top,
      child: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: BuanHeroDelegate(
              balance: balance,
              level: data.level,
              streak: data.streak,
              topPadding: mq.padding.top,
              screenHeight: mq.size.height,
              onHistory: () => context.push(Routes.history),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: BuanTabsHeaderDelegate(
              onChanged: (i) {
                const routes = [null, Routes.market, Routes.league, Routes.badges];
                final r = routes[i];
                if (r != null) context.push(r);
              },
            ),
          ),
          if (offline) const SliverToBoxAdapter(child: OfflineBanner(margin: EdgeInsets.fromLTRB(20, 4, 20, 0))),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 28 + bottom),
            sliver: SliverList.list(
              children: [
                for (final g in data.groups) ...[
                  BuanGroupHeader(title: g.title, note: g.note),
                  for (final t in g.tasks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TaskCard(task: t, onTap: () => context.push(BuanViewModel.routeFor(t))),
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
