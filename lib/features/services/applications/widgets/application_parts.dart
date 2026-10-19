import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/services/application.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/svc_format.dart';

/// Durum rozeti: renk + ikon + metin (yalnız renge dayanmaz).
class ApplicationStatusBadge extends StatelessWidget {
  const ApplicationStatusBadge({super.key, required this.app, required this.hoursLeft});

  final Application app;
  final int? hoursLeft;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final (Color bg, Color fg, String icon, String text) = switch (app.status) {
      ApplicationStatus.approved => (p.grnS, p.grnT, AppIcons.check, app.paid ? l.svcStatusApprovedPaid : l.svcStatusApproved),
      ApplicationStatus.accepted => (p.grnS, p.grnT, AppIcons.check, l.svcStatusAccepted),
      ApplicationStatus.pendingPayment => (
          p.yelS,
          p.warningText,
          AppIcons.clock,
          hoursLeft == null ? l.svcStatusPendingPaymentNoTime : l.svcStatusPendingPayment('$hoursLeft'),
        ),
      ApplicationStatus.waitlist => (p.yelS, p.warningText, AppIcons.clock, l.svcStatusWaitlist),
      ApplicationStatus.attended => (
          p.sf2,
          p.mut,
          AppIcons.check,
          (app.earnedBuan ?? 0) > 0 ? l.svcStatusAttendedBuan(Fmt.number(app.earnedBuan!)) : l.svcStatusAttended,
        ),
      ApplicationStatus.cancelled => (p.pinkS, p.pinkT, AppIcons.close, app.medicalMakeUp ? l.svcStatusCancelledMakeUp : l.svcStatusCancelled),
      ApplicationStatus.rejected => (p.pinkS, p.pinkT, AppIcons.close, l.svcStatusRejected),
      ApplicationStatus.unknown => (p.sf2, p.mut, AppIcons.info, l.svcStatusUnknown),
    };
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 12, color: fg, strokeWidth: 3),
          const SizedBox(width: 4),
          Flexible(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.body(11, weight: FontWeight.w900, color: fg))),
        ],
      ),
    );
  }
}

/// Kota / indirim / kupon notu kutusu.
class ApplicationNote extends StatelessWidget {
  const ApplicationNote(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: p.bg, borderRadius: BorderRadius.circular(14)),
      child: Text(text, style: AppTypography.body(12, weight: FontWeight.w800, color: p.mut)),
    );
  }
}

/// Turnike QR bileti (kesikli çerçeve).
class ApplicationTicketView extends StatelessWidget {
  const ApplicationTicketView({super.key, required this.ticket});

  final ApplicationTicket ticket;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: CustomPaint(
        painter: _DashedBorder(color: p.line, radius: 18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Semantics(
                image: true,
                label: l.svcTicketSemantics(ticket.code),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(12)),
                  child: QrImageView(
                    data: ticket.qrToken,
                    size: 96,
                    padding: EdgeInsets.zero,
                    eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: p.onTile),
                    dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: p.onTile),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.svcTicketHint, style: AppTypography.body(12, weight: FontWeight.w800, color: p.mut)),
                    const SizedBox(height: 4),
                    Text(ticket.code.split('').join(' '), style: AppTypography.display(24, color: p.ink).copyWith(letterSpacing: 2)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()..addRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)));
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 10) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}

/// Kart başlığı: ikon karosu + başlık + alt satır + durum.
class ApplicationHeader extends StatelessWidget {
  const ApplicationHeader({super.key, required this.app, required this.hoursLeft, required this.icon});

  final Application app;
  final int? hoursLeft;
  final String icon;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(icon: icon, color: SvcFmt.tile(p, app.tile), size: 48, radius: 16, iconSize: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(app.title, style: AppTypography.body(15, weight: FontWeight.w900, color: p.ink)),
                const SizedBox(height: 3),
                if (app.subtitle.isNotEmpty) Text(app.subtitle, style: AppTypography.body(12, color: p.mut)),
                const SizedBox(height: 7),
                ApplicationStatusBadge(app: app, hoursLeft: hoursLeft),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
