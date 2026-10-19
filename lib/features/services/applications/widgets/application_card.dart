import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/services/application.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/services_icons.dart';
import '../../widgets/svc_format.dart';
import '../../widgets/svc_navigation.dart';
import '../view_model/applications_view_model.dart';
import 'application_parts.dart';

/// Başvuru kartı: durum, kota/indirim notu, QR bilet, eylemler.
class ApplicationCard extends StatelessWidget {
  const ApplicationCard({super.key, required this.app, required this.vm, required this.onCancel});

  final Application app;
  final ApplicationsViewModel vm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final open = vm.openTicketId == app.id && app.ticket != null;
    final coupon = app.couponAmount ?? 0;
    final notes = [
      ...[app.quotaNote, app.note].whereType<String>().where((s) => s.isNotEmpty),
      if (coupon > 0) l.svcAppCouponNote(SvcFmt.price(context, coupon)),
    ];
    final actions = _actions(context);
    return Container(
      decoration: BoxDecoration(color: p.sf, borderRadius: BorderRadius.circular(AppRadii.card), boxShadow: p.cardShadow),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ApplicationHeader(app: app, hoursLeft: vm.hoursLeft(app), icon: SvcIcons.of(app.icon)),
          for (final n in notes) ApplicationNote(n),
          if (open) ApplicationTicketView(ticket: app.ticket!),
          if (actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Row(
                children: [
                  for (var i = 0; i < actions.length; i++) ...[if (i > 0) const SizedBox(width: 8), Expanded(child: actions[i])],
                ],
              ),
            )
          else
            const SizedBox(height: 6),
        ],
      ),
    );
  }

  List<Widget> _actions(BuildContext context) {
    final l = context.l10n;
    final busy = vm.isBusy(app.id);
    Widget primary(String label, VoidCallback onTap) => AppButton(label: label, onPressed: onTap, size: AppButtonSize.medium);
    Widget secondary(String label, VoidCallback? onTap, {bool loading = false}) =>
        AppButton(label: label, onPressed: onTap, busy: loading, variant: AppButtonVariant.outlineInk, size: AppButtonSize.medium);
    final cancelLabel = switch (app.cancelKind) {
      CancelKind.cancel => l.svcActCancel,
      CancelKind.withdraw => l.svcActWithdraw,
      CancelKind.request => l.svcActRequest,
    };
    final cancel = app.canCancel ? secondary(cancelLabel, busy ? null : onCancel, loading: busy) : null;
    if (app.isActive) {
      return [
        if (app.ticket != null)
          primary(vm.openTicketId == app.id ? l.svcTicketHide : l.svcTicketShow, () => vm.toggleTicket(app.id))
        else if (app.status == ApplicationStatus.pendingPayment)
          // TODO(varsayım): Ödeme bekleyen başvuru için sunucu sepeti yeniden kurar; doğrudan sepete gidilir.
          primary(l.svcActPay, () => context.push(Routes.cart)),
        ?cancel,
      ];
    }
    return [
      if (app.status == ApplicationStatus.attended && app.sourceId.isNotEmpty)
        secondary(l.svcActReapply, () => app.sourceType == ApplicationSource.event
            ? context.push(Routes.event(app.sourceId))
            : openSessions(context, app.sourceId)),
      if (app.status == ApplicationStatus.cancelled && (app.couponAmount ?? 0) > 0) secondary(l.svcActCoupons, () => context.push(Routes.coupons)),
    ];
  }
}
