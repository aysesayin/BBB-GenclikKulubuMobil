import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/profile/coupon.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/profile_ui.dart';

String _locale(BuildContext context) => Localizations.localeOf(context).languageCode;

/// "%15" / "30 ₺" — kupon değeri.
String couponValueText(BuildContext context, CouponKind kind, num value, {bool signed = false, bool cents = false}) {
  final abs = value.abs();
  final sign = !signed ? '' : (value < 0 ? '−' : '+');
  final body = switch (kind) {
    CouponKind.percent => context.l10n.profilePercent(Fmt.number(abs)),
    CouponKind.amount => cents ? ProfileFmt.money(abs, _locale(context)) : Fmt.currency(abs),
  };
  return '$sign$body';
}

/// Turkuaz bakiye kartı + sağ üstte yarı saydam blob.
class CouponBalanceCard extends StatelessWidget {
  const CouponBalanceCard({super.key, required this.balance});

  final num balance;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final fg = p.onCta;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      decoration: BoxDecoration(color: p.primary, borderRadius: BorderRadius.circular(26)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -50,
            top: -40,
            child: SvgArt(
              '<svg viewBox="0 0 200 180"><path d="M110 10c50 0 85 40 80 90s-40 75-90 75S10 135 18 85 60 10 110 10z" '
              'fill="${p.paper.hex}" fill-opacity=".3"/></svg>',
              width: 200,
              height: 180,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.profileCouponBalance,
                    style: AppTypography.body(13, weight: FontWeight.w900, color: fg),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(ProfileFmt.money(balance, _locale(context)), style: AppTypography.number(44, color: fg, height: 1.1)),
                  ),
                  Text(
                    l.profileCouponBalanceNote,
                    style: AppTypography.body(12, weight: FontWeight.w800, color: fg),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bilet biçimli kupon: solda değer karosu (kesik çizgi), sağda başlık + durum.
class CouponTile extends StatelessWidget {
  const CouponTile({super.key, required this.coupon});

  final Coupon coupon;

  String _subtitle(AppLocalizations l) {
    final used = coupon.usedAt;
    final until = coupon.expiresAt;
    if (coupon.used) return used == null ? coupon.source : l.profileCouponUsed(ProfileFmt.dmy(used));
    if (until == null) return coupon.source;
    final date = ProfileFmt.dmy(until);
    return coupon.source.isEmpty ? l.profileCouponUntilShort(date) : l.profileCouponUntil(coupon.source, date);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final tone = coupon.kind == CouponKind.percent ? p.tile4 : p.tile2;
    return Opacity(
      opacity: coupon.used ? .6 : 1,
      child: Container(
        decoration: BoxDecoration(color: p.sf, borderRadius: BorderRadius.circular(AppRadii.tile)),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomPaint(
                foregroundPainter: _DashedRightEdge(p.line),
                child: Container(
                  width: 86,
                  color: tone,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(couponValueText(context, coupon.kind, coupon.value), style: AppTypography.display(20, color: p.onTile)),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TitleSubtitle(title: coupon.title, subtitle: _subtitle(l)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedRightEdge extends CustomPainter {
  _DashedRightEdge(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    final x = size.width - 1;
    for (double y = 0; y < size.height; y += 8) {
      canvas.drawLine(Offset(x, y), Offset(x, (y + 4).clamp(0, size.height)), paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRightEdge old) => old.color != color;
}

/// Hareket satırı: başlık + tarih, sağda işaretli değer (+ yeşil, − mor).
class CouponMovementRow extends StatelessWidget {
  const CouponMovementRow({super.key, required this.movement});

  final CouponMovement movement;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final positive = movement.value >= 0;
    return MergeSemantics(
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: p.line)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: TitleSubtitle(
                title: movement.title,
                subtitle: ProfileFmt.dayMonthYear(movement.date, _locale(context)),
                titleSize: 14,
                titleWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              couponValueText(context, movement.kind, movement.value, signed: true, cents: true),
              style: AppTypography.number(15, color: positive ? p.grnT : p.purT),
            ),
          ],
        ),
      ),
    );
  }
}
