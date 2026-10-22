import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/ui_prefs_controller.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/services/session.dart';
import '../../../../data/repositories/cart_repository.dart';
import '../../../../data/repositories/facility_repository.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/services_icons.dart';
import '../../widgets/svc_format.dart';
import '../view_model/session_view_model.dart';
import '../widgets/session_bottom_bar.dart';
import '../widgets/session_day_pager.dart';
import '../widgets/session_grid.dart';

/// H2 · Seans takvimi (tam ekran): `/seans/:itemId`.
class SessionView extends StatelessWidget {
  const SessionView({super.key, required this.itemId});

  final String itemId;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => SessionViewModel(sl<FacilityRepository>(), sl<CartRepository>(), itemId: itemId)..load(),
        child: const _Body(),
      );
}

class _Body extends StatelessWidget {
  const _Body();

  Future<void> _add(BuildContext context, SessionViewModel vm) => AuthGate.guard(context, () async {
        final ok = await vm.addToCart();
        if (!context.mounted) return;
        if (ok) {
          context.push(Routes.cart);
        } else if (vm.takeError() case final e?) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessageOf(context, e))));
        }
      });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SessionViewModel>();
    final p = context.palette;
    final easy = context.easyMode;
    final week = vm.state.dataOrNull;
    return Scaffold(
      backgroundColor: p.bg,
      bottomNavigationBar: week == null ? null : SessionBottomBar(vm: vm, onAdd: () => _add(context, vm)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(title: week?.title ?? '', subtitle: week?.facilityName ?? ''),
          Expanded(
            child: ViewStateBuilder<SessionWeek>(
              state: vm.state,
              onRetry: vm.load,
              skeleton: (_) => const _GridSkeleton(),
              builder: (context, data, {required offline}) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (offline) const OfflineBanner(),
                  if (vm.participants.length > 1) _WhoTabs(vm: vm),
                  if (!easy) _WeekNav(vm: vm),
                  const _Legend(),
                  Expanded(
                    child: easy
                        ? SessionDayPager(vm: vm)
                        : vm.rowMinutes.isEmpty
                            ? EmptyState(title: context.l10n.svcNoSessionsTitle, message: context.l10n.svcNoSessionsMessage)
                            : SessionGrid(vm: vm),
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

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.subtitle});

  final String title, subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.fromLTRB(8, MediaQuery.paddingOf(context).top + 8, 16, 0),
      child: Row(
        children: [
          AppIconButton(icon: AppIcons.back, iconSize: 24, semanticLabel: context.l10n.commonBack, onPressed: () => Navigator.of(context).maybePop()),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(header: true, child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.display(22, color: p.ink))),
                if (subtitle.isNotEmpty) Text(subtitle, style: AppTypography.body(13, weight: FontWeight.w800, color: p.mut)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WhoTabs extends StatelessWidget {
  const _WhoTabs({required this.vm});

  final SessionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final list = vm.participants;
    final index = list.indexWhere((x) => x.id == vm.participant?.id);
    return Semantics(
      label: l.svcWhoLabel,
      container: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: SegmentedTabs(
          labels: [for (final x in list) x.relation == Relation.child ? l.svcWhoChild(x.name, '${x.age}') : l.svcWhoSelf],
          index: index < 0 ? 0 : index,
          onChanged: (i) => vm.selectParticipant(list[i].id),
        ),
      ),
    );
  }
}

class _WeekNav extends StatelessWidget {
  const _WeekNav({required this.vm});

  final SessionViewModel vm;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(SvcFmt.weekRange(context, vm.weekStart, vm.weekEnd), style: AppTypography.body(15, weight: FontWeight.w900, color: p.ink)),
          ),
          AppIconButton(
            icon: SvcIcons.chevronLeft,
            semanticLabel: l.svcWeekPrev,
            background: p.sf,
            iconSize: 20,
            color: vm.canGoPrev ? p.ink : p.line,
            onPressed: vm.canGoPrev ? vm.prevWeek : null,
          ),
          const SizedBox(width: 4),
          AppIconButton(icon: AppIcons.chevronRight, semanticLabel: l.svcWeekNext, background: p.sf, iconSize: 20, onPressed: vm.nextWeek),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    Widget item(Color fill, String text, {Color? border}) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(4),
                border: border == null ? null : Border.all(color: border, width: 2),
              ),
            ),
            const SizedBox(width: 4),
            Text(text, style: AppTypography.body(11, weight: FontWeight.w900, color: p.mut)),
          ],
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: [
          item(p.tealS, l.svcLegendToday, border: p.teal),
          item(p.pinkS, l.svcLegendFull),
          item(p.sf, l.svcLegendIneligible, border: p.line),
          item(p.yelS, l.svcLegendHoliday),
          item(p.sf2, l.svcLegendClosed),
        ],
      ),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) => const Shimmer(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            children: [
              SkeletonBox(height: 50, radius: 18),
              SizedBox(height: 16),
              SkeletonBox(height: 20, width: 140),
              SizedBox(height: 16),
              Expanded(child: SkeletonBox(radius: 14, height: double.infinity)),
            ],
          ),
        ),
      );
}
