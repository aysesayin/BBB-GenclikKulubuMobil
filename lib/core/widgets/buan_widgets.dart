import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'app_icon.dart';
import 'app_icons.dart';

/// BUAN jetonu: mor daire + turkuaz üçgen.
class BuanCoin extends StatelessWidget {
  const BuanCoin({super.key, this.size = 24, this.ring = false});

  final double size;

  /// Büyük kullanımlarda iç halka (tasarım sistemi coin varyantı).
  final bool ring;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ringSvg = ring ? '<circle cx="12" cy="12" r="8.5" fill="none" stroke="${p.buanGlow.hex}" stroke-width="1"/>' : '';
    return SvgArt(
      '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="11" fill="${p.buanFill.hex}"/>$ringSvg'
      '<path d="M9.5 7.5l7 4.5-7 4.5z" fill="${p.coinMark.hex}"/></svg>',
      width: size,
      height: size,
    );
  }
}

/// Sabit genişlikli puan rozeti: "+2.000". ASLA satır kırmaz (eski uygulamadaki
/// "+200 / 0" taşmasının düzeltmesi) — sığmazsa küçülür.
class BuanPointsBadge extends StatelessWidget {
  const BuanPointsBadge({super.key, required this.points, this.minWidth = 64, this.height = 26, this.fontSize = 13, this.signed = true, this.background, this.foreground, this.label});

  /// Aralık / serbest metin (ör. "+10–200"); verilirse [points] yerine gösterilir.
  const BuanPointsBadge.text(String this.label, {super.key, this.minWidth = 64, this.height = 26, this.fontSize = 13, this.background, this.foreground})
      : points = 0,
        signed = false;

  final int points;
  final String? label;
  final double minWidth, height, fontSize;
  final bool signed;
  final Color? background, foreground;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = label ?? (signed ? Fmt.signed(points) : Fmt.number(points));
    return Semantics(
      label: context.l10n.buanAmount(text),
      excludeSemantics: true,
      child: Container(
        constraints: BoxConstraints(minWidth: minWidth),
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(color: background ?? p.purS, borderRadius: BorderRadius.circular(height / 2)),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(text, maxLines: 1, softWrap: false, style: AppTypography.number(fontSize, color: foreground ?? p.purT)),
        ),
      ),
    );
  }
}

/// Başlıktaki bakiye çipi: jeton + "12.450". [onTap] verilirse BUAN'a gider.
class BuanBalanceChip extends StatelessWidget {
  const BuanBalanceChip({super.key, required this.balance, this.onTap, this.animate = true});

  final int balance;
  final VoidCallback? onTap;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final amount = Fmt.number(balance);
    return Semantics(
      button: onTap != null,
      label: context.l10n.buanBalanceSemantics(amount),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.fromLTRB(6, 0, 12, 0),
          decoration: BoxDecoration(color: p.purS, borderRadius: BorderRadius.circular(18)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BuanCoin(),
              const SizedBox(width: 6),
              CountUpText(value: balance, animate: animate, style: AppTypography.number(14, color: p.purT)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Seri çipi: ateş + gün sayısı.
class StreakChip extends StatelessWidget {
  const StreakChip({super.key, required this.days, this.onTap});

  final int days;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: onTap != null,
      label: context.l10n.streakSemantics(days),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(color: p.yelS, borderRadius: BorderRadius.circular(18)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(AppIcons.flame, size: 18, color: p.ctaShadow, fill: p.cta, strokeWidth: 1.5),
              const SizedBox(width: 4),
              Text('$days', style: AppTypography.number(14, color: p.ink)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sayılarda count-up (900 ms easeOutExpo). Değer değişince eskiden yeniye sayar.
/// "Hareketi azalt" açıkken doğrudan son değeri gösterir.
class CountUpText extends StatelessWidget {
  const CountUpText({super.key, required this.value, required this.style, this.animate = true, this.signed = false, this.duration = AppDurations.countUp, this.from = 0});

  final int value;

  /// İlk gösterimde sayımın başlangıcı (ör. takasta eski bakiye).
  final int from;
  final TextStyle style;
  final bool animate, signed;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    String fmt(num v) => signed ? Fmt.signed(v.round()) : Fmt.number(v.round());
    if (!animate || reduce) return Text(fmt(value), style: style, maxLines: 1, softWrap: false);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: from.toDouble(), end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutExpo,
      builder: (_, v, _) => Text(fmt(v), style: style, maxLines: 1, softWrap: false),
    );
  }
}
