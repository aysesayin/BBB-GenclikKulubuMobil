import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/ui_prefs_controller.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/services/sports.dart';
import '../../../../data/repositories/facility_repository.dart';
import '../../../../l10n/l10n.dart';
import '../../tennis/view_model/tennis_view_model.dart';
import '../../tennis/widgets/tennis_list.dart';
import '../../widgets/service_row_card.dart';
import '../../widgets/services_icons.dart';
import '../../widgets/svc_format.dart';
import '../../widgets/svc_navigation.dart';
import '../view_model/sports_school_view_model.dart';
import '../widgets/branch_card.dart';

/// H4 · Spor Okulları ve Tenis (Keşfet sekmesi içinde). Havuz akışıyla aynı:
/// branş → dönem → grup/seans → sepet.
class SportsSchoolView extends StatelessWidget {
  const SportsSchoolView({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SportsSchoolViewModel(sl<FacilityRepository>())..load()),
          ChangeNotifierProvider(lazy: false, create: (_) => TennisViewModel(sl<FacilityRepository>())..load()),
        ],
        child: const _Body(),
      );
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SportsSchoolViewModel>();
    final p = context.palette;
    final l = context.l10n;
    final easy = context.easyMode;
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBackHeader(title: l.svcSportsTitle),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: SegmentedTabs(labels: [l.svcSportsTabSchools, l.svcSportsTabTennis], index: vm.tab, onChanged: vm.setTab),
          ),
          Expanded(
            child: ViewStateBuilder<SportsCatalog>(
              state: vm.state,
              onRetry: vm.load,
              skeleton: (_) => const _Skeleton(),
              builder: (context, _, {required offline}) => ListView(
                padding: EdgeInsets.only(bottom: AppSpacing.tabBarHeight + MediaQuery.paddingOf(context).bottom),
                children: [
                  if (offline) const OfflineBanner(),
                  const SizedBox(height: 12),
                  PillRow(children: [
                    for (final t in vm.terms) FilterPill(label: t.label, selected: t.id == vm.termId, onTap: () => vm.selectTerm(t.id)),
                  ]),
                  const SizedBox(height: 8),
                  PillRow(children: [
                    for (final a in vm.ageGroups) FilterPill(label: a.label, selected: a.id == vm.ageGroupId, onTap: () => vm.selectAgeGroup(a.id)),
                  ]),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: vm.tab == 1
                        ? TennisList(ageGroupId: vm.ageGroupId)
                        : easy
                            ? _BranchRows(tiles: vm.branches)
                            : _BranchGrid(tiles: vm.branches),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchGrid extends StatelessWidget {
  const _BranchGrid({required this.tiles});

  final List<BranchTile> tiles;

  @override
  Widget build(BuildContext context) {
    if (tiles.isEmpty) {
      return SizedBox(height: 360, child: EmptyState(title: context.l10n.svcSportsEmptyTitle, message: context.l10n.svcSportsEmptyMessage));
    }
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 12.0;
        final w = (c.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final t in tiles)
              SizedBox(
                width: w,
                child: BranchCard(tile: t, onTap: t.offer == null ? null : () => openSessions(context, t.offer!.itemId)),
              ),
          ],
        );
      },
    );
  }
}

/// Kolay Mod: 3 sütunlu ızgara yerine 64 px karolu dikey satırlar.
class _BranchRows extends StatelessWidget {
  const _BranchRows({required this.tiles});

  final List<BranchTile> tiles;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (tiles.isEmpty) {
      return SizedBox(height: 360, child: EmptyState(title: context.l10n.svcSportsEmptyTitle, message: context.l10n.svcSportsEmptyMessage));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final t in tiles) ...[
          Builder(builder: (context) {
            final (quota, color) = BranchCard.quotaOf(context, t);
            return Opacity(
              opacity: t.offer == null ? .6 : 1,
              child: ServiceRowCard(
                icon: SvcIcons.of(t.branch.icon),
                tileColor: SvcFmt.tile(p, t.branch.tile),
                title: t.branch.name,
                subtitle: quota,
                semanticLabel: context.l10n.svcBranchSemantics(t.branch.name, quota),
                onTap: t.offer == null ? () {} : () => openSessions(context, t.offer!.itemId),
                trailing: Text(quota, style: AppTypography.body(13, weight: FontWeight.w900, color: color)),
              ),
            );
          }),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => Shimmer(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            children: [
              const Row(children: [SkeletonBox(width: 150, height: 40, radius: 20), SizedBox(width: 8), SkeletonBox(width: 150, height: 40, radius: 20)]),
              const SizedBox(height: 20),
              for (var r = 0; r < 3; r++) ...[
                const Row(children: [
                  Expanded(child: SkeletonBox(height: 120, radius: 22)),
                  SizedBox(width: 12),
                  Expanded(child: SkeletonBox(height: 120, radius: 22)),
                  SizedBox(width: 12),
                  Expanded(child: SkeletonBox(height: 120, radius: 22)),
                ]),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      );
}
