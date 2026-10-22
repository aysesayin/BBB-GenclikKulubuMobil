import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/base/view_state.dart';
import '../../../core/di/locator.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ui_prefs_controller.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/card/digital_card.dart';
import '../../../data/repositories/card_repository.dart';
import '../../../l10n/l10n.dart';
import '../utils/brightness_boost.dart';
import '../view_model/card_view_model.dart';
import '../widgets/card_actions.dart';
import '../widgets/card_flip.dart';
import '../widgets/card_guest_wall.dart';
import '../widgets/card_qr_panel.dart';
import '../widgets/holo_card.dart';

/// D1 · Kartım sekmesi. Misafirde yumuşak duvar; üyede çevrilebilir kart + dinamik QR.
/// Kolay Mod: 56 px kod, tam genişlik alt alta butonlar.
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
  bool _flipped = false;

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
    final easy = context.easyMode;
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
              trailing: [if (_bright) BrightChip(label: l.cardBrightnessUp)],
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
                _ => FlipCard(
                  flipped: _flipped,
                  onTap: () => setState(() => _flipped = !_flipped),
                  front: HoloCard(
                    live: vm.active && !_flipped,
                    name: card.fullName,
                    memberNo: card.memberNo,
                    levelLabel: l.cardLevelBadge(card.level, card.levelName),
                    semanticLabel: l.cardSemantics(card.fullName, card.memberNo, card.levelName),
                  ),
                  back: CardBackFace(token: vm.token?.token, pin: vm.pin, secondsLeft: vm.secondsLeft, ring: vm.ringValue),
                ),
              },
            ),
            if (card != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l.cardFlipHint,
                  textAlign: TextAlign.center,
                  style: AppTypography.body(12, weight: FontWeight.w800, color: p.mut),
                ),
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
                large: easy,
                onRetry: vm.refreshToken,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: CardActions(),
            ),
          ],
        ),
      ),
    );
  }
}
