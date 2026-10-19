import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/base/view_state.dart';
import '../../../core/di/locator.dart';
import '../../../core/router/routes.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/opportunities/opportunity.dart';
import '../../../data/repositories/opportunity_repository.dart';
import '../../../l10n/l10n.dart';
import '../view_model/opportunity_list_view_model.dart';
import '../widgets/category_strip.dart';
import '../widgets/deal_card.dart';

/// C1 · Fırsatlar sekmesi.
class OpportunityListView extends StatelessWidget {
  const OpportunityListView({super.key});

  @override
  Widget build(BuildContext context) {
    final member = context.select<SessionController, bool>((s) => s.isAuthenticated);
    return ChangeNotifierProvider(
      key: ValueKey(member),
      create: (_) => OpportunityListViewModel(sl<OpportunityRepository>(), isMember: member)..load(),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  bool _onScroll(BuildContext context, ScrollNotification n) {
    if (n.metrics.axis == Axis.vertical && n.metrics.extentAfter < 600) context.read<OpportunityListViewModel>().loadMore();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OpportunityListViewModel>();
    final p = context.palette;
    final bottom = AppSpacing.tabBarHeight + MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: p.bg,
      body: BlobBackground(
        variant: BlobLayout.cornerPink,
        child: RefreshIndicator(
          color: p.teal,
          onRefresh: vm.refresh,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) => _onScroll(context, n),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _Header(walletCount: vm.walletCount)),
                SliverToBoxAdapter(
                  child: CategoryStrip(categories: vm.categories, selected: vm.category, onSelect: vm.selectCategory),
                ),
                SliverToBoxAdapter(
                  child: FilterStrip(selected: vm.filter, onToggle: vm.toggleFilter),
                ),
                ..._content(context, vm),
                SliverToBoxAdapter(child: SizedBox(height: bottom)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _content(BuildContext context, OpportunityListViewModel vm) {
    final state = vm.state;
    final offline = switch (state) {
      ViewSuccess(:final fromCache) => fromCache,
      ViewError(:final cached) => cached != null,
      _ => false,
    };
    if (state.dataOrNull == null) {
      if (state case ViewError(:final error)) {
        return [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 560,
              child: ErrorStateView(error: error, onRetry: vm.refresh),
            ),
          ),
        ];
      }
      return [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 30, 20, 24),
          sliver: SliverToBoxAdapter(
            child: Shimmer(
              child: Column(
                children: [
                  for (var i = 0; i < 3; i++) ...[const DealCardSkeleton(), const SizedBox(height: 16)],
                ],
              ),
            ),
          ),
        ),
      ];
    }
    return [
      if (offline) const SliverToBoxAdapter(child: OfflineBanner(margin: EdgeInsets.fromLTRB(20, 8, 20, 0))),
      if (vm.isEmpty)
        SliverToBoxAdapter(
          child: SizedBox(height: 560, child: _Empty(favorites: vm.filter == OpportunityFilter.favorites)),
        )
      else ...[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Semantics(
              liveRegion: true,
              child: Text(
                context.l10n.oppCount(vm.count),
                style: AppTypography.body(13, weight: FontWeight.w800, color: context.palette.mut),
              ),
            ),
          ),
        ),
        _DealList(items: vm.visible),
        SliverToBoxAdapter(child: _Footer(vm: vm)),
      ],
    ];
  }
}

class _DealList extends StatelessWidget {
  const _DealList({required this.items});

  final List<Opportunity> items;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<OpportunityListViewModel>();
    final now = DateTime.now();
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      sliver: SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final d = items[i];
          return DealCard(
            key: ValueKey(d.id),
            deal: d,
            now: now,
            onTap: () => context.push(Routes.opportunity(d.id)),
            onFavorite: () async {
              final messenger = ScaffoldMessenger.of(context);
              final msg = context.l10n;
              final error = await vm.toggleFavorite(d.id);
              if (error != null && context.mounted) {
                messenger.showSnackBar(SnackBar(content: Text(errorMessageOf(context, error))));
              } else if (error == null) {
                messenger.hideCurrentSnackBar();
                if (!d.isFavorite) {
                  messenger.showSnackBar(SnackBar(content: Text(msg.oppFavoriteAdded), duration: const Duration(seconds: 2)));
                }
              }
            },
          );
        },
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.vm});

  final OpportunityListViewModel vm;

  @override
  Widget build(BuildContext context) {
    if (vm.loadingMore) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 3, color: context.palette.teal)),
        ),
      );
    }
    if (vm.loadMoreFailed) {
      return Center(
        child: AppButton.text(label: context.l10n.commonRetry, expand: false, onPressed: vm.loadMore),
      );
    }
    return const SizedBox(height: 16);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.walletCount});

  final int? walletCount;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final label = walletCount == null ? l.oppWallet : l.oppWalletCount(walletCount!);
    return TabScreenHeader(
      title: l.tabOpportunities,
      trailing: [
        AppIconButton(
          icon: AppIcons.search,
          semanticLabel: l.oppSearchLabel,
          background: p.sf,
          onPressed: () => context.push(Routes.search),
        ),
        Semantics(
          button: true,
          label: l.oppWalletSemantics(walletCount ?? 0),
          excludeSemantics: true,
          child: GestureDetector(
            onTap: () => AuthGate.guard(context, () => context.push(Routes.myOpportunities)),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(color: p.ink, borderRadius: BorderRadius.circular(22)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(AppIcons.wallet, size: 18, color: p.bg, strokeWidth: 2.4),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: AppTypography.body(14, weight: FontWeight.w900, color: p.bg),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// S4 · Boş durum (Favoriler boşsa "Fırsatlara göz at").
class _Empty extends StatelessWidget {
  const _Empty({required this.favorites});

  final bool favorites;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.read<OpportunityListViewModel>();
    return EmptyState(
      title: l.emptyTitle,
      message: favorites ? l.oppFavEmptyMessage : l.oppEmptyMessage,
      ctaLabel: favorites ? l.oppFavEmptyCta : l.oppEmptyCta,
      onCta: vm.clearFilters,
    );
  }
}
