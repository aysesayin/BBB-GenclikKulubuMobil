import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/svc_format.dart';

/// Ara toplam · İndirim · Kupon · Ödenecek.
class CartTotals extends StatelessWidget {
  const CartTotals({super.key, required this.subtotal, required this.discount, required this.coupon, required this.total});

  final num subtotal, discount, coupon, total;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    String minus(num v) => v > 0 ? l.svcMinus(SvcFmt.money(context, v)) : SvcFmt.money(context, 0);
    Widget row(String k, String v, {Color? color}) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(child: Text(k, style: AppTypography.body(14, color: p.mut))),
              Text(v, style: AppTypography.number(14, color: color ?? p.ink)),
            ],
          ),
        );
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(color: p.sf, borderRadius: BorderRadius.circular(AppRadii.tile)),
      child: Column(
        children: [
          row(l.svcSubtotal, SvcFmt.money(context, subtotal)),
          row(l.svcDiscountLine, minus(discount), color: p.grnT),
          row(l.svcCouponLine, minus(coupon), color: p.grnT),
          Container(
            padding: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: p.line))),
            child: Row(
              children: [
                Expanded(child: Text(l.svcTotal, style: AppTypography.body(16, weight: FontWeight.w900, color: p.ink))),
                Text(SvcFmt.money(context, total), style: AppTypography.number(18, color: p.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
