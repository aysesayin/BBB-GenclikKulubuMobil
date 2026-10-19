import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import 'motion.dart';
import 'onb_icons.dart';

/// A2 · 3. hikâye: dönen BUAN coin'i. Dokununca halka (700 ms), konfeti ve
/// 0 → bonus sayımı (900 ms easeOutExpo, mediumImpact).
class StoryCoinScene extends StatelessWidget {
  const StoryCoinScene({super.key, required this.popped, required this.bonus, required this.onPop, this.parallax = Offset.zero});

  final bool popped;
  final int bonus;
  final VoidCallback onPop;
  final Offset parallax;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 340,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: popped
              ? [
                  const _Boom(),
                  const Positioned.fill(child: CelebrationOverlay(play: true)),
                  _Reward(bonus: bonus),
                ]
              : [Transform.translate(offset: parallax, child: _Coin(bonus: bonus, onTap: onPop))],
        ),
      );
}

class _Coin extends StatelessWidget {
  const _Coin({required this.bonus, required this.onTap});

  final int bonus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final coin = Container(
      width: 210,
      height: 210,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-.36, -.44),
          radius: .9,
          colors: [Color.lerp(p.buanFill, p.paper, .55)!, p.buanFill, p.buanGradEnd],
          stops: const [0, .42, 1],
        ),
        boxShadow: [
          BoxShadow(color: p.glow.withValues(alpha: .33), spreadRadius: 10),
          BoxShadow(color: p.buanShadow.withValues(alpha: .53), blurRadius: 60, offset: const Offset(0, 30)),
        ],
      ),
      child: AppIcon(OnbIcons.coinTriangle, size: 96, color: p.coinMark, fill: p.coinMark, strokeWidth: 2),
    );
    return Semantics(
      button: true,
      label: context.l10n.onbCoinSemantics(Fmt.number(bonus)),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 230,
          height: 230,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              LoopMotion(
                duration: const Duration(milliseconds: 2400),
                reverse: false,
                child: coin,
                builder: (_, t, child) => Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 1 / 800)
                    ..rotateY(t * 2 * math.pi),
                  child: child,
                ),
              ),
              Positioned(right: -14, top: -10, child: _TapSticker(label: context.l10n.onbCoinTap)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TapSticker extends StatelessWidget {
  const _TapSticker({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LoopMotion(
      duration: const Duration(milliseconds: 500),
      builder: (_, t, child) => Transform.scale(scale: 1 + .08 * Curves.easeInOut.transform(t), child: child),
      child: Transform.rotate(
        angle: 10 * math.pi / 180,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: p.cta,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.onTile, width: 3),
            boxShadow: [BoxShadow(color: p.onTile, offset: const Offset(4, 4))],
          ),
          child: Text(label, style: AppTypography.display(22, height: 1, color: p.onCta)),
        ),
      ),
    );
  }
}

class _Boom extends StatelessWidget {
  const _Boom();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (context.reduceMotion) return const SizedBox.shrink();
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeOut,
        builder: (_, v, child) => Opacity(opacity: 1 - v, child: Transform.scale(scale: 1 + 1.4 * v, child: child)),
        child: Container(
          width: 210,
          height: 210,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: p.glow, width: 10)),
        ),
      ),
    );
  }
}

class _Reward extends StatelessWidget {
  const _Reward({required this.bonus});

  final int bonus;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final amount = Fmt.number(bonus);
    return Semantics(
      liveRegion: true,
      label: '${l.onbCoinReady(amount)} ${l.onbCoinNote}',
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: context.reduceMotion ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 600),
        builder: (_, v, child) {
          final s = v < .55 ? .2 + 1.05 * (v / .55) : 1.25 - .25 * ((v - .55) / .45);
          return Opacity(opacity: (v / .55).clamp(0, 1), child: Transform.scale(scale: s, child: child));
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BuanCoin(size: 64, ring: true),
                const SizedBox(width: 10),
                CountUpText(value: bonus, style: AppTypography.display(96, height: 1, color: p.onBuan).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
              ],
            ),
            const SizedBox(height: 6),
            Text(l.onbCoinReady(amount), textAlign: TextAlign.center, style: AppTypography.display(26, color: p.onBuan)),
            const SizedBox(height: 6),
            Opacity(opacity: .9, child: Text(l.onbCoinNote, textAlign: TextAlign.center, style: AppTypography.body(14, weight: FontWeight.w800, color: p.onBuan))),
          ],
        ),
      ),
    );
  }
}
