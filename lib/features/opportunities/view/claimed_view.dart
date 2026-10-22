import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/base/base_view.dart';
import '../../../core/di/locator.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/opportunities/claim.dart';
import '../../../data/repositories/opportunity_repository.dart';
import '../../../l10n/l10n.dart';
import '../../card_qr/utils/keep_awake.dart';
import '../view_model/claimed_view_model.dart';
import '../widgets/claim_ticket.dart';
import '../widgets/claimed_parts.dart';
import '../widgets/rating_sheet.dart';

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
/// Kod gösterilirken ekran uyanık tutulur ([KeepAwake]); kod kullanılınca puanlama açılır.
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
  final _awake = KeepAwake();
  bool _bright = false;
  bool _celebrated = false;

  @override
  void initState() {
    super.initState();
    _awake.enable().then((ok) {
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
    _awake.disable();
    super.dispose();
  }

  void _copy(ClaimResult c) {
    unawaited(Clipboard.setData(ClipboardData(text: c.code ?? '')));
    Haptics.selection();
    context.read<ClaimedViewModel>().markCopied();
    SemanticsService.sendAnnouncement(View.of(context), context.l10n.commonCopied, Directionality.of(context));
  }

  /// Demo: "Kullandım" → cüzdan durumu `used` → puanlama sayfası → "Fırsat Kullan Kazan" toast'ı.
  Future<void> _markUsed() async {
    final vm = context.read<ClaimedViewModel>();
    vm.markUsed();
    Haptics.medium();
    if (!vm.takeRatingPrompt()) return;
    final result = await RatingSheet.show(context, opportunityId: vm.opportunityId);
    if (!mounted || result == null) return;
    showRewardToast(context, label: result.label ?? context.l10n.oppRatingToast, amount: result.buanReward);
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
            child: ClaimedHeroArt(color: p.hotFill),
          ),
          Positioned.fill(
            child: Column(
              children: [
                SizedBox(height: top + 8),
                ClaimedTopBar(bright: _bright),
                Expanded(
                  child: ViewStateBuilder<ClaimResult>(
                    state: vm.state,
                    onRetry: vm.refresh,
                    skeleton: (_) => const Center(child: CircularProgressIndicator()),
                    builder: (context, c, {required offline}) => _Content(claim: c, copied: vm.copied, onCopy: () => _copy(c)),
                  ),
                ),
                if (vm.state.dataOrNull != null) const KeepAwakeHint(),
                ClaimedActions(used: vm.used, onMarkUsed: ApiConfig.useMock && vm.state.dataOrNull != null ? _markUsed : null),
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
