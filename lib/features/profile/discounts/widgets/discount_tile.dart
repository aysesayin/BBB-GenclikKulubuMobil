import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/profile/discount.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/profile_icons.dart';
import '../../widgets/profile_ui.dart';

/// Durum → (etiket, ikon, zemin, yazı rengi). Durum hem ikon hem metinle verilir.
(String, String, Color, Color) discountStatusStyle(BuildContext context, DiscountStatus status) {
  final p = context.palette;
  final l = context.l10n;
  return switch (status) {
    DiscountStatus.approved => (l.profileDiscountStatusApproved, AppIcons.check, p.grnS, p.grnT),
    DiscountStatus.pending => (l.profileDiscountStatusPending, AppIcons.clock, p.yelS, p.warningText),
    DiscountStatus.expiring => (l.profileDiscountStatusExpiring, ProfileIcons.warn, p.yelS, p.warningText),
    DiscountStatus.rejected => (l.profileDiscountStatusRejected, AppIcons.close, p.pinkS, p.pinkT),
    DiscountStatus.expired => (l.profileDiscountStatusExpired, ProfileIcons.warn, p.pinkS, p.pinkT),
  };
}

/// "Öğrenci · Geçerlilik 30.06.2027 · [✓ Onaylandı]" satırı. Reddedilen / süresi dolan
/// indirime dokunmak aynı tür için yeniden başvuruyu başlatır.
class DiscountTile extends StatelessWidget {
  const DiscountTile({super.key, required this.discount, required this.today, this.onRenew});

  final UserDiscount discount;
  final DateTime today;
  final VoidCallback? onRenew;

  String _subtitle(AppLocalizations l, DiscountStatus status) {
    final until = discount.validUntil;
    final sent = discount.submittedAt;
    return switch (status) {
      DiscountStatus.approved || DiscountStatus.expired when until != null => l.profileDiscountValidUntil(ProfileFmt.dmy(until)),
      DiscountStatus.expiring when until != null => l.profileDiscountRenew(ProfileFmt.dmy(until)),
      DiscountStatus.rejected => (discount.rejectReason?.isNotEmpty ?? false) ? discount.rejectReason! : l.profileDiscountRejectedDefault,
      _ when sent != null => l.profileDiscountSentOn(ProfileFmt.dmy(sent)),
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final status = discount.effectiveStatus(today);
    final (label, icon, bg, fg) = discountStatusStyle(context, status);
    final renewable = status == DiscountStatus.rejected || status == DiscountStatus.expiring || status == DiscountStatus.expired;
    return AppCard(
      onTap: renewable ? onRenew : null,
      radius: AppRadii.tile,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Row(
          children: [
            Expanded(
              child: TitleSubtitle(title: discount.typeName, subtitle: _subtitle(l, status)),
            ),
            const SizedBox(width: 12),
            StatusPill(label: label, icon: icon, background: bg, foreground: fg),
          ],
        ),
      ),
    );
  }
}
