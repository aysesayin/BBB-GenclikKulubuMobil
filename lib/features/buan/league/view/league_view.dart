import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/buan/buan_league.dart';
import '../../../../data/repositories/buan_repository.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/buan_icons.dart';
import '../../widgets/buan_skeleton.dart';
import '../view_model/league_view_model.dart';
import '../widgets/league_widgets.dart';
import '../widgets/season_countdown.dart';

/// E4 · Haftalık Lig.
class LeagueView extends StatelessWidget {
  const LeagueView({super.key});

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider(create: (_) => LeagueViewModel(sl<BuanRepository>())..load(), child: const _Body());
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LeagueViewModel>();
    final l = context.l10n;
    final p = context.palette;
    final data = vm.state.dataOrNull;
    final me = vm.me;
    final tabBar = AppSpacing.tabBarHeight + MediaQuery.paddingOf(context).bottom;
    const scopes = BuanLeagueScope.values;
    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          Column(
            children: [
              AppBackHeader(
                title: l.buanLeagueTitle,
                trailing: [if (data != null) SeasonCountdown(endsAt: data.seasonEndsAt)],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: SegmentedTabs(
                  labels: [l.buanLeagueScopeGlobal, l.buanLeagueScopeDistrict, l.buanLeagueScopeFriends],
                  index: scopes.indexOf(vm.scope),
                  onChanged: (i) => vm.setScope(scopes[i]),
                ),
              ),
              if (vm.scope == BuanLeagueScope.district && data != null && data.districts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _DistrictButton(vm: vm, districts: data.districts),
                  ),
                ),
              Expanded(
                child: ViewStateBuilder<BuanLeague>(
                  state: vm.state,
                  onRetry: vm.load,
                  skeleton: (_) =>
                      MediaQuery.removePadding(context: context, removeTop: true, child: const BuanSkeleton(rows: 7, rowHeight: 52)),
                  builder: (context, league, {required offline}) =>
                      _Content(league: league, offline: offline, bottom: tabBar + (me != null ? 72 : 16)),
                ),
              ),
            ],
          ),
          if (me != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: tabBar + 8,
              child: LeagueMeBar(
                me: me,
                subtitle: vm.scope != BuanLeagueScope.global
                    ? null
                    : vm.inPromotion
                    ? l.buanLeagueInPromotion
                    : (data?.pointsToPromotion != null ? l.buanLeagueToPromotion(Fmt.number(data!.pointsToPromotion!)) : null),
              ),
            ),
        ],
      ),
    );
  }
}

class _DistrictButton extends StatelessWidget {
  const _DistrictButton({required this.vm, required this.districts});

  final LeagueViewModel vm;
  final List<BuanDistrict> districts;

  Future<void> _pick(BuildContext context) async {
    final id = await AppSheet.show<String>(
      context,
      builder: (ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(ctx.l10n.buanLeagueDistrictPick, style: AppTypography.display(24, color: ctx.palette.ink)),
          ),
          const SizedBox(height: 8),
          for (final d in districts)
            ListTile(
              contentPadding: EdgeInsets.zero,
              minTileHeight: 48,
              title: Text(
                d.name,
                style: AppTypography.body(15, weight: FontWeight.w800, color: ctx.palette.ink),
              ),
              trailing: d.id == vm.districtId ? AppIcon(AppIcons.check, size: 20, color: ctx.palette.teal, strokeWidth: 2.6) : null,
              selected: d.id == vm.districtId,
              onTap: () {
                Haptics.selection();
                Navigator.of(ctx).pop(d.id);
              },
            ),
        ],
      ),
    );
    if (id != null) await vm.setDistrict(id);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return Semantics(
      button: true,
      label: '${l.buanLeagueDistrictPick}: ${vm.districtName ?? ''}',
      excludeSemantics: true,
      child: Material(
        color: p.sf,
        shape: StadiumBorder(side: BorderSide(color: p.line, width: 1.5)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => _pick(context),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  vm.districtName ?? l.buanLeagueDistrictPick,
                  style: AppTypography.body(14, weight: FontWeight.w900, color: p.ink),
                ),
                const SizedBox(width: 6),
                Text(l.buanLeagueDistrictCount(districts.length), style: AppTypography.body(14, color: p.mut)),
                const SizedBox(width: 8),
                AppIcon(AppIcons.chevronDown, size: 16, color: p.ink, strokeWidth: 2.6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.league, required this.offline, required this.bottom});

  final BuanLeague league;
  final bool offline;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<LeagueViewModel>();
    final p = context.palette;
    final l = context.l10n;
    final rest = vm.rest;
    final rules = league.promoteTo != null && league.relegateTo != null
        ? l.buanLeagueRules(league.tierName, league.promoteCount, league.promoteTo!, league.relegateCount, league.relegateTo!)
        : l.buanLeagueTierOnly(league.tierName);
    if (league.entries.isEmpty) {
      return EmptyState(title: l.buanLeagueEmptyTitle, message: l.buanLeagueEmptyMessage);
    }
    return RefreshIndicator(
      onRefresh: vm.refresh,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (offline) const OfflineBanner(margin: EdgeInsets.fromLTRB(20, 12, 20, 0)),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(color: p.sf, borderRadius: BorderRadius.circular(AppRadii.md)),
            child: Row(
              children: [
                IconTile(icon: BuanIcons.trophy, color: p.tile3, size: 34, radius: 12, iconSize: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    rules,
                    style: AppTypography.body(13, weight: FontWeight.w800, color: p.ink),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: LeaguePodium(top: vm.podium),
          ),
          Container(
            constraints: BoxConstraints(minHeight: rest.isEmpty ? 0 : 120),
            padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottom),
            decoration: BoxDecoration(
              color: p.sf,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.card)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < rest.length; i++) ...[
                  if (vm.zoneHeaderBefore(i) case final z?) LeagueZoneHeader(zone: z),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: LeagueRow(entry: rest[i]),
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
