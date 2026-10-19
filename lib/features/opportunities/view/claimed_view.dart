import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/base/base_view.dart';
import '../../../core/di/locator.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/opportunities/claim.dart';
import '../../../data/repositories/opportunity_repository.dart';
import '../../../l10n/l10n.dart';
import '../../card_qr/utils/brightness_boost.dart';
import '../view_model/claimed_view_model.dart';
import '../widgets/claim_ticket.dart';
import '../widgets/opp_icons.dart';

/// Rota `extra`'sı: taze yakalamada [ClaimResult] doğrudan; cüzdan/detaydan
/// tekrar açılışta kutlamasız [ClaimedExtra].
class ClaimedExtra {
  const ClaimedExtra(this.claim, {this.fresh = false});
  final ClaimResult claim;
  final bool fresh;

  static ClaimedExtra? from(Object? extra) => switch (extra) {
    final ClaimedExtra e => e,
    final ClaimResult c => ClaimedExtra(c, fresh: true),
    _ => null,
  };
}

/// C3 · Fırsat yakalandı (`/firsat/:id/yakalandi`, sonuç `extra` ile).
class ClaimedView extends StatelessWidget {
  const ClaimedView({super.key, required this.id, this.extra});

  final String id;
  final ClaimedExtra? extra;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
    create: (_) => ClaimedViewModel(sl<OpportunityRepository>(), id, initial: extra?.claim, fresh: extra?.fresh ?? false)..load(),
    child: const _Body(),
  );
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final _boost = BrightnessBoost();
  bool _bright = false;
  bool _celebrated = false;

  @override
  void initState() {
    super.initState();
    _boost.enable().then((ok) {
      if (mounted) setState(() => _bright = ok);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _celebrate());
  }

  void _celebrate() {
    if (!mounted) return;
    final vm = context.read<ClaimedViewModel>();
    final claim = vm.state.dataOrNull;
    if (!vm.celebrate || _celebrated || claim == null) return;
    _celebrated = true;
    setState(() {});
    if (claim.buanReward > 0) {
      showRewardToast(context, label: context.l10n.oppClaimToast, amount: claim.buanReward, haptic: false);
    } else {
      Haptics.medium();
    }
  }

  @override
  void dispose() {
    _boost.restore();
    super.dispose();
  }

  void _copy(ClaimResult c) {
    unawaited(Clipboard.setData(ClipboardData(text: c.code ?? '')));
    Haptics.selection();
    context.read<ClaimedViewModel>().markCopied();
    SemanticsService.sendAnnouncement(View.of(context), context.l10n.commonCopied, Directionality.of(context));
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ClaimedViewModel>();
    final p = context.palette;
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 286 + top,
            child: _HeroArt(color: p.hotFill),
          ),
          Positioned.fill(
            child: Column(
              children: [
                SizedBox(height: top + 8),
                _TopBar(bright: _bright),
                Expanded(
                  child: ViewStateBuilder<ClaimResult>(
                    state: vm.state,
                    onRetry: vm.refresh,
                    skeleton: (_) => const Center(child: CircularProgressIndicator()),
                    builder: (context, c, {required offline}) => _Content(claim: c, copied: vm.copied, onCopy: () => _copy(c)),
                  ),
                ),
                const _Actions(),
              ],
            ),
          ),
          Positioned.fill(
            child: CelebrationOverlay(play: _celebrated, duration: const Duration(milliseconds: 1200)),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.claim, required this.copied, required this.onCopy});

  final ClaimResult claim;
  final bool copied;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l.oppClaimTitle,
              textAlign: TextAlign.center,
              style: AppTypography.display(34, height: 1, color: p.onTile),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.claimSubtitle(claim.type),
            textAlign: TextAlign.center,
            style: AppTypography.body(15, weight: FontWeight.w800, color: p.onTile),
          ),
          const SizedBox(height: 24),
          ClaimTicket(claim: claim, copied: copied, onCopy: onCopy),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.bright});

  final bool bright;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 16),
      child: Row(
        children: [
          AppIconButton(
            icon: AppIcons.close,
            semanticLabel: l.commonClose,
            background: p.paper.withValues(alpha: .9),
            color: p.onTile,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Spacer(),
          if (bright)
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: p.onTile.withValues(alpha: .85), borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(OppIcons.sun, size: 16, color: p.paper, strokeWidth: 2.4),
                  const SizedBox(width: 6),
                  Text(
                    l.oppBrightnessFull,
                    style: AppTypography.body(12, weight: FontWeight.w900, color: p.paper),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 16 + MediaQuery.paddingOf(context).bottom),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: l.oppMyOpportunities,
              variant: AppButtonVariant.outlineInk,
              onPressed: () => context.go(Routes.myOpportunities),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AppButton(label: l.commonDone, onPressed: () => context.go(Routes.opportunities)),
          ),
        ],
      ),
    );
  }
}

class _HeroArt extends StatelessWidget {
  const _HeroArt({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: color),
        SvgArt(
          '<svg viewBox="0 0 393 330" preserveAspectRatio="xMidYMid slice">'
          '<path d="M260 -40c100 0 170 70 150 170s-110 120-190 100-90-100-60-170 0-100 100-100z" fill="${p.cta.hex}" fill-opacity=".55"/>'
          '<path d="M-30 200c60-40 140-20 170 30s-20 120-90 110-140-100-80-140z" fill="${p.buanFill.hex}" fill-opacity=".35"/></svg>',
          fit: BoxFit.cover,
        ),
      ],
    );
  }
}
