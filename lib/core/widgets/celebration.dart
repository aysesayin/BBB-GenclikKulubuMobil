import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/haptics.dart';
import 'buan_widgets.dart';

/// Kazanım toast'ı: "Fırsat kullandın  +100". Alttan 240 ms easeOutBack girer,
/// 2,5 sn kalır; mediumImpact haptik; ekran okuyucuya duyurulur.
void showRewardToast(BuildContext context, {required String label, required int amount, bool haptic = true}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  if (haptic) Haptics.medium();
  final text = context.l10n.rewardToastSemantics(label, Fmt.number(amount));
  SemanticsService.sendAnnouncement(View.of(context), text, Directionality.of(context));
  late OverlayEntry entry;
  entry = OverlayEntry(builder: (_) => _RewardToast(label: label, amount: amount, onDone: () => entry.remove()));
  overlay.insert(entry);
}

class _RewardToast extends StatefulWidget {
  const _RewardToast({required this.label, required this.amount, required this.onDone});

  final String label;
  final int amount;
  final VoidCallback onDone;

  @override
  State<_RewardToast> createState() => _RewardToastState();
}

class _RewardToastState extends State<_RewardToast> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: AppDurations.toastIn);

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await _c.forward();
    await Future<void>.delayed(AppDurations.toastStay);
    if (!mounted) return;
    await _c.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bottom = MediaQuery.paddingOf(context).bottom + AppSpacing.tabBarHeight + 12;
    return Positioned(
      left: 16,
      right: 16,
      bottom: bottom,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, child) {
            final t = Curves.easeOutBack.transform(_c.value);
            return Opacity(opacity: _c.value, child: Transform.translate(offset: Offset(0, 60 * (1 - t)), child: child));
          },
          child: Material(
            type: MaterialType.transparency,
            child: ExcludeSemantics(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: p.chip, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    const BuanCoin(),
                    const SizedBox(width: 12),
                    Expanded(child: Text(widget.label, style: AppTypography.body(14, weight: FontWeight.w800, color: p.onChip))),
                    Text(Fmt.signed(widget.amount), style: AppTypography.number(16, color: p.glow)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Konfeti / coin yağmuru katmanı. [play] true olduğunda bir kez patlar.
/// "Hareketi azalt" açıkken hiçbir şey çizmez.
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({super.key, required this.play, this.coins = false, this.duration = AppDurations.confetti});

  final bool play;

  /// true → konfeti yerine BUAN jetonu yağmuru.
  final bool coins;
  final Duration duration;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> {
  late final ConfettiController _c = ConfettiController(duration: widget.duration);

  @override
  void didUpdateWidget(CelebrationOverlay old) {
    super.didUpdateWidget(old);
    if (widget.play && !old.play) _fire();
  }

  @override
  void initState() {
    super.initState();
    if (widget.play) WidgetsBinding.instance.addPostFrameCallback((_) => _fire());
  }

  void _fire() {
    if (!mounted || (MediaQuery.maybeDisableAnimationsOf(context) ?? false)) return;
    Haptics.medium();
    _c.play();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _c,
          blastDirection: math.pi / 2,
          blastDirectionality: BlastDirectionality.explosive,
          emissionFrequency: widget.coins ? 0.06 : 0.08,
          numberOfParticles: widget.coins ? 10 : 18,
          maxBlastForce: 22,
          minBlastForce: 8,
          gravity: 0.25,
          colors: widget.coins ? [p.buanFill, p.coinMark] : [p.cta, p.hotFill, p.coinMark, p.secondary, p.buanFill],
          createParticlePath: widget.coins ? _coinPath : null,
        ),
      ),
    );
  }

  static Path _coinPath(Size size) => Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: 9));
}
