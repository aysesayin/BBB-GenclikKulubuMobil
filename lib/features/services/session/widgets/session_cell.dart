import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../data/models/services/session.dart';
import '../../../../l10n/l10n.dart';
import '../../widgets/services_icons.dart';
import '../../widgets/svc_format.dart';
import '../view_model/session_view_model.dart';
import 'session_cell_sheet.dart';

const kCellW = 104.0;
const kCellH = 72.0;

/// Tek seans hücresi. Açık → seçer; DOLU → bekleme listesi sayfası; uygun değil →
/// %40 soluk + kilit ikonu, dokununca neden sayfası (uzun basınca tooltip).
class SlotCell extends StatelessWidget {
  const SlotCell({super.key, required this.vm, required this.day, required this.slot, required this.minute, this.width = kCellW});

  final SessionViewModel vm;
  final SessionDay day;
  final SessionSlot? slot;
  final int minute;

  /// null → satırı doldurur (Kolay Mod tek gün görünümü).
  final double? width;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = context.l10n;
    final s = slot;
    final kind = vm.kindOf(s, day);
    if (kind == CellKind.empty) return SizedBox(width: width, height: kCellH);
    final cap = s == null ? '' : l.svcCellCapacity('${s.isFull ? s.capacity : s.booked}', '${s.capacity}');
    final price = s == null ? '' : SvcFmt.price(context, s.price);
    final label = s?.label ?? '';
    final waitPos = s == null ? null : vm.waitlistPositionOf(s.id);
    final (Color bg, Color fg, Color? border, String l1, String l2, String l3, String? icon) = switch (kind) {
      CellKind.holiday => (p.yelS, p.warningText, null, l.svcCellHoliday, '', l.svcCellClosed, AppIcons.calendar),
      CellKind.maintenance => (p.sf2, p.mut, null, label.isEmpty ? l.svcCellMaintenance : label, '', '', SvcIcons.wrench),
      CellKind.cancelled => (p.sf2, p.mut, null, label, l.svcCellCancelled, '', AppIcons.close),
      CellKind.full => (p.pinkS, p.pinkT, null, label, waitPos == null ? l.svcCellFull : l.svcCellWaitlisted('$waitPos'), cap, null),
      CellKind.ineligible => (p.sf, p.ink, p.line, label, l.svcCellIneligible, '', AppIcons.lock),
      CellKind.past => (p.sf2, p.mut, null, label, price, l.svcCellPast, null),
      CellKind.selected => (p.onTile, p.paper, null, label, price, cap, AppIcons.check),
      _ => (p.sf, p.ink, p.line, label, price, cap, null),
    };
    final tappable = s != null && (kind == CellKind.open || kind == CellKind.selected || kind == CellKind.full || kind == CellKind.ineligible);
    final issue = kind == CellKind.ineligible && s != null ? vm.ineligibilityOf(s) : null;
    final style = AppTypography.number(11, color: fg, height: 1.15);
    Widget cell = AnimatedContainer(
      duration: AppDurations.chip,
      width: width,
      height: kCellH,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: border == null ? null : Border.all(color: border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  l1,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: style.copyWith(decoration: kind == CellKind.cancelled ? TextDecoration.lineThrough : null, decorationColor: fg),
                ),
              ),
              if (icon != null) AppIcon(icon, size: 12, color: fg, strokeWidth: 2.8),
            ],
          ),
          Row(
            children: [
              Expanded(child: Text(l2, maxLines: 1, overflow: TextOverflow.fade, softWrap: false, style: style)),
              Flexible(child: Text(l3, maxLines: 1, overflow: TextOverflow.fade, softWrap: false, style: style)),
            ],
          ),
        ],
      ),
    );
    if (kind == CellKind.ineligible) cell = Opacity(opacity: .4, child: cell);
    if (issue != null) cell = Tooltip(message: ruleIssueText(context, issue), child: cell);
    final status = [l2, l3, if (issue != null) ruleIssueText(context, issue)].where((e) => e.isNotEmpty).join(' ');
    return Semantics(
      button: true,
      enabled: tappable,
      selected: kind == CellKind.selected,
      excludeSemantics: true,
      label: l.svcCellSemantics(SvcFmt.dayHeader(context, day.date), SvcFmt.minuteLabel(minute), l1, status),
      child: GestureDetector(
        onTap: tappable
            ? () {
                Haptics.selection();
                handleCellTap(context, vm, slot: s, day: day, kind: kind);
              }
            : null,
        child: cell,
      ),
    );
  }
}
