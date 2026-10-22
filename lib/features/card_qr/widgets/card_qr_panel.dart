import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../opportunities/widgets/ticket_parts.dart';

/// Dinamik QR paneli: halka geri sayım, 180 px QR, büyük 4 haneli kod ([large] → 56 px, Kolay Mod).
/// Ekran okuyucuda "Kodu sesli oku" özel eylemi kodu hane hane duyurur.
class CardQrPanel extends StatelessWidget {
  const CardQrPanel({
    super.key,
    required this.token,
    required this.pin,
    required this.secondsLeft,
    required this.ring,
    required this.offline,
    required this.loading,
    this.large = false,
    this.onRetry,
  });

  final String? token, pin;
  final int secondsLeft;
  final double ring;
  final bool offline, loading;

  /// Kolay Mod: 4 haneli kod 56 px.
  final bool large;
  final VoidCallback? onRetry;

  void _readAloud(BuildContext context) {
    final code = pin;
    if (code == null) return;
    SemanticsService.sendAnnouncement(View.of(context), context.l10n.cardPinSemantics(spellOut(code)), Directionality.of(context));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final code = pin;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      customSemanticsActions: code == null ? null : {CustomSemanticsAction(label: l.cardReadAloud): () => _readAloud(context)},
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: p.sf, borderRadius: BorderRadius.circular(AppRadii.xl), boxShadow: p.cardShadow),
        child: Column(
          children: [
            _Status(secondsLeft: secondsLeft, ring: ring, offline: offline, hasToken: token != null, onRetry: onRetry),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(18)),
              child: SizedBox.square(
                dimension: 180,
                child: token != null
                    ? Semantics(
                        label: l.cardQrSemantics,
                        image: true,
                        excludeSemantics: true,
                        child: QrImageView(
                          data: token!,
                          size: 180,
                          padding: EdgeInsets.zero,
                          backgroundColor: p.paper,
                          eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: p.onTile),
                          dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: p.onTile),
                        ),
                      )
                    : _NoQr(offline: offline, loading: loading),
              ),
            ),
            if (code != null) ...[
              const SizedBox(height: 14),
              Text(
                l.cardPinHint,
                textAlign: TextAlign.center,
                style: AppTypography.body(12, weight: FontWeight.w800, color: p.mut),
              ),
              const SizedBox(height: 6),
              Semantics(
                label: l.cardPinSemantics(spellOut(code)),
                excludeSemantics: true,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: large
                      ? PinBoxes(parts: code.split(''), minWidth: 68, height: 84, fontSize: 56, radius: 20)
                      : PinBoxes(parts: code.split(''), minWidth: 52, height: 60, fontSize: 34, radius: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.secondsLeft, required this.ring, required this.offline, required this.hasToken, this.onRetry});

  final int secondsLeft;
  final double ring;
  final bool offline, hasToken;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final style = AppTypography.body(14, weight: FontWeight.w800, color: p.mut);
    if (!hasToken) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(offline ? AppIcons.wifiOff : AppIcons.refresh, size: 20, color: offline ? p.pinkT : p.mut, strokeWidth: 2.4),
          const SizedBox(width: 8),
          Flexible(child: Text(offline ? l.cardOfflineStatus : l.cardTokenError, style: style)),
          if (!offline && onRetry != null) ...[
            const SizedBox(width: 4),
            AppButton.text(label: l.commonRetry, size: AppButtonSize.small, expand: false, onPressed: onRetry),
          ],
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ProgressRing(value: ring, color: p.primary, size: 26, stroke: 3),
        const SizedBox(width: 8),
        Flexible(child: Text(l.cardRefreshIn(secondsLeft), style: style)),
      ],
    );
  }
}

class _NoQr extends StatelessWidget {
  const _NoQr({required this.offline, required this.loading});

  final bool offline, loading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (loading && !offline) return const Shimmer(child: SkeletonBox(width: 180, height: 180, radius: 8));
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppIcon(AppIcons.qr, size: 56, color: p.line, strokeWidth: 1.8),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            offline ? context.l10n.cardOfflineQr : context.l10n.cardTokenError,
            textAlign: TextAlign.center,
            style: AppTypography.body(12, weight: FontWeight.w800, color: p.borderStrong),
          ),
        ),
      ],
    );
  }
}
