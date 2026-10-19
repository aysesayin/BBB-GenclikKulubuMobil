import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/services/benefits.dart';
import '../../../../data/models/services/cart.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/services_icons.dart';
import '../../widgets/svc_format.dart';

/// Sepet kalemi kartı.
class CartItemCard extends StatelessWidget {
  const CartItemCard({super.key, required this.item});

  final CartItem item;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final start = item.start;
    final when = start == null ? '' : '${SvcFmt.dayMonth(context, start)} ${SvcFmt.time(context, start)}';
    final who = item.forSelf ? l.svcWhoSelf : item.participantName;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: p.sf, borderRadius: BorderRadius.circular(AppRadii.lg)),
      child: Row(
        children: [
          IconTile(icon: SvcIcons.of(item.icon), color: SvcFmt.tile(p, item.tile), size: 52, radius: 16, iconSize: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: AppTypography.body(15, weight: FontWeight.w900, color: p.ink)),
                const SizedBox(height: 2),
                Text(l.svcCartItemMeta(item.facilityName, when, who), style: AppTypography.body(12, color: p.mut)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(SvcFmt.price(context, item.price), style: AppTypography.number(16, color: p.ink)),
        ],
      ),
    );
  }
}

/// "Uygun indirimler" radyo satırı. [discount] null → "İndirim kullanma".
class DiscountOptionRow extends StatelessWidget {
  const DiscountOptionRow({super.key, required this.discount, required this.selected, required this.onTap});

  final EligibleDiscount? discount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final d = discount;
    final enabled = d == null || d.usable;
    final title = d?.name ?? l.svcDiscountNone;
    final sub = switch (d) {
      null => '',
      EligibleDiscount(:final usable, :final validUntil) when usable =>
        validUntil == null ? l.svcDiscountApprovedNoDate : l.svcDiscountApproved(SvcFmt.shortDate(validUntil)),
      EligibleDiscount(status: DiscountStatus.pending) => l.svcDiscountPending,
      _ => l.svcDiscountUnavailable,
    };
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: enabled,
      button: true,
      child: Opacity(
        opacity: enabled ? 1 : .6,
        child: GestureDetector(
          onTap: () {
            Haptics.selection();
            onTap();
          },
          child: AnimatedContainer(
            duration: AppDurations.chip,
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: p.sf,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: selected ? p.teal : Colors.transparent, width: 2),
            ),
            child: Row(
              children: [
                _RadioDot(selected: selected),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.body(15, weight: FontWeight.w900, color: p.ink)),
                      if (sub.isNotEmpty) Text(sub, style: AppTypography.body(12, color: p.mut)),
                    ],
                  ),
                ),
                if (d != null && d.rate > 0)
                  Text(l.svcDiscountRate('${d.rate}'), style: AppTypography.body(14, weight: FontWeight.w900, color: p.grnT)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedContainer(
      duration: AppDurations.chip,
      width: 22,
      height: 22,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? p.teal : p.borderStrong, width: 2)),
      alignment: Alignment.center,
      child: selected ? Container(width: 12, height: 12, decoration: BoxDecoration(color: p.teal, shape: BoxShape.circle)) : null,
    );
  }
}

/// "Kupon bakiyesi kullan" anahtarı.
class CouponToggleRow extends StatelessWidget {
  const CouponToggleRow({super.key, required this.wallet, required this.value, required this.onChanged});

  final CouponWallet wallet;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final amount = SvcFmt.price(context, wallet.balance);
    final source = wallet.primaryAmountCoupon?.title ?? '';
    return MergeSemantics(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: p.sf, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            AppIcon(SvcIcons.ticket, size: 22, color: p.teal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.svcCouponTitle, style: AppTypography.body(15, weight: FontWeight.w900, color: p.ink)),
                  Text(source.isEmpty ? l.svcCouponSubPlain(amount) : l.svcCouponSub(amount, source), style: AppTypography.body(12, color: p.mut)),
                ],
              ),
            ),
            Switch.adaptive(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
