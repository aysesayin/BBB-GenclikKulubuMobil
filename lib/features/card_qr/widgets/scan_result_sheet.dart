import 'package:flutter/material.dart';

import '../../../core/network/app_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/card/digital_card.dart';
import '../../../l10n/l10n.dart';

/// Ekran içi alt sayfa kabuğu: karartma + alttan yaylanarak (320 ms) giren kart.
class ScanSheetFrame extends StatelessWidget {
  const ScanSheetFrame({super.key, required this.child, this.coins = false});

  final Widget child;
  final bool coins;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reduce = context.reduceMotion;
    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: p.night.withValues(alpha: .6))),
        if (coins) const Positioned.fill(child: CelebrationOverlay(play: true, coins: true, duration: AppDurations.coinRain)),
        Align(
          alignment: Alignment.bottomCenter,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: reduce ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 320),
            curve: const Cubic(.34, 1.56, .64, 1),
            builder: (context, t, child) => FractionalTranslation(translation: Offset(0, 1 - t), child: child),
            child: Semantics(
              scopesRoute: true,
              namesRoute: true,
              explicitChildNodes: true,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + MediaQuery.paddingOf(context).bottom),
                decoration: BoxDecoration(
                  color: p.sf,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [const SheetHandle(), child]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Başarı: eğik onay rozeti, başlık, "+300 BUAN", rozet ipucu, "Harika!".
class ScanSuccessContent extends StatefulWidget {
  const ScanSuccessContent({super.key, required this.result, required this.onDone});

  final QrCheckInResult result;
  final VoidCallback onDone;

  @override
  State<ScanSuccessContent> createState() => _ScanSuccessContentState();
}

class _ScanSuccessContentState extends State<ScanSuccessContent> {
  @override
  void initState() {
    super.initState();
    // Konfeti katmanı haptiği kendisi verir; hareket azaltılmışsa burada veriyoruz.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.reduceMotion) Haptics.medium();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final r = widget.result;
    final amount = l.buanAmount(Fmt.signed(r.buan));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 6),
        Transform.rotate(
          angle: -6 * 3.14159 / 180,
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: p.secondary,
              borderRadius: BorderRadius.circular(AppRadii.xl),
              border: Border.all(color: p.onTile, width: 3),
              boxShadow: [BoxShadow(color: p.onTile, offset: const Offset(4, 4))],
            ),
            alignment: Alignment.center,
            child: AppIcon(AppIcons.check, size: 44, color: p.onTile, strokeWidth: 3),
          ),
        ),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(
            r.headline ?? l.cardScanSuccessTitle(r.placeName),
            textAlign: TextAlign.center,
            style: AppTypography.display(26, color: p.ink),
          ),
        ),
        if (r.buan > 0) ...[
          const SizedBox(height: 12),
          Semantics(
            liveRegion: true,
            label: amount,
            excludeSemantics: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BuanCoin(size: 40),
                const SizedBox(width: 8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(amount, maxLines: 1, style: AppTypography.number(40, color: p.purT)),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (r.badgeHint case final hint?) ...[
          const SizedBox(height: 12),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: AppTypography.body(14, color: p.mut),
          ),
        ],
        const SizedBox(height: 16),
        AppButton(label: l.cardScanDone, onPressed: widget.onDone),
      ],
    );
  }
}

/// Hata: zaten check-in yapıldı / kod geçersiz / ağ yok.
class ScanFailureContent extends StatelessWidget {
  const ScanFailureContent({super.key, required this.error, required this.onRetry, required this.onScanAgain});

  final AppException error;
  final VoidCallback onRetry, onScanAgain;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final network = error is NetworkException;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 6),
        const Mascot(mood: MascotMood.surprised, size: 96),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text(
            l.cardScanFailTitle,
            textAlign: TextAlign.center,
            style: AppTypography.display(24, color: p.ink),
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          liveRegion: true,
          child: Text(
            errorMessageOf(context, error),
            textAlign: TextAlign.center,
            style: AppTypography.body(15, color: p.mut, height: 1.4),
          ),
        ),
        const SizedBox(height: 16),
        if (network) ...[AppButton(label: l.commonRetry, onPressed: onRetry), const SizedBox(height: 8)],
        AppButton(
          label: l.cardScanAgain,
          onPressed: onScanAgain,
          variant: network ? AppButtonVariant.outlineInk : AppButtonVariant.cta,
          size: network ? AppButtonSize.medium : AppButtonSize.large,
        ),
      ],
    );
  }
}
