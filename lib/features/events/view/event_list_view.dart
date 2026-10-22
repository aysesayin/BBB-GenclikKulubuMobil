import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/base/base_view.dart';
import '../../../core/di/locator.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/events/event_item.dart';
import '../../../data/repositories/event_repository.dart';
import '../../../l10n/l10n.dart';
import '../view_model/event_list_view_model.dart';
import '../widgets/day_strip.dart';
import '../widgets/event_card.dart';

/// G1 · Etkinlik listesi (Keşfet sekmesi içinde, alt navigasyon görünür).
class EventListView extends StatelessWidget {
  const EventListView({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => EventListViewModel(sl<EventRepository>())..load(),
        child: const _Body(),
      );
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.watch<EventListViewModel>();
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBackHeader(
            title: l.eventListTitle,
            titleSize: 28,
            onBack: () => context.canPop() ? context.pop() : context.go(Routes.home),
            trailing: [
              AppIconButton(
                icon: AppIcons.map,
                semanticLabel: l.eventShowOnMap,
                background: p.sf,
                onPressed: () => context.push(Routes.map),
              ),
            ],
          ),
          DayStrip(days: vm.days, isSelected: vm.isSelectedDay, hasEvents: vm.hasEventsOn, onPick: vm.selectDay),
          Expanded(
            child: RefreshIndicator(
              onRefresh: vm.refresh,
              color: p.teal,
              child: ViewStateBuilder<EventFeed>(
                state: vm.state,
                onRetry: vm.load,
                skeleton: (_) => const _ListSkeleton(),
                empty: (_) => EmptyState(title: l.eventEmptyTitle, message: l.eventEmptyMessage),
                builder: (context, _, {required offline}) => _Content(offline: offline),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.offline});

  final bool offline;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final vm = context.watch<EventListViewModel>();
    final events = vm.events;
    final bottom = AppSpacing.tabBarHeight + MediaQuery.paddingOf(context).bottom;
    return ListView(
      padding: EdgeInsets.only(bottom: bottom),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        if (offline) const OfflineBanner(margin: EdgeInsets.fromLTRB(20, 6, 20, 0)),
        Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 4),
          child: PillRow(
            children: [
              FilterPill(label: l.commonAll, selected: vm.categoryId == null, onTap: () => vm.selectCategory(null)),
              for (final c in vm.categories)
                FilterPill(label: c.label, selected: vm.categoryId == c.id, onTap: () => vm.selectCategory(c.id)),
            ],
          ),
        ),
        if (events.isEmpty)
          EmptyState(
            title: l.eventEmptyTitle,
            message: l.eventEmptyMessage,
            ctaLabel: vm.hasFilters ? l.eventEmptyCta : null,
            onCta: vm.hasFilters ? vm.clearFilters : null,
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              children: [
                for (var i = 0; i < events.length; i++) ...[
                  if (i > 0) const SizedBox(height: 14),
                  EventCard(event: events[i], onTap: () => context.push(Routes.event(events[i].id))),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) => Shimmer(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          children: [
            Row(children: [for (final w in [64.0, 72.0, 90.0]) ...[SkeletonBox(width: w, height: 40, radius: 20), const SizedBox(width: 8)]]),
            for (var i = 0; i < 3; i++) ...[
              const SizedBox(height: 14),
              const SkeletonBox(height: 110, radius: AppRadii.card),
              const SizedBox(height: 10),
              const SkeletonBox(width: 220, height: 18),
              const SizedBox(height: 8),
              const SkeletonBox(width: 160, height: 14),
              const SizedBox(height: 8),
              const SkeletonBox(height: 8, radius: 4),
            ],
          ],
        ),
      );
}
