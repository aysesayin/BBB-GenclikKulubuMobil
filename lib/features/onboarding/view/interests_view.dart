import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/base/base_view.dart';
import '../../../core/di/locator.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/auth/interest_option.dart';
import '../../../data/repositories/interests_repository.dart';
import '../../../l10n/l10n.dart';
import '../view_model/interests_view_model.dart';
import '../widgets/bubble_field.dart';
import '../widgets/nav_x.dart';
import '../widgets/onb_icons.dart';
import '../widgets/poster_title.dart';

/// A4 · Baloncuk ilgi seçici. Ekran okuyucu açıkken baloncuklar yerine liste.
class InterestsView extends StatelessWidget {
  const InterestsView({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => InterestsViewModel(sl<InterestsRepository>())..load(),
        child: const _Body(),
      );
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final vm = context.watch<InterestsViewModel>();
    final pad = MediaQuery.paddingOf(context);
    const min = InterestsViewModel.minSelection;
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(12, pad.top + 4, 16, 0),
            child: Row(
              children: [
                AppIconButton(icon: AppIcons.back, semanticLabel: l.commonBack, iconSize: 24, onPressed: () => context.popOr(Routes.welcome)),
                const Spacer(),
                _Counter(count: vm.count, ok: vm.canContinue),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PosterTitle(lines: [l.onbInterestsLine1, l.onbInterestsLine2], size: 48, lineHeight: .95, from: const Offset(50, 0), stagger: Duration.zero),
                const SizedBox(height: 6),
                Text(l.onbInterestsSubtitle(min), style: AppTypography.body(15, weight: FontWeight.w800, color: p.mut)),
              ],
            ),
          ),
          Expanded(
            child: ViewStateBuilder<List<InterestOption>>(
              state: vm.state,
              onRetry: vm.load,
              skeleton: (_) => const _Skeleton(),
              builder: (context, options, {required offline}) => Column(
                children: [
                  if (offline) const OfflineBanner(),
                  Expanded(
                    child: Semantics(
                      container: true,
                      label: l.onbInterestsGroup,
                      child: MediaQuery.of(context).accessibleNavigation
                          ? _AccessibleList(options: options)
                          : Padding(
                              padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                              child: BubbleField(
                                options: options,
                                selected: vm.selected,
                                last: vm.lastSelected,
                                onToggle: vm.toggle,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(24, 8, 24, 40 + pad.bottom),
            child: AppButton(
              label: vm.canContinue ? l.commonContinue : l.onbInterestsCtaLocked(min),
              onPressed: vm.canContinue
                  ? () {
                      if (vm.submit()) context.push(Routes.register);
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({required this.count, required this.ok});

  final int count;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    const min = InterestsViewModel.minSelection;
    return Semantics(
      liveRegion: true,
      label: l.onbInterestsCountSemantics(count, min),
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: ok ? p.grn : p.sf2, borderRadius: BorderRadius.circular(18)),
        child: Text(
          ok ? l.onbInterestsSelected(count) : l.onbInterestsCount(count, min),
          style: AppTypography.number(15, color: ok ? p.onTile : p.ink),
        ),
      ),
    );
  }
}

/// Ekran okuyucu alternatifi: sıradan anahtarlı liste.
class _AccessibleList extends StatelessWidget {
  const _AccessibleList({required this.options});

  final List<InterestOption> options;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final vm = context.watch<InterestsViewModel>();
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      itemCount: options.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final o = options[i];
        final on = vm.isSelected(o.id);
        return Material(
          color: on ? p.tiles[(o.tile - 1).clamp(0, 5)] : p.sf,
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: CheckboxListTile(
            value: on,
            onChanged: (_) {
              Haptics.selection();
              vm.toggle(o.id);
            },
            secondary: AppIcon(OnbIcons.interest(o.icon), size: 24, color: on ? p.onTile : p.ink),
            title: Text(o.label, style: AppTypography.body(16, weight: FontWeight.w800, color: on ? p.onTile : p.ink)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
          ),
        );
      },
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => Shimmer(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Wrap(
            spacing: 18,
            runSpacing: 18,
            alignment: WrapAlignment.center,
            children: [for (final s in const [120.0, 100.0, 110.0, 130.0, 96.0, 116.0, 104.0]) SkeletonBox(width: s, height: s, circle: true)],
          ),
        ),
      );
}
