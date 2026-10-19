import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/base/base_view.dart';
import '../../../core/di/locator.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_result.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/opportunities/opportunity.dart';
import '../../../data/repositories/opportunity_repository.dart';
import '../../../l10n/l10n.dart';
import '../view_model/opportunity_detail_view_model.dart';
import '../widgets/detail_accordion.dart';
import '../widgets/detail_banner.dart';
import '../widgets/detail_branch.dart';
import '../widgets/detail_sections.dart';
import 'claimed_view.dart';

/// C2 · Fırsat detayı (`/firsat/:id`).
class OpportunityDetailView extends StatelessWidget {
  const OpportunityDetailView({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider(create: (_) => OpportunityDetailViewModel(sl<OpportunityRepository>(), id)..load(), child: const _Body());
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OpportunityDetailViewModel>();
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.sf,
      body: Stack(
        children: [
          Positioned.fill(
            child: ViewStateBuilder<OpportunityDetail>(
              state: vm.state,
              onRetry: vm.refresh,
              skeleton: (_) => const _Skeleton(),
              builder: (context, d, {required offline}) => Column(
                children: [
                  Expanded(
                    child: _Content(detail: d, offline: offline),
                  ),
                  const _CtaBar(),
                ],
              ),
            ),
          ),
          // Yükleme / hata sırasında da geri dönülebilsin.
          if (vm.detail == null)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 12,
              child: AppIconButton(
                icon: AppIcons.back,
                semanticLabel: context.l10n.commonBack,
                background: p.sf,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.detail, required this.offline});

  final OpportunityDetail detail;
  final bool offline;

  Future<void> _favorite(BuildContext context) async {
    final error = await context.read<OpportunityDetailViewModel>().toggleFavorite();
    if (error != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessageOf(context, error))));
    }
  }

  void _share(BuildContext context) {
    final s = detail.summary;
    final link = '${ApiConfig.deepLinkBase}${Routes.opportunity(s.id)}';
    SharePlus.instance.share(ShareParams(text: context.l10n.oppShareText(s.brand, s.title, link), subject: s.title));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OpportunityDetailViewModel>();
    final p = context.palette;
    final l = context.l10n;
    final s = detail.summary;
    final sections = <(String, List<String>)>[
      if (detail.conditions.isNotEmpty) (l.oppConditions, detail.conditions),
      if (detail.validity.isNotEmpty) (l.oppValidity, detail.validity),
      if (detail.minAge != null && detail.maxAge != null)
        (l.oppAgeLimit, [l.oppAgeMembers(detail.minAge!, detail.maxAge!), ?detail.ineligibleReason]),
    ];
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DetailBanner(
            tone: s.tone,
            imageUrl: detail.bannerUrl,
            isFavorite: vm.isFavorite,
            onFavorite: () => _favorite(context),
            onShare: () => _share(context),
          ),
          Transform.translate(
            offset: const Offset(0, -28),
            child: Container(
              decoration: BoxDecoration(
                color: p.sf,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadii.xl)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 40,
                    child: OverflowBox(
                      alignment: Alignment.bottomCenter,
                      maxHeight: 120,
                      child: DetailBrandRow(detail: detail),
                    ),
                  ),
                  if (offline) const OfflineBanner(margin: EdgeInsets.only(top: 16)),
                  const SizedBox(height: 16),
                  Semantics(
                    header: true,
                    child: Text(s.title, style: AppTypography.display(27, color: p.ink)),
                  ),
                  const SizedBox(height: 16),
                  DetailInfoChips(detail: detail, daysLeft: vm.daysLeft(), urgent: vm.endingSoon),
                  if (s.stockTotal > 0) ...[const SizedBox(height: 16), DetailStockBox(deal: s)],
                  if (detail.steps.isNotEmpty) ...[const SizedBox(height: 16), DetailSteps(steps: detail.steps)],
                  if (sections.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    DetailAccordion(sections: sections, expanded: vm.expanded, onToggle: vm.toggleSection),
                  ],
                  if (detail.branch case final b?) ...[const SizedBox(height: 16), DetailBranch(branch: b)],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Yapışkan "Fırsatı Yakala" alanı. Misafirde S2 yumuşak duvarı açılır.
class _CtaBar extends StatelessWidget {
  const _CtaBar();

  Future<void> _claim(BuildContext context) async {
    final vm = context.read<OpportunityDetailViewModel>();
    final r = await vm.claimNow();
    if (!context.mounted) return;
    switch (r) {
      case Success(:final data):
        context.push(Routes.opportunityClaimed(vm.id), extra: data);
      case Failure(:final error):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessageOf(context, error))));
        // Stok bitti / yaş kuralı değişti olabilir → güncel durumu çek.
        if (error is ConflictException || error is ForbiddenException) vm.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OpportunityDetailViewModel>();
    final p = context.palette;
    final l = context.l10n;
    final d = vm.detail;
    final cta = vm.cta;
    final reason = switch (cta) {
      ClaimCta.ineligible =>
        d?.ineligibleReason ?? (d?.minAge != null && d?.maxAge != null ? l.ageLocked(d!.minAge!, d.maxAge!) : l.errorForbidden),
      _ => null,
    };
    final label = switch (cta) {
      ClaimCta.available || ClaimCta.ineligible => l.oppClaimCta,
      ClaimCta.claimed => l.oppShowMyCode,
      ClaimCta.soldOut => l.oppSoldOut,
      ClaimCta.expired => l.oppExpired,
    };
    final VoidCallback? onPressed = switch (cta) {
      ClaimCta.available => () => AuthGate.guard(context, () => _claim(context)),
      ClaimCta.claimed => () => context.push(Routes.opportunityClaimed(vm.id), extra: vm.claim == null ? null : ClaimedExtra(vm.claim!)),
      _ => null,
    };
    return StickyBottomBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (reason != null) ...[
            Semantics(
              liveRegion: true,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppIcon(AppIcons.lock, size: 16, color: p.mut, strokeWidth: 2.4),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      reason,
                      textAlign: TextAlign.center,
                      style: AppTypography.body(13, weight: FontWeight.w800, color: p.mut),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
          AppButton(label: label, busy: vm.claiming, onPressed: onPressed, semanticLabel: reason == null ? null : '$label, $reason'),
        ],
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => Shimmer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(builder: (_, c) => SkeletonBox(height: c.maxWidth / 1.75, radius: 0)),
        const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(width: 64, height: 64, radius: 20),
              SizedBox(height: 16),
              SkeletonBox(height: 28),
              SizedBox(height: 10),
              SkeletonBox(width: 220, height: 28),
              SizedBox(height: 16),
              SkeletonBox(height: 90, radius: 20),
            ],
          ),
        ),
      ],
    ),
  );
}
