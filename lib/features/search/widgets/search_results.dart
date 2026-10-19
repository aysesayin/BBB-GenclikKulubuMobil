import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/base/view_state.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/search/search_result.dart';
import '../../../l10n/l10n.dart';
import '../../home/widgets/home_icons.dart';
import '../view_model/search_view_model.dart';

/// Sorgu varken: sekme çipleri + gruplu sonuçlar (150 ms fade).
class SearchResultsPane extends StatelessWidget {
  const SearchResultsPane({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SearchViewModel>();
    final state = vm.results;
    final Widget body = switch (state) {
      ViewError(:final error) => ErrorStateView(error: error, onRetry: () => vm.submit(vm.query)),
      ViewSuccess(:final data) when data.isEmpty => EmptyState(
        title: context.l10n.searchNoResultTitle,
        message: context.l10n.searchNoResultMessage(vm.query.trim()),
      ),
      ViewSuccess() || ViewLoading(previous: _?) => _ResultList(vm: vm),
      _ => const _ResultsSkeleton(),
    };
    final key = switch (body) {
      _ResultList() => 'list-${vm.tab.name}-${identityHashCode(state.dataOrNull)}',
      _ResultsSkeleton() => 'skeleton',
      _ => 'other-${vm.query}',
    };
    return AnimatedSwitcher(
      duration: context.reduceMotion ? Duration.zero : const Duration(milliseconds: 150),
      child: KeyedSubtree(key: ValueKey(key), child: body),
    );
  }
}

class _ResultList extends StatelessWidget {
  const _ResultList({required this.vm});

  final SearchViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    String label(SearchTab t) => switch (t) {
      SearchTab.all => l.commonAll,
      SearchTab.opportunities => l.searchTypeOpportunities,
      SearchTab.events => l.searchTypeEvents,
      SearchTab.places => l.searchTypePlaces,
    };
    final tabs = SearchTab.values.where((t) => t == SearchTab.all || vm.countFor(t) > 0).toList();
    return ListView(
      padding: EdgeInsets.fromLTRB(0, 8, 0, 24 + MediaQuery.paddingOf(context).bottom),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        PillRow(
          children: [
            for (final t in tabs)
              FilterPill(label: l.searchTabCount(label(t), vm.countFor(t)), selected: vm.tab == t, onTap: () => vm.selectTab(t)),
          ],
        ),
        for (final g in vm.groups)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    trUpper(label(g.tab)),
                    style: AppTypography.body(13, weight: FontWeight.w900, color: p.mut).copyWith(letterSpacing: .6),
                  ),
                ),
                for (final item in g.items) ...[const SizedBox(height: 8), _ResultRow(item: item, vm: vm)],
              ],
            ),
          ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.item, required this.vm});

  final SearchResult item;
  final SearchViewModel vm;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (icon, tone, route) = switch (item.type) {
      SearchResultType.opportunity => (HomeIcons.tagPlain, p.tile1, Routes.opportunity(item.id)),
      SearchResultType.reward => (HomeIcons.tagPlain, p.tile1, Routes.reward(item.id)),
      SearchResultType.event => (AppIcons.calendar, p.tile2, Routes.event(item.id)),
      SearchResultType.place => (AppIcons.pin, p.tile3, Routes.place(item.id)),
    };
    return Semantics(
      button: true,
      label: '${item.title}, ${item.subtitle}',
      excludeSemantics: true,
      child: Material(
        color: p.sf,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Haptics.selection();
            vm.rememberQuery();
            context.push(route);
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                IconTile(icon: icon, color: tone, size: 48, radius: 14, iconSize: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(15, weight: FontWeight.w800, color: p.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.body(12, color: p.mut),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AppIcon(AppIcons.chevronRight, size: 18, color: p.mut, strokeWidth: 2.4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultsSkeleton extends StatelessWidget {
  const _ResultsSkeleton();

  @override
  Widget build(BuildContext context) => Shimmer(
    child: ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      children: [
        const Row(
          children: [SkeletonBox(width: 92, height: 40, radius: 20), SizedBox(width: 8), SkeletonBox(width: 110, height: 40, radius: 20)],
        ),
        const SizedBox(height: 22),
        const SkeletonBox(width: 90, height: 13, radius: 6),
        for (var i = 0; i < 4; i++) ...[const SizedBox(height: 8), const SkeletonBox(height: 68, radius: 18)],
      ],
    ),
  );
}
