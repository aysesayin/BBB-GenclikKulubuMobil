import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/opportunities/claim.dart';
import '../../../data/models/opportunities/opportunity.dart';
import '../../../l10n/l10n.dart';
import 'opp_icons.dart';
import 'opp_style.dart';
import 'ticket_parts.dart';

/// C3 bilet kartı: marka satırı, kesik ayraç (çentikli), tipe göre kod / QR + PIN, geri sayım.
class ClaimTicket extends StatelessWidget {
  const ClaimTicket({super.key, required this.claim, required this.copied, required this.onCopy});

  final ClaimResult claim;
  final bool copied;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.sf,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: [BoxShadow(color: p.onTile.withValues(alpha: .18), blurRadius: 40, offset: const Offset(0, 18))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Row(
              children: [
                OppLogoTile(text: claim.logoText, shadow: false),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        claim.brand,
                        style: AppTypography.body(12, weight: FontWeight.w800, color: p.mut),
                      ),
                      Text(
                        claim.title,
                        style: AppTypography.body(16, weight: FontWeight.w900, height: 1.2, color: p.ink),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _Notched(color: p.bg, line: p.line),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (claim.type == ClaimType.code) _CodeBody(claim: claim, copied: copied, onCopy: onCopy) else _QrBody(claim: claim),
                const SizedBox(height: 14),
                HmsCountdown(
                  deadline: claim.expiresAt,
                  builder: (context, hms, _) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppIcon(AppIcons.clock, size: 16, color: p.pinkT, strokeWidth: 2.4),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(context.l10n.oppUseWithin(hms), style: AppTypography.number(13, color: p.pinkT)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Notched extends StatelessWidget {
  const _Notched({required this.color, required this.line});

  final Color color, line;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 24,
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: DashedLine(color: line),
        ),
        Positioned(left: -12, child: _dot(color)),
        Positioned(right: -12, child: _dot(color)),
      ],
    ),
  );

  Widget _dot(Color c) => Container(
    width: 24,
    height: 24,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );
}

class _CodeBody extends StatelessWidget {
  const _CodeBody({required this.claim, required this.copied, required this.onCopy});

  final ClaimResult claim;
  final bool copied;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final code = claim.code ?? '';
    return Column(
      children: [
        Text(
          l.oppYourCode,
          style: AppTypography.body(13, weight: FontWeight.w800, color: p.mut),
        ),
        const SizedBox(height: 14),
        Semantics(
          label: l.oppCodeSemantics(spellOut(code)),
          excludeSemantics: true,
          child: DashedBox(
            color: p.teal,
            background: p.bg,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(code, maxLines: 1, style: AppTypography.display(36, height: 1.2, color: p.ink).copyWith(letterSpacing: 2)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Semantics(
          button: true,
          label: copied ? l.commonCopied : l.oppCopyCode,
          excludeSemantics: true,
          child: Material(
            color: p.ink,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: onCopy,
              child: Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppIcon(copied ? AppIcons.check : OppIcons.copy, size: 18, color: p.sf, strokeWidth: 2.4),
                    const SizedBox(width: 8),
                    Text(copied ? l.commonCopied : l.oppCopyCode, style: AppTypography.buttonM.copyWith(color: p.sf)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          l.oppCodeHint,
          textAlign: TextAlign.center,
          style: AppTypography.body(13, color: p.mut),
        ),
      ],
    );
  }
}

class _QrBody extends StatelessWidget {
  const _QrBody({required this.claim});

  final ClaimResult claim;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final pnr = claim.type == ClaimType.pnr;
    final parts = claim.pinParts;
    return Column(
      children: [
        Text(
          pnr ? l.oppScanAtEntrance : l.oppScanAtCheckout,
          style: AppTypography.body(13, weight: FontWeight.w800, color: p.mut),
        ),
        const SizedBox(height: 14),
        Semantics(
          label: l.oppQrSemantics,
          image: true,
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.paper,
              borderRadius: BorderRadius.circular(AppRadii.tile),
              border: Border.all(color: p.line),
            ),
            child: QrImageView(
              data: claim.qrData,
              size: 160,
              padding: EdgeInsets.zero,
              backgroundColor: p.paper,
              eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: p.onTile),
              dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: p.onTile),
            ),
          ),
        ),
        if (parts.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            pnr ? l.oppPnrLabel : l.oppPinLabel,
            style: AppTypography.body(12, weight: FontWeight.w800, color: p.mut),
          ),
          const SizedBox(height: 4),
          Semantics(
            label: l.oppCodeSemantics(spellOut(claim.pin ?? '')),
            excludeSemantics: true,
            child: PinBoxes(parts: parts),
          ),
        ],
      ],
    );
  }
}

/// Tipine göre alt başlık ("Kasada QR’ı okut ya da 4 haneli kodu söyle").
extension ClaimSubtitle on AppLocalizations {
  String claimSubtitle(ClaimType t) => switch (t) {
    ClaimType.code => oppClaimSubCode,
    ClaimType.qr => oppClaimSubQr,
    ClaimType.pnr => oppClaimSubPnr,
  };
}
