import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ui_prefs_controller.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import 'opp_icons.dart';

/// C3 üst çubuk: kapat + "Parlaklık %100" çipi.
class ClaimedTopBar extends StatelessWidget {
  const ClaimedTopBar({super.key, required this.bright});

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
                  Text(l.oppBrightnessFull, style: AppTypography.body(12, weight: FontWeight.w900, color: p.paper)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// "Ekran kapanırsa kodu Fırsatlarım’dan tekrar açabilirsin" ipucu (uyku kilidi yok).
class KeepAwakeHint extends StatelessWidget {
  const KeepAwakeHint({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(OppIcons.sun, size: 14, color: p.mut, strokeWidth: 2.4),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              context.l10n.oppKeepAwakeHint,
              textAlign: TextAlign.center,
              style: AppTypography.body(12, weight: FontWeight.w800, color: p.mut),
            ),
          ),
        ],
      ),
    );
  }
}

/// Alt eylemler: Fırsatlarım · Tamam (+ mock modunda "Kullandım" demo butonu / "Kullanıldı" rozeti).
/// Kolay Mod: butonlar tam genişlik, alt alta.
class ClaimedActions extends StatelessWidget {
  const ClaimedActions({super.key, required this.used, this.onMarkUsed});

  final bool used;

  /// null → demo butonu gösterilmez (gerçek API modu).
  final VoidCallback? onMarkUsed;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = context.palette;
    final easy = context.easyMode;
    final mine = AppButton(
      label: l.oppMyOpportunities,
      variant: AppButtonVariant.outlineInk,
      onPressed: () => context.go(Routes.myOpportunities),
    );
    final done = AppButton(label: l.commonDone, onPressed: () => context.go(Routes.opportunities));
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 16 + MediaQuery.paddingOf(context).bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (used)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Center(child: TagBadge(label: l.oppUsedBadge, background: p.grnS, foreground: p.grnT)),
            )
          else if (onMarkUsed != null)
            AppButton.text(
              label: l.oppMarkUsed,
              icon: AppIcons.check,
              semanticLabel: l.oppMarkUsedSemantics,
              onPressed: onMarkUsed,
            ),
          if (easy) ...[mine, const SizedBox(height: 10), done] else Row(children: [Expanded(child: mine), const SizedBox(width: 10), Expanded(child: done)]),
        ],
      ),
    );
  }
}

/// Üstteki sıcak pembe blob illüstrasyonu.
class ClaimedHeroArt extends StatelessWidget {
  const ClaimedHeroArt({super.key, required this.color});

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
