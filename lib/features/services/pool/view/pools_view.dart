import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/services/facility.dart';
import '../../../../data/repositories/facility_repository.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/service_row_card.dart';
import '../../widgets/services_icons.dart';
import '../../widgets/svc_format.dart';
import '../../widgets/svc_navigation.dart';
import '../view_model/pools_view_model.dart';
import '../widgets/pool_picker.dart';

/// H1 · Havuzlar (Keşfet sekmesi içinde).
class PoolsView extends StatelessWidget {
  const PoolsView({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => PoolsViewModel(sl<FacilityRepository>())..load(),
        child: const _Body(),
      );
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PoolsViewModel>();
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBackHeader(title: context.l10n.svcPoolsTitle, titleSize: 28),
          Expanded(
            child: ViewStateBuilder<PoolCatalog>(
              state: vm.state,
              onRetry: vm.load,
              skeleton: (_) => const _PoolsSkeleton(),
              builder: (context, catalog, {required offline}) => RefreshIndicator(
                onRefresh: vm.load,
                child: ListView(
                  padding: EdgeInsets.only(bottom: AppSpacing.tabBarHeight + MediaQuery.paddingOf(context).bottom),
                  children: [
                    if (offline) const OfflineBanner(),
                    PoolPicker(pools: catalog.items, selectedId: vm.selectedId, onSelect: vm.select),
                    _RulesNote(rules: catalog.ageRules, swim: catalog.dailySwimConfirmation),
                    _ServicesSection(vm: vm),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RulesNote extends StatelessWidget {
  const _RulesNote({required this.rules, required this.swim});

  final AgeRules rules;
  final bool swim;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final text = [
      l.svcPoolRulesNote('${rules.minAge}', '${rules.guardianUntil}', '${rules.guardianUntil + 1}', '${rules.permissionUntil}'),
      if (swim) l.svcPoolSwimNote,
    ].join(' ');
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 2, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: p.tealS, borderRadius: BorderRadius.circular(18)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(SvcIcons.alert, size: 20, color: p.teal, strokeWidth: 2.4),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTypography.body(13, color: p.ink, height: 1.45))),
        ],
      ),
    );
  }
}

class _ServicesSection extends StatelessWidget {
  const _ServicesSection({required this.vm});

  final PoolsViewModel vm;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final pool = vm.selectedPool;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pool != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Semantics(
                header: true,
                child: Text(l.svcPoolServicesTitle(pool.name), style: AppTypography.display(20, color: p.ink)),
              ),
            ),
          ViewStateBuilder<List<ServiceItem>>(
            state: vm.items,
            onRetry: vm.loadItems,
            skeleton: (_) => const _RowsSkeleton(),
            empty: (_) => SizedBox(height: 360, child: EmptyState(title: l.svcPoolsEmptyTitle, message: l.svcPoolsEmptyMessage)),
            builder: (context, items, {required offline}) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in items) ...[_ItemRow(item: item), const SizedBox(height: 10)],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final ServiceItem item;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final unit = SvcFmt.unit(context, item.priceUnit);
    final price = SvcFmt.price(context, item.price);
    return ServiceRowCard(
      icon: SvcIcons.of(item.icon),
      tileColor: SvcFmt.tile(p, item.tile),
      title: item.title,
      tags: item.tags,
      semanticLabel: [item.title, ...item.tags, if (!item.isFree) unit, price].join(', '),
      onTap: () => openSessions(context, item.id),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!item.isFree && unit.isNotEmpty) Text(unit, style: AppTypography.body(11, weight: FontWeight.w800, color: p.mut)),
          Text(price, maxLines: 1, softWrap: false, style: AppTypography.number(16, color: p.ink)),
        ],
      ),
    );
  }
}

class _PoolsSkeleton extends StatelessWidget {
  const _PoolsSkeleton();

  @override
  Widget build(BuildContext context) => Shimmer(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          children: [
            const Row(children: [
              Expanded(child: SkeletonBox(height: 130, radius: 22)),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(height: 130, radius: 22)),
            ]),
            const SizedBox(height: 14),
            const SkeletonBox(height: 64, radius: 18),
            const SizedBox(height: 20),
            const _RowsSkeleton(),
          ],
        ),
      );
}

class _RowsSkeleton extends StatelessWidget {
  const _RowsSkeleton();

  @override
  Widget build(BuildContext context) => Shimmer(
        child: Column(
          children: [for (var i = 0; i < 4; i++) const Padding(padding: EdgeInsets.only(bottom: 10), child: SkeletonBox(height: 72, radius: 20))],
        ),
      );
}
