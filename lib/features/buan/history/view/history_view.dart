import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/buan/buan_transaction.dart';
import '../../../../data/repositories/buan_repository.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/buan_skeleton.dart';
import '../view_model/history_view_model.dart';
import '../widgets/history_widgets.dart';

/// E6 · Geçmiş İşlemlerim.
class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider(create: (_) => HistoryViewModel(sl<BuanRepository>())..load(), child: const _Body());
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HistoryViewModel>();
    final l = context.l10n;
    const filters = BuanTxFilter.values;
    return Scaffold(
      backgroundColor: context.palette.bg,
      body: Column(
        children: [
          AppBackHeader(title: l.buanHistoryTitle),
          if (vm.summary case final s?)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: HistorySummary(summary: s),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: SegmentedTabs(
              labels: [l.commonAll, l.buanHistoryFilterEarn, l.buanHistoryFilterSpend],
              index: filters.indexOf(vm.filter),
              onChanged: (i) => vm.setFilter(filters[i]),
            ),
          ),
          Expanded(
            child: ViewStateBuilder<List<BuanTransaction>>(
              state: vm.state,
              onRetry: vm.load,
              skeleton: (_) =>
                  MediaQuery.removePadding(context: context, removeTop: true, child: const BuanSkeleton(rows: 8, rowHeight: 56)),
              empty: (_) => EmptyState(
                title: l.buanHistoryEmptyTitle,
                message: l.buanHistoryEmptyMessage,
                ctaLabel: l.buanHistoryEmptyCta,
                onCta: () => Navigator.of(context).maybePop(),
              ),
              builder: (context, items, {required offline}) => _Timeline(items: items, offline: offline),
            ),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.items, required this.offline});

  final List<BuanTransaction> items;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<HistoryViewModel>();
    final loadingMore = context.select<HistoryViewModel, bool>((v) => v.loadingMore);
    final days = HistoryViewModel.groupByDay(items);
    final bottom = AppSpacing.tabBarHeight + MediaQuery.paddingOf(context).bottom;
    final children = <Widget>[
      if (offline) const OfflineBanner(margin: EdgeInsets.only(top: 12)),
      for (final d in days) ...[HistoryDayHeader(label: historyDayLabel(context, d.day)), for (final t in d.items) TransactionRow(tx: t)],
      if (loadingMore)
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
        ),
    ];
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.extentAfter < 300) vm.loadMore();
        return false;
      },
      child: RefreshIndicator(
        onRefresh: vm.refresh,
        child: ListView(padding: EdgeInsets.fromLTRB(20, 6, 20, bottom + 24), children: children),
      ),
    );
  }
}
