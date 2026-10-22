import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ui_prefs_controller.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import 'card_icons.dart';

/// Kartım eylemleri: "Gişede göster" (öne çıkan CTA), "QR Okut" ve pasif "Cüzdana ekle · Yakında" çipi.
/// Kolay Mod: hepsi tam genişlik, alt alta.
class CardActions extends StatelessWidget {
  const CardActions({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final easy = context.easyMode;
    final gate = AppButton(label: l.cardShowAtGate, icon: CardIcons.qrSmall, onPressed: () => context.push(Routes.turnstile));
    final scan = AppButton.buan(label: l.cardScanCta, icon: CardIcons.scan, fontSize: 16, onPressed: () => context.push(Routes.qrScan));
    const wallet = WalletSoonChip();
    if (easy) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [gate, const SizedBox(height: 10), scan, const SizedBox(height: 10), wallet],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        gate,
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(flex: 12, child: scan),
            const SizedBox(width: 10),
            const Expanded(flex: 10, child: wallet),
          ],
        ),
      ],
    );
  }
}

/// "Cüzdana ekle" henüz yok: pasif görünümlü çip + "Yakında" rozeti (ölü buton yerine).
// TODO(varsayım): Apple/Google Wallet pass'i backend'den (.pkpass / JWT) gelince gerçek buton olacak.
class WalletSoonChip extends StatelessWidget {
  const WalletSoonChip({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return Semantics(
      label: '${l.cardAddToWallet}, ${l.commonComingSoon}',
      excludeSemantics: true,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: p.sf2,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: p.line, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(AppIcons.wallet, size: 18, color: p.mut, strokeWidth: 2.2),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                l.cardAddToWallet,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.body(14, weight: FontWeight.w800, color: p.mut),
              ),
            ),
            const SizedBox(width: 8),
            TagBadge(label: l.commonComingSoon, background: p.yelS, foreground: p.onTile, fontSize: 11),
          ],
        ),
      ),
    );
  }
}

/// "Parlaklık arttı" çipi (başlık sağı).
class BrightChip extends StatelessWidget {
  const BrightChip({super.key, required this.label});

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
          Text(label, style: AppTypography.body(12, weight: FontWeight.w900, color: p.mut)),
        ],
      ),
    );
  }
}
