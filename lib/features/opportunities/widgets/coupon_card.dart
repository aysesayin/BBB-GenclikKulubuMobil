import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/opportunities/claim.dart';
import '../../../l10n/l10n.dart';
import 'opp_style.dart';
import 'ticket_parts.dart';

/// C4 kupon kartı: solda 92 px renkli koçan (indirim + logo), kesik "yırtık" kenar, durum satırı.
class CouponCard extends StatelessWidget {
  const CouponCard({super.key, required this.item, required this.now, required this.onTap});

  final WalletItem item;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (status, color, icon) = _status(context);
    return Opacity(
      opacity: item.status == WalletStatus.expired ? .7 : 1,
      child: AppCard(
        padding: EdgeInsets.zero,
        clip: true,
        onTap: onTap,
        semanticLabel: '${item.brand}, ${item.title}, ${item.discountLabel}, $status',
        child: ExcludeSemantics(
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 92,
                  color: p.tone(item.tone),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(item.discountLabel, style: AppTypography.display(26, height: 1, color: p.onTile)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.logoText,
                        style: AppTypography.body(11, weight: FontWeight.w900, color: p.onTile),
                      ),
                    ],
                  ),
                ),
                _TornEdge(color: p.bg, line: p.line),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item.brand,
                          style: AppTypography.body(12, weight: FontWeight.w800, color: p.mut),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.title,
                          style: AppTypography.body(15, weight: FontWeight.w800, height: 1.25, color: p.ink),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            AppIcon(icon, size: 14, color: color, strokeWidth: 2.6),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                status,
                                style: AppTypography.body(12, weight: FontWeight.w900, color: color),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Center(child: AppIcon(AppIcons.chevronRight, size: 18, color: p.mut, strokeWidth: 2.4)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (String, Color, String) _status(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    switch (item.status) {
      case WalletStatus.active:
        final left = (item.expiresAt ?? item.claim?.expiresAt)?.difference(now);
        if (left != null && left.inHours < 48) {
          return (l.oppWalletUseWithinHours(left.isNegative ? 0 : left.inHours), p.pinkT, AppIcons.clock);
        }
        return (l.oppWalletValidDays(left == null ? 0 : (left.inHours / 24).ceil()), p.mut, AppIcons.clock);
      case WalletStatus.used:
        final date = item.usedAt == null ? '' : l.dateLoc(item.usedAt!.toLocal());
        return (
          item.buanEarned > 0 ? l.oppWalletUsedEarned(date, Fmt.signed(item.buanEarned)) : l.oppWalletUsed(date),
          p.grnT,
          AppIcons.check,
        );
      case WalletStatus.expired:
        final date = item.expiresAt == null ? '' : l.dateLoc(item.expiresAt!.toLocal());
        return (l.oppWalletExpiredOn(date), p.mut, AppIcons.close);
    }
  }
}

/// Koçan ile gövde arasındaki kesik çizgi + üst/alt çentik.
class _TornEdge extends StatelessWidget {
  const _TornEdge({required this.color, required this.line});

  final Color color, line;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 2,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: DashedLine(color: line, vertical: true),
          ),
        ),
        Positioned(top: -8, left: -7, child: _notch()),
        Positioned(bottom: -8, left: -7, child: _notch()),
      ],
    ),
  );

  Widget _notch() => Container(
    width: 16,
    height: 16,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
