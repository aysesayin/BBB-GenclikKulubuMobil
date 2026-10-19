import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/base/view_state.dart';
import '../../../core/di/locator.dart';
import '../../../core/router/routes.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/card/digital_card.dart';
import '../../../data/repositories/card_repository.dart';
import '../../../l10n/l10n.dart';
import '../utils/brightness_boost.dart';
import '../view_model/card_view_model.dart';
import '../widgets/card_guest_wall.dart';
import '../widgets/card_icons.dart';
import '../widgets/card_qr_panel.dart';
import '../widgets/holo_card.dart';

/// D1 · Kartım sekmesi. Misafirde yumuşak duvar; üyede kart + dinamik QR.
class CardView extends StatelessWidget {
  const CardView({super.key});

  @override
  Widget build(BuildContext context) {
    final member = context.select<SessionController, bool>((s) => s.isAuthenticated);
    if (!member) return const CardGuestWall();
    return ChangeNotifierProvider(create: (_) => CardViewModel(sl<CardRepository>())..load(), child: const _Body());
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> with WidgetsBindingObserver {
  final _boost = BrightnessBoost();
  bool _visible = false;
  bool _bright = false;
  bool _resumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sekme kabuğu gizli dalları TickerMode(false) ile sarar → görünürlük.
    _visible = TickerMode.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sync();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _sync();
  }

  Future<void> _sync() async {
    final on = _visible && _resumed;
    context.read<CardViewModel>().setActive(on);
    if (on) {
      final ok = await _boost.enable();
      if (mounted && ok != _bright) setState(() => _bright = ok);
    } else {
      await _boost.restore();
      if (mounted && _bright) setState(() => _bright = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _boost.restore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<CardViewModel>();
    final p = context.palette;
    final l = context.l10n;
    final bottom = AppSpacing.tabBarHeight + MediaQuery.paddingOf(context).bottom;
    final card = vm.card.dataOrNull;
    final cardOffline = vm.card is ViewError || (vm.card is ViewSuccess<DigitalCard> && (vm.card as ViewSuccess<DigitalCard>).fromCache);
    return Scaffold(
      backgroundColor: p.bg,
      body: RefreshIndicator(
        color: p.teal,
        onRefresh: vm.refresh,
        child: ListView(
          padding: EdgeInsets.only(bottom: bottom + 24),
          children: [
            TabScreenHeader(
              title: l.tabCard,
              trailing: [if (_bright) _BrightChip(label: l.cardBrightnessUp)],
            ),
            if (vm.offline || cardOffline) const OfflineBanner(margin: EdgeInsets.fromLTRB(20, 12, 20, 0)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: switch (vm.card) {
                ViewError(:final error, cached: null) => SizedBox(
                  height: 260,
                  child: ErrorStateView(error: error, onRetry: vm.refresh),
                ),
                _ when card == null => const Shimmer(
                  child: AspectRatio(aspectRatio: 1 / .595, child: SkeletonBox(radius: 26)),
                ),
                _ => HoloCard(
                  live: vm.active,
                  name: card.fullName,
                  memberNo: card.memberNo,
                  levelLabel: l.cardLevelBadge(card.level, card.levelName),
                  semanticLabel: l.cardSemantics(card.fullName, card.memberNo, card.levelName),
                ),
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: CardQrPanel(
                token: vm.token?.token,
                pin: vm.pin,
                secondsLeft: vm.secondsLeft,
                ring: vm.ringValue,
                offline: vm.offline,
                loading: vm.tokenLoading,
                onRetry: vm.refreshToken,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    flex: 12,
                    child: AppButton.buan(label: l.cardScanCta, icon: CardIcons.scan, fontSize: 16, onPressed: () => context.push(Routes.qrScan)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 10,
                    child: AppButton(
                      label: l.cardAddToWallet,
                      icon: AppIcons.wallet,
                      variant: AppButtonVariant.outlineInk,
                      fontSize: 15,
                      // TODO(varsayım): Apple/Google Wallet pass'i backend'den (.pkpass / JWT) gelecek; şimdilik bilgi notu.
                      onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.cardWalletSoon))),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrightChip extends StatelessWidget {
  const _BrightChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: p.sf2, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(CardIcons.sun, size: 16, color: p.mut, strokeWidth: 2.4),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTypography.body(12, weight: FontWeight.w900, color: p.mut),
          ),
        ],
      ),
    );
  }
}
