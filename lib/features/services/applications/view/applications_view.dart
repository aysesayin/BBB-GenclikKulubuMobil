import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/base/base_view.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/services/application.dart';
import '../../../../data/repositories/application_repository.dart';
import '../../../../l10n/l10n.dart';
import '../view_model/applications_view_model.dart';
import '../widgets/application_card.dart';

/// H5 · Başvurularım (Profil sekmesi içinde).
class ApplicationsView extends StatelessWidget {
  const ApplicationsView({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => ApplicationsViewModel(sl<ApplicationRepository>())..load(),
        child: const _Body(),
      );
}

class _Body extends StatelessWidget {
  const _Body();

  Future<void> _cancel(BuildContext context, ApplicationsViewModel vm, Application app) async {
    final ok = await AppSheet.show<bool>(context, builder: (ctx) => _CancelConfirm(title: app.title));
    if (ok != true || !context.mounted) return;
    final error = await vm.cancel(app.id);
    if (!context.mounted) return;
    final l = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error == null ? l.svcCancelDone : errorMessageOf(context, error))));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ApplicationsViewModel>();
    final p = context.palette;
    final l = context.l10n;
    final active = vm.tab == ApplicationsTab.active;
    return Scaffold(
      backgroundColor: p.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppBackHeader(title: l.svcAppsTitle),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: SegmentedTabs(
              labels: [l.svcAppsTabActive('${vm.activeCount}'), l.svcAppsTabPast],
              index: vm.tab.index,
              onChanged: (i) => vm.setTab(ApplicationsTab.values[i]),
            ),
          ),
          Expanded(
            child: ViewStateBuilder<List<Application>>(
              state: vm.state,
              onRetry: vm.load,
              skeleton: (_) => const _Skeleton(),
              empty: (_) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.tabBarHeight),
                child: EmptyState(
                  title: active ? l.svcAppsEmptyActiveTitle : l.svcAppsEmptyPastTitle,
                  message: active ? l.svcAppsEmptyActiveMessage : l.svcAppsEmptyPastMessage,
                  ctaLabel: active ? l.svcBrowsePools : null,
                  onCta: active ? () => context.go(Routes.pools) : null,
                ),
              ),
              builder: (context, _, {required offline}) => RefreshIndicator(
                onRefresh: vm.load,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + AppSpacing.tabBarHeight + MediaQuery.paddingOf(context).bottom),
                  children: [
                    if (offline) const OfflineBanner(margin: EdgeInsets.only(bottom: 12)),
                    for (final a in vm.visible) ...[
                      ApplicationCard(app: a, vm: vm, onCancel: () => _cancel(context, vm, a)),
                      const SizedBox(height: 14),
                    ],
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

class _CancelConfirm extends StatelessWidget {
  const _CancelConfirm({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(l.svcCancelConfirmTitle, style: AppTypography.display(24, color: p.ink))),
        const SizedBox(height: 10),
        Text(l.svcCancelConfirmBody(title), style: AppTypography.body(15, color: p.mut, height: 1.4)),
        const SizedBox(height: 20),
        AppButton(label: l.svcCancelConfirmYes, onPressed: () => Navigator.of(context).pop(true)),
        const SizedBox(height: 8),
        AppButton.text(label: l.svcCancelKeep, onPressed: () => Navigator.of(context).pop(false)),
      ],
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => Shimmer(
        child: ListView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          children: [for (var i = 0; i < 3; i++) const Padding(padding: EdgeInsets.only(bottom: 14), child: SkeletonBox(height: 150, radius: 24))],
        ),
      );
}
