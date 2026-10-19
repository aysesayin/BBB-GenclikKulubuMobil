import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/base/view_state.dart';
import '../../../core/di/locator.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/opportunities/claim.dart';
import '../../../data/repositories/opportunity_repository.dart';
import '../../../l10n/l10n.dart';
import '../view_model/my_opportunities_view_model.dart';
import '../widgets/coupon_card.dart';
import 'claimed_view.dart';

/// C4 · Fırsatlarım (`/firsatlar/cuzdan`, alt navigasyon görünür).
class MyOpportunitiesView extends StatelessWidget {
  const MyOpportunitiesView({super.key});

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider(create: (_) => MyOpportunitiesViewModel(sl<OpportunityRepository>())..load(), child: const _Body());
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MyOpportunitiesViewModel>();
    final p = context.palette;
    final l = context.l10n;
    final bottom = AppSpacing.tabBarHeight + MediaQuery.paddingOf(context).bottom;
    final labels = [
      l.oppWalletActive(vm.countOf(WalletStatus.active)),
      l.oppWalletUsedTab(vm.countOf(WalletStatus.used)),
      l.oppWalletExpiredTab,
    ];
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBackHeader(title: l.oppMyOpportunities),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: SegmentedTabs(labels: labels, index: vm.tab, onChanged: vm.selectTab),
          ),
          Expanded(
            child: RefreshIndicator(
              color: p.teal,
              onRefresh: vm.refresh,
              child: _List(vm: vm, bottom: bottom),
            ),
          ),
        ],
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.vm, required this.bottom});

  final MyOpportunitiesViewModel vm;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = vm.state;
    final padding = EdgeInsets.fromLTRB(20, 18, 20, 24 + bottom);
    if (state.dataOrNull == null) {
      if (state case ViewError(:final error)) {
        return ListView(
          padding: EdgeInsets.only(bottom: bottom),
          children: [
            SizedBox(
              height: 520,
              child: ErrorStateView(error: error, onRetry: vm.refresh),
            ),
          ],
        );
      }
      return Shimmer(
        child: ListView(
          padding: padding,
          children: [
            for (var i = 0; i < 3; i++) const Padding(padding: EdgeInsets.only(bottom: 14), child: SkeletonBox(height: 96, radius: 22)),
          ],
        ),
      );
    }
    final offline = state is ViewError || (state is ViewSuccess<List<WalletItem>> && state.fromCache);
    final items = vm.items;
    final now = DateTime.now();
    return ListView(
      padding: padding,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        if (offline)
          const Padding(
            padding: EdgeInsets.only(bottom: 14),
            child: OfflineBanner(margin: EdgeInsets.zero),
          ),
        if (items.isEmpty)
          SizedBox(
            height: 460,
            child: EmptyState(
              title: l.emptyTitle,
              message: l.oppWalletEmpty,
              ctaLabel: l.oppFavEmptyCta,
              onCta: () => context.go(Routes.opportunities),
            ),
          ),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: CouponCard(
              key: ValueKey(item.id),
              item: item,
              now: now,
              onTap: () => item.status == WalletStatus.active
                  ? context.push(
                      Routes.opportunityClaimed(item.opportunityId),
                      extra: item.claim == null ? null : ClaimedExtra(item.claim!),
                    )
                  : context.push(Routes.opportunity(item.opportunityId)),
            ),
          ),
      ],
    );
  }
}
