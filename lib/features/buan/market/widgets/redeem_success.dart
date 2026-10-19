import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/buan/buan_reward.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/buan_icons.dart';
import '../../widgets/buan_ui.dart';

/// Takas başarı katmanı: mor tam ekran, hediye sticker'ı (pop), kod, kalan bakiye
/// (eski → yeni 600 ms), konfeti.
class RedeemSuccess extends StatefulWidget {
  const RedeemSuccess({
    super.key,
    required this.reward,
    required this.result,
    required this.balanceFrom,
    required this.balanceTo,
    required this.onCodes,
    required this.onBack,
  });

  final BuanReward reward;
  final BuanRedeemResult result;
  final int balanceFrom, balanceTo;
  final VoidCallback onCodes, onBack;

  @override
  State<RedeemSuccess> createState() => _RedeemSuccessState();
}

class _RedeemSuccessState extends State<RedeemSuccess> with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

  @override
  void initState() {
    super.initState();
    Haptics.medium();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.reduceMotion) {
        _pop.value = 1;
      } else {
        _pop.forward();
      }
    });
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.result.code));
    Haptics.selection();
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(context.l10n.commonCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final mq = MediaQuery.paddingOf(context);
    final info = widget.result.info ?? widget.reward.redeemInfo ?? l.buanRedeemDefaultInfo;
    return Material(
      color: p.buanFill,
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -60,
            child: SvgArt(
              '<svg viewBox="0 0 400 400"><path d="M220 20c110 0 180 70 170 170s-90 180-200 170S10 280 30 180 110 20 220 20z" '
              'fill="${p.coinMark.hex}" opacity=".3"/></svg>',
              width: 400,
              height: 400,
            ),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, math.max(mq.top + 76, 120), 24, 40 + mq.bottom),
                      child: Column(
                        children: [
                          _GiftSticker(animation: _pop),
                          const SizedBox(height: 22),
                          Semantics(
                            header: true,
                            liveRegion: true,
                            child: Text(
                              l.buanRedeemSuccessTitle,
                              textAlign: TextAlign.center,
                              style: AppTypography.display(32, height: 1.05, color: p.onBuan),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            info,
                            textAlign: TextAlign.center,
                            style: AppTypography.body(15, color: p.onBuan.withValues(alpha: .92)),
                          ),
                          const SizedBox(height: 14),
                          Semantics(
                            button: true,
                            label: l.buanRedeemCodeSemantics(widget.result.code),
                            excludeSemantics: true,
                            child: GestureDetector(
                              onTap: _copy,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(18)),
                                child: Text(
                                  widget.result.code,
                                  style: AppTypography.display(30, color: p.onTile).copyWith(letterSpacing: 2),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          BalanceTween(
                            from: widget.balanceFrom,
                            to: widget.balanceTo,
                            builder: (_, v) => Text(
                              l.buanRedeemRemaining(Fmt.number(v)),
                              textAlign: TextAlign.center,
                              style: AppTypography.number(13, weight: FontWeight.w800, color: p.onBuan.withValues(alpha: .9)),
                            ),
                          ),
                          const Spacer(),
                          const SizedBox(height: 32),
                          AppButton(label: l.buanRedeemGoCodes, onPressed: widget.onCodes),
                          const SizedBox(height: 6),
                          SizedBox(
                            height: 48,
                            width: double.infinity,
                            child: TextButton(
                              onPressed: widget.onBack,
                              style: TextButton.styleFrom(foregroundColor: p.paper, shape: const StadiumBorder()),
                              child: Text(l.buanRedeemBackToMarket, style: AppTypography.buttonM.copyWith(color: p.paper)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Positioned.fill(child: CelebrationOverlay(play: true)),
        ],
      ),
    );
  }
}

class _GiftSticker extends StatelessWidget {
  const _GiftSticker({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final sticker = Container(
      width: 110,
      height: 110,
      decoration: BoxDecoration(
        color: p.secondary,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: p.onTile, width: 3),
        boxShadow: [BoxShadow(color: p.onTile, offset: const Offset(5, 5))],
      ),
      alignment: Alignment.center,
      child: AppIcon(BuanIcons.giftOpen, size: 56, color: p.onTile, strokeWidth: 2),
    );
    return AnimatedBuilder(
      animation: animation,
      child: sticker,
      builder: (_, child) {
        final t = Curves.easeOutBack.transform(animation.value);
        final deg = -10 + 4 * t;
        return Opacity(
          opacity: animation.value.clamp(0, 1),
          child: Transform.rotate(
            angle: deg * math.pi / 180,
            child: Transform.scale(scale: .6 + .4 * t, child: child),
          ),
        );
      },
    );
  }
}
